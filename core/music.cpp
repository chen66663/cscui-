#include "core/music.h"

#include <QMediaPlayer>
#include <QCoreApplication>
#include <QDateTime>
#include <QFile>
#include <QFileInfo>
#include <QDir>
#include <QDirIterator>
#include <QStandardPaths>
#include <QImage>
#include <QPixmap>
#include <QFileSystemWatcher>
#include <QTimer>
#include <QSet>
#include <QThread>
#include <QThreadPool>
#include <QUuid>
#include <QtConcurrent/QtConcurrentRun>

#include <atomic>
#include <limits>
#include <memory>

namespace {

using ScanCancellationToken = std::shared_ptr<std::atomic_bool>;

constexpr qsizetype kMaxIncrementalFileEvents = 128;
// Building two QSets is useful for a small library, but it is still GUI-thread
// work. Large snapshots already arrive through musicFilesChanged, so legacy
// per-file notifications are deliberately skipped above this bound.
constexpr qsizetype kMaxIncrementalDiffInputFiles = 1024;
constexpr qsizetype kMaxMetadataQueueSize = 256;
constexpr qsizetype kMaxMetadataCacheSize = 2048;
constexpr qint64 kMaxLyricsFileBytes = 2 * 1024 * 1024;
constexpr int kMetadataPrefetchTimeoutMs = 2500;
constexpr int kCoverMaximumEdge = 640;

bool isScanCancelled(const ScanCancellationToken &token)
{
    return token && token->load(std::memory_order_relaxed);
}

const QStringList &validMusicExtensions()
{
    static const QStringList extensions = {
        QStringLiteral("mp3"),
        QStringLiteral("m4a"),
        QStringLiteral("flac"),
        QStringLiteral("wav"),
        QStringLiteral("ogg"),
        QStringLiteral("aac"),
        QStringLiteral("wma")
    };
    return extensions;
}

QString normalizedLocalPath(const QString &path)
{
    QString normalized = path;
    if (path.startsWith(QStringLiteral("file:"))) {
        const QUrl url(path);
        if (url.isValid())
            normalized = url.toLocalFile();
    }
    return QDir::fromNativeSeparators(normalized);
}

// This function only uses value types and filesystem APIs, so it is safe to
// execute on the dedicated scan pool without touching a QObject.
QStringList scanMusicFilesOnWorker(const QString &rootPath,
                                   bool recursive,
                                   const ScanCancellationToken &cancellationToken = {})
{
    QStringList musicFiles;
    if (isScanCancelled(cancellationToken))
        return musicFiles;

    const QString normalized = normalizedLocalPath(rootPath);
    if (normalized.isEmpty() || !QDir(normalized).exists())
        return musicFiles;

    QStringList nameFilters;
    nameFilters.reserve(validMusicExtensions().size());
    for (const QString &extension : validMusicExtensions())
        nameFilters.append(QStringLiteral("*.%1").arg(extension));

    const QDirIterator::IteratorFlag iteratorFlag = recursive
            ? QDirIterator::Subdirectories
            : QDirIterator::NoIteratorFlags;
    QDirIterator iterator(normalized, nameFilters, QDir::Files, iteratorFlag);
    while (!isScanCancelled(cancellationToken) && iterator.hasNext())
        musicFiles.append(iterator.next());

    if (isScanCancelled(cancellationToken))
        return {};
    musicFiles.sort(Qt::CaseInsensitive);
    return musicFiles;
}

QStringList scanMusicRootsOnWorker(const QStringList &roots,
                                   bool recursive,
                                   const ScanCancellationToken &cancellationToken = {})
{
    QStringList allMusic;
    QSet<QString> seen;
    for (const QString &root : roots) {
        if (isScanCancelled(cancellationToken))
            return {};
        const QStringList files = scanMusicFilesOnWorker(root, recursive, cancellationToken);
        if (isScanCancelled(cancellationToken))
            return {};
        for (const QString &file : files) {
            if (seen.contains(file))
                continue;
            seen.insert(file);
            allMusic.append(file);
        }
    }
    allMusic.sort(Qt::CaseInsensitive);
    return allMusic;
}

QString findProjectRootOnWorker(const QString &applicationDir)
{
    QDir directory(applicationDir);
    for (int level = 0; level < 6; ++level) {
        if (directory.exists(QStringLiteral("src.qrc"))
                || directory.exists(QStringLiteral("components"))) {
            return directory.absolutePath();
        }
        if (!directory.cdUp())
            break;
    }
    return applicationDir;
}

// Locate an LRC file using only value types and filesystem APIs. Keeping the
// lookup beside the read lets the asynchronous QML path avoid even a single
// directory enumeration on the GUI thread.
QString findLyricsFileOnWorker(const QString &source,
                               const QString &projectRoot,
                               const ScanCancellationToken &cancellationToken = {})
{
    if (source.isEmpty() || isScanCancelled(cancellationToken))
        return {};

    const auto trySameDirectory = [&cancellationToken](const QString &localPath) -> QString {
        if (isScanCancelled(cancellationToken))
            return {};
        const QFileInfo fileInfo(localPath);
        if (!fileInfo.exists())
            return {};

        const QString matchingPath = fileInfo.dir().absoluteFilePath(
                fileInfo.completeBaseName() + QStringLiteral(".lrc"));
        if (isScanCancelled(cancellationToken))
            return {};
        if (QFile::exists(matchingPath))
            return QUrl::fromLocalFile(matchingPath).toString();

        const QStringList candidates = fileInfo.dir().entryList(
                QStringList{QStringLiteral("*.lrc")}, QDir::Files, QDir::Name);
        if (isScanCancelled(cancellationToken))
            return {};
        if (candidates.size() == 1) {
            const QString fallbackPath = fileInfo.dir().absoluteFilePath(candidates.constFirst());
            if (QFile::exists(fallbackPath))
                return QUrl::fromLocalFile(fallbackPath).toString();
        }
        return {};
    };

    if (source.startsWith(QStringLiteral("file:///"))) {
        const QString hit = trySameDirectory(QUrl(source).toLocalFile());
        if (!hit.isEmpty())
            return hit;
    } else if (source.startsWith(QStringLiteral("qrc:/"))) {
        if (projectRoot.isEmpty() || isScanCancelled(cancellationToken))
            return {};
        const QFileInfo sourceInfo(QUrl(source).path());
        const QString candidate = QDir(projectRoot).absoluteFilePath(
                sourceInfo.completeBaseName() + QStringLiteral(".lrc"));
        if (QFile::exists(candidate))
            return QUrl::fromLocalFile(candidate).toString();
    } else {
        const QString hit = trySameDirectory(source);
        if (!hit.isEmpty())
            return hit;
    }

    if (projectRoot.isEmpty() || isScanCancelled(cancellationToken))
        return {};
    QDirIterator iterator(projectRoot,
                          QStringList{QStringLiteral("*.lrc")},
                          QDir::Files,
                          QDirIterator::NoIteratorFlags);
    if (isScanCancelled(cancellationToken))
        return {};
    return iterator.hasNext() ? QUrl::fromLocalFile(iterator.next()).toString() : QString();
}

QVariantMap readLyricsTextOnWorker(const QString &source,
                                   const QString &lyricsUrl,
                                   const ScanCancellationToken &cancellationToken = {})
{
    QVariantMap result{
        {QStringLiteral("source"), source},
        {QStringLiteral("filePath"), lyricsUrl},
        {QStringLiteral("text"), QString()}
    };
    if (lyricsUrl.isEmpty() || isScanCancelled(cancellationToken))
        return result;

    const QUrl url(lyricsUrl);
    const QString lyricsPath = url.isLocalFile() ? url.toLocalFile() : lyricsUrl;
    const QFileInfo info(lyricsPath);
    if (!info.exists() || !info.isFile() || info.size() <= 0
            || info.size() > kMaxLyricsFileBytes) {
        return result;
    }

    QFile file(lyricsPath);
    if (!file.open(QIODevice::ReadOnly))
        return result;
    QByteArray bytes;
    bytes.reserve(static_cast<int>(kMaxLyricsFileBytes));
    constexpr qint64 kLyricsReadChunk = 64 * 1024;
    while (!file.atEnd() && bytes.size() <= kMaxLyricsFileBytes) {
        if (isScanCancelled(cancellationToken))
            return result;
        const QByteArray chunk = file.read(kLyricsReadChunk);
        if (chunk.isEmpty())
            break;
        bytes.append(chunk);
        if (bytes.size() > kMaxLyricsFileBytes)
            return result;
    }
    if (isScanCancelled(cancellationToken))
        return result;

    QString text = QString::fromUtf8(bytes);
    if (text.trimmed().isEmpty() && !bytes.isEmpty())
        text = QString::fromLocal8Bit(bytes);
    result.insert(QStringLiteral("text"), text);
    return result;
}

QString writeCoverImageOnWorker(QImage coverImage,
                                const QByteArray &encodedCover,
                                const QString &outputPath,
                                const ScanCancellationToken &cancellationToken)
{
    if (isScanCancelled(cancellationToken) || outputPath.isEmpty())
        return {};

    if (coverImage.isNull() && !encodedCover.isEmpty())
        coverImage.loadFromData(encodedCover);
    if (coverImage.isNull() || isScanCancelled(cancellationToken))
        return {};

    if (coverImage.width() > kCoverMaximumEdge
            || coverImage.height() > kCoverMaximumEdge) {
        coverImage = coverImage.scaled(kCoverMaximumEdge,
                                       kCoverMaximumEdge,
                                       Qt::KeepAspectRatio,
                                       Qt::SmoothTransformation);
    }
    if (isScanCancelled(cancellationToken))
        return {};

    if (!coverImage.save(outputPath, "JPG", 88))
        return {};
    if (isScanCancelled(cancellationToken)) {
        QFile::remove(outputPath);
        return {};
    }
    return outputPath;
}

class MusicScanThreadPool final : public QThreadPool
{
public:
    MusicScanThreadPool()
    {
        // Directory walks are disk-bound. Serializing them prevents several
        // MusicLibrary instances from competing with rendering and playback.
        setMaxThreadCount(1);
        setExpiryTimeout(30'000);
        setThreadPriority(QThread::LowPriority);
    }
};

class MusicMediaThreadPool final : public QThreadPool
{
public:
    MusicMediaThreadPool()
    {
        // Small metadata/lyrics reads may run beside a long directory walk,
        // but remain serialized so media I/O cannot fan out uncontrollably.
        setMaxThreadCount(1);
        setExpiryTimeout(30'000);
        setThreadPriority(QThread::LowPriority);
    }
};

QThreadPool *musicScanThreadPool()
{
    static MusicScanThreadPool pool;
    return &pool;
}

QThreadPool *musicMediaThreadPool()
{
    static MusicMediaThreadPool pool;
    return &pool;
}

} // namespace

// ---------------------- AudioMetadata ----------------------
AudioMetadata::AudioMetadata(QObject *parent)
    : QObject(parent)
    , m_mediaPlayer(new QMediaPlayer(this))
    , m_duration(0)
{
    // Metadata extraction never plays audio. Omitting QAudioOutput avoids an
    // unnecessary platform audio backend and its worker resources.
    connect(m_mediaPlayer, &QMediaPlayer::metaDataChanged,
            this, &AudioMetadata::onMetaDataChanged);
    connect(m_mediaPlayer, &QMediaPlayer::durationChanged,
            this, &AudioMetadata::onDurationChanged);
}

AudioMetadata::~AudioMetadata()
{
    ++m_coverGeneration;
    if (m_coverCancellation)
        m_coverCancellation->store(true, std::memory_order_relaxed);
    if (!m_tempCoverPath.isEmpty()) {
        QFile::remove(m_tempCoverPath);
    }
    if (!m_pendingCoverPath.isEmpty())
        QFile::remove(m_pendingCoverPath);
}

void AudioMetadata::setSource(const QString &source)
{
    if (m_source != source) {
        ++m_coverGeneration;
        if (m_coverCancellation)
            m_coverCancellation->store(true, std::memory_order_relaxed);
        m_coverExtractionPending = false;
        if (!m_pendingCoverPath.isEmpty()) {
            QFile::remove(m_pendingCoverPath);
            m_pendingCoverPath.clear();
        }

        m_source = source;
        emit sourceChanged();

        m_title.clear();
        m_artist.clear();
        m_album.clear();
        m_coverImageUrl.clear();
        m_duration = 0;

        // Clear stale values immediately; metadata signals may arrive later or
        // not at all for malformed files.
        emit titleChanged();
        emit artistChanged();
        emit albumChanged();
        emit coverImageUrlChanged();
        emit durationChanged();

        if (!m_tempCoverPath.isEmpty()) {
            QFile::remove(m_tempCoverPath);
            m_tempCoverPath.clear();
        }

        loadMetadata();
    }
}

void AudioMetadata::loadMetadata()
{
    if (m_source.isEmpty()) {
        // Clearing the QML source must also release the backend's previous
        // decoder/file handle. Returning early leaves late metadata signals
        // and the old backend alive after a track is removed.
        m_mediaPlayer->stop();
        m_mediaPlayer->setSource(QUrl());
        return;
    }

    // 设置媒体源
    if (m_source.startsWith("qrc:/")) {
        m_mediaPlayer->setSource(QUrl(m_source));
    } else {
        m_mediaPlayer->setSource(QUrl::fromLocalFile(m_source));
    }
}

void AudioMetadata::onMetaDataChanged()
{
    const QMediaMetaData metaData = m_mediaPlayer->metaData();

    // 标题
    if (metaData.value(QMediaMetaData::Title).isValid()) {
        m_title = metaData.value(QMediaMetaData::Title).toString();
    } else {
        m_title = extractFileNameTitle(m_source);
    }
    emit titleChanged();

    // 艺术家
    if (metaData.value(QMediaMetaData::AlbumArtist).isValid()) {
        m_artist = metaData.value(QMediaMetaData::AlbumArtist).toString();
    } else if (metaData.value(QMediaMetaData::ContributingArtist).isValid()) {
        m_artist = metaData.value(QMediaMetaData::ContributingArtist).toString();
    } else {
        m_artist = QStringLiteral("未知艺术家");
    }
    emit artistChanged();

    // 专辑
    if (metaData.value(QMediaMetaData::AlbumTitle).isValid()) {
        m_album = metaData.value(QMediaMetaData::AlbumTitle).toString();
    } else {
        m_album = QStringLiteral("未知专辑");
    }
    emit albumChanged();

    // 封面
    extractCoverArt();
    emit metadataLoaded();
}

void AudioMetadata::onDurationChanged(qint64 duration)
{
    const qint64 maximumSeconds = static_cast<qint64>(std::numeric_limits<int>::max());
    m_duration = static_cast<int>(qBound<qint64>(qint64{0}, duration / 1000, maximumSeconds));
    emit durationChanged();
}

void AudioMetadata::extractCoverArt()
{
    // Some backends emit metaDataChanged more than once for the same source.
    // Reuse the first extracted cover instead of encoding duplicate files.
    if (!m_coverImageUrl.isEmpty() || m_coverExtractionPending)
        return;

    const QMediaMetaData metaData = m_mediaPlayer->metaData();
    QVariant coverData;

    if (metaData.value(QMediaMetaData::CoverArtImage).isValid()) {
        coverData = metaData.value(QMediaMetaData::CoverArtImage);
    } else if (metaData.value(QMediaMetaData::ThumbnailImage).isValid()) {
        coverData = metaData.value(QMediaMetaData::ThumbnailImage);
    }

    if (!coverData.isValid())
        return;

    // QPixmap must remain on the GUI thread. QImage and encoded bytes are
    // implicitly shared value types and can safely cross into the media pool.
    QImage coverImage;
    QByteArray encodedCover;
    if (coverData.canConvert<QImage>()) {
        coverImage = coverData.value<QImage>();
    } else if (coverData.canConvert<QPixmap>()) {
        coverImage = coverData.value<QPixmap>().toImage();
    } else if (coverData.canConvert<QByteArray>()) {
        encodedCover = coverData.toByteArray();
    }
    if (coverImage.isNull() && encodedCover.isEmpty())
        return;

    const QString tempDir = QStandardPaths::writableLocation(QStandardPaths::TempLocation);
    if (tempDir.isEmpty())
        return;
    const QString uniqueId = QUuid::createUuid().toString(QUuid::Id128);
    const QString requestedPath = QDir(tempDir).filePath(QStringLiteral("cscui-cover-%1-%2.jpg")
                                                 .arg(QCoreApplication::applicationPid())
                                                 .arg(uniqueId));
    const ScanCancellationToken cancellationToken =
            std::make_shared<std::atomic_bool>(false);
    const quint64 generation = m_coverGeneration;
    m_coverCancellation = cancellationToken;
    m_pendingCoverPath = requestedPath;
    m_coverExtractionPending = true;

    auto *watcher = new QFutureWatcher<QString>(this);
    connect(watcher, &QFutureWatcher<QString>::finished, this,
            [this, watcher, requestedPath, generation] {
                const QString resultPath = watcher->result();
                watcher->deleteLater();

                if (m_pendingCoverPath == requestedPath) {
                    m_pendingCoverPath.clear();
                    m_coverExtractionPending = false;
                }
                if (generation != m_coverGeneration || resultPath.isEmpty()) {
                    if (!resultPath.isEmpty())
                        QFile::remove(resultPath);
                    return;
                }

                if (!m_tempCoverPath.isEmpty())
                    QFile::remove(m_tempCoverPath);
                m_tempCoverPath = resultPath;
                m_coverImageUrl = QUrl::fromLocalFile(m_tempCoverPath);
                emit coverImageUrlChanged();
            });
    watcher->setFuture(QtConcurrent::run(
            musicMediaThreadPool(),
            [coverImage, encodedCover, requestedPath, cancellationToken] {
                return writeCoverImageOnWorker(coverImage,
                                               encodedCover,
                                               requestedPath,
                                               cancellationToken);
            }));
}

QString AudioMetadata::extractFileNameTitle(const QString &filePath)
{
    QFileInfo fileInfo(filePath);
    QString baseName = fileInfo.baseName();
    if (baseName.contains(" - ")) {
        QStringList parts = baseName.split(" - ");
        if (parts.size() >= 2) return parts.last().trimmed();
    }
    return baseName;
}

// ---------------------- MusicLibrary ----------------------
MusicLibrary::MusicLibrary(QObject *parent)
    : QObject(parent)
    , m_watcher(new QFileSystemWatcher(this))
    , m_scanTimer(new QTimer(this))
    , m_isWatching(false)
    , m_prefetchPlayer(nullptr)
    , m_prefetchTimeoutTimer(new QTimer(this))
    , m_prefetchActive(false)
    , m_scanWatcher(new QFutureWatcher<QStringList>(this))
{
    // 配置扫描定时器
    m_scanTimer->setSingleShot(true);
    m_scanTimer->setInterval(SCAN_DELAY_MS);
    m_lastScanMs = 0;
    
    // 连接信号
    connect(m_watcher, &QFileSystemWatcher::directoryChanged,
            this, &MusicLibrary::onDirectoryChanged);
    connect(m_watcher, &QFileSystemWatcher::fileChanged,
            this, &MusicLibrary::onFileChanged);
    connect(m_scanTimer, &QTimer::timeout,
            this, &MusicLibrary::performDelayedScan);

    m_prefetchTimeoutTimer->setSingleShot(true);
    m_prefetchTimeoutTimer->setInterval(kMetadataPrefetchTimeoutMs);
    connect(m_prefetchTimeoutTimer, &QTimer::timeout, this, [this] {
        finishCurrentPrefetch(true);
    });
    connect(m_scanWatcher, &QFutureWatcher<QStringList>::finished,
            this, &MusicLibrary::onAsyncScanFinished);
}

MusicLibrary::~MusicLibrary()
{
    // The worker captures only values and this shared token. QFutureWatcher
    // detaches safely during destruction, so page teardown must not wait on a
    // slow filesystem or unavailable network volume from the GUI thread.
    ++m_scanGeneration;
    m_hasPendingScan = false;
    if (m_activeScanCancellation)
        m_activeScanCancellation->store(true, std::memory_order_relaxed);
    if (m_lyricsCancellation)
        m_lyricsCancellation->store(true, std::memory_order_relaxed);
    ++m_lyricsGeneration;
    m_prefetchTimeoutTimer->stop();
    m_prefetchQueue.clear();
    disconnect(m_scanWatcher, nullptr, this, nullptr);
    m_scanWatcher->cancel();
}

QStringList MusicLibrary::scanMusicFiles(const QString &rootPath, bool recursive)
{
    return scanMusicFilesOnWorker(rootPath, recursive);
}

QString MusicLibrary::defaultProjectRoot()
{
    return findProjectRootFromAppDir();
}

QStringList MusicLibrary::scanDefaultProjectMusic(bool recursive)
{
    return scanMusicFiles(defaultProjectRoot(), recursive);
}

QString MusicLibrary::findProjectRootFromAppDir() const
{
    QString appDir = QCoreApplication::applicationDirPath();
    QDir dir(appDir);

    // 向上查找最多6级目录
    for (int i = 0; i < 6; ++i) {
        if (dir.exists("src.qrc") || dir.exists("components")) {
            return dir.absolutePath();
        }
        if (!dir.cdUp()) break;
    }

    return appDir; // 默认返回应用程序目录
}

// 新增：获取Windows音乐文件夹路径
QString MusicLibrary::getWindowsMusicFolder()
{
    return QStandardPaths::writableLocation(QStandardPaths::MusicLocation);
}

// 新增：扫描Windows音乐文件夹
QStringList MusicLibrary::scanWindowsMusic(bool recursive)
{
    QString windowsMusicPath = getWindowsMusicFolder();
    if (windowsMusicPath.isEmpty()) {
        return QStringList();
    }
    return scanMusicFiles(windowsMusicPath, recursive);
}

// 新增：扫描所有可用音乐（项目+Windows音乐文件夹）
QStringList MusicLibrary::scanAllAvailableMusic(bool recursive)
{
    const QStringList allMusic = scanMusicRootsOnWorker(allAvailableScanRoots(), recursive);
    m_cachedFiles = allMusic;
    return allMusic;
}

QStringList MusicLibrary::allAvailableScanRoots() const
{
    QStringList roots;
    const QString projectRoot = findProjectRootFromAppDir();
    if (!projectRoot.isEmpty())
        roots.append(projectRoot);

    const QString windowsMusic = QStandardPaths::writableLocation(QStandardPaths::MusicLocation);
    if (!windowsMusic.isEmpty() && !roots.contains(windowsMusic, Qt::CaseInsensitive))
        roots.append(windowsMusic);
    return roots;
}

void MusicLibrary::scanAllAvailableMusicAsync(bool recursive)
{
    requestAsyncScan(allAvailableScanRoots(), recursive, true);
}

bool MusicLibrary::isScanInProgress() const
{
    return m_scanInProgress;
}

void MusicLibrary::requestAsyncScan(const QStringList &roots,
                                    bool recursive,
                                    bool forceNotification)
{
    const quint64 generation = ++m_scanGeneration;
    if (m_scanInProgress) {
        // Collapse bursts into the newest request and cooperatively stop the
        // active directory walk so the shared serial pool becomes available.
        if (m_activeScanCancellation)
            m_activeScanCancellation->store(true, std::memory_order_relaxed);
        m_pendingScanRoots = roots;
        m_pendingScanRecursive = recursive;
        m_pendingScanForceNotification = forceNotification;
        m_pendingScanGeneration = generation;
        m_hasPendingScan = true;
        return;
    }

    launchAsyncScan(roots, recursive, forceNotification, generation);
}

void MusicLibrary::launchAsyncScan(const QStringList &roots,
                                   bool recursive,
                                   bool forceNotification,
                                   quint64 generation)
{
    m_activeScanGeneration = generation;
    m_activeScanForceNotification = forceNotification;
    m_activeScanCancellation = std::make_shared<std::atomic_bool>(false);
    if (!m_scanInProgress) {
        m_scanInProgress = true;
        emit scanInProgressChanged();
    }
    emit musicScanStarted(generation);

    // Capturing values and the token keeps the worker independent of
    // MusicLibrary lifetime. QObject state is only read on the GUI thread.
    const ScanCancellationToken cancellationToken = m_activeScanCancellation;
    m_scanWatcher->setFuture(QtConcurrent::run(
            musicScanThreadPool(),
            [roots, recursive, cancellationToken] {
                return scanMusicRootsOnWorker(roots, recursive, cancellationToken);
            }));
}

void MusicLibrary::onAsyncScanFinished()
{
    const quint64 finishedGeneration = m_activeScanGeneration;
    const bool resultIsCurrent = finishedGeneration == m_scanGeneration
            && !m_scanWatcher->isCanceled();

    if (resultIsCurrent) {
        const QStringList files = m_scanWatcher->result();
        applyScanResult(files, m_activeScanForceNotification);
        emit musicScanFinished(files, finishedGeneration);
    }

    if (m_hasPendingScan) {
        const QStringList roots = m_pendingScanRoots;
        const bool recursive = m_pendingScanRecursive;
        const bool forceNotification = m_pendingScanForceNotification;
        const quint64 generation = m_pendingScanGeneration;
        m_pendingScanRoots.clear();
        m_hasPendingScan = false;
        launchAsyncScan(roots, recursive, forceNotification, generation);
        return;
    }

    m_scanInProgress = false;
    emit scanInProgressChanged();
}

void MusicLibrary::applyScanResult(const QStringList &files, bool forceNotification)
{
    const QStringList previousFiles = m_cachedFiles;
    const bool changed = files != previousFiles;
    if (!changed && !forceNotification)
        return;

    // Always publish one bounded snapshot first. QML applies the model in
    // batches, so this signal is the scalable path for large libraries.
    m_cachedFiles = files;
    emit musicFilesChanged(files);

    if (!changed)
        return;

    // Avoid constructing and walking large GUI-thread hash sets. The legacy
    // fileAdded/fileRemoved signals are only useful for small incremental
    // updates; consumers can derive large-library changes from the snapshot.
    if (previousFiles.size() > kMaxIncrementalDiffInputFiles
            || files.size() > kMaxIncrementalDiffInputFiles) {
        return;
    }

    QSet<QString> previousSet;
    previousSet.reserve(previousFiles.size());
    for (const QString &file : previousFiles)
        previousSet.insert(file);

    QSet<QString> currentSet;
    currentSet.reserve(files.size());
    for (const QString &file : files)
        currentSet.insert(file);

    // A full snapshot is already delivered above. Do not turn a first scan of
    // thousands of files into thousands of synchronous QML callbacks. Keep
    // the legacy per-file signals for genuinely small incremental changes.
    qsizetype incrementalEventCount = 0;
    for (const QString &file : files) {
        if (!previousSet.contains(file) && ++incrementalEventCount > kMaxIncrementalFileEvents)
            return;
    }
    for (const QString &file : previousFiles) {
        if (!currentSet.contains(file) && ++incrementalEventCount > kMaxIncrementalFileEvents)
            return;
    }

    for (const QString &file : files) {
        if (!previousSet.contains(file))
            emit fileAdded(file);
    }
    for (const QString &file : previousFiles) {
        if (!currentSet.contains(file))
            emit fileRemoved(file);
    }
}

// 查找与音源同名同目录的 LRC，或项目根目录回退
QString MusicLibrary::findLyricsFileForSource(const QString &source)
{
    if (source.isEmpty()) return QString();

    // Source changes can trigger this lookup more than once while a track is
    // loading. Cache successful paths so the GUI does not rescan the folder.
    const auto cachedPath = m_lyricsPathCache.constFind(source);
    if (cachedPath != m_lyricsPathCache.cend()) {
        const QString localCachedPath = QUrl(*cachedPath).toLocalFile();
        if (!localCachedPath.isEmpty() && QFile::exists(localCachedPath))
            return *cachedPath;
        m_lyricsPathCache.erase(cachedPath);
    }

    // 优先：同名同目录
    auto trySameDir = [&](const QString &localPath) -> QString {
        QFileInfo fi(localPath);
        if (!fi.exists()) return QString();
        QString candidate = fi.dir().absoluteFilePath(fi.completeBaseName() + ".lrc");
        if (QFile::exists(candidate)) {
            return QUrl::fromLocalFile(candidate).toString();
        }
        // 兼容：若同名未命中且目录内只有一个 .lrc，则使用该文件
        QStringList lrcs = fi.dir().entryList(QStringList() << "*.lrc", QDir::Files, QDir::Name);
        if (lrcs.size() == 1) {
            QString onlyLrc = fi.dir().absoluteFilePath(lrcs.first());
            if (QFile::exists(onlyLrc)) {
                return QUrl::fromLocalFile(onlyLrc).toString();
            }
        }
        return QString();
    };

    if (source.startsWith("file:///")) {
        QUrl u(source);
        QString localPath = u.toLocalFile();
        QString hit = trySameDir(localPath);
        if (!hit.isEmpty()) {
            m_lyricsPathCache.insert(source, hit);
            return hit;
        }
    } else if (source.startsWith("qrc:/")) {
        // qrc: 路径下尝试根据文件名在项目根目录匹配
        QUrl u(source);
        QFileInfo fi(u.path());
        QString baseName = fi.completeBaseName();
        QString root = defaultProjectRoot();
        QString candidate = QDir(root).absoluteFilePath(baseName + ".lrc");
        if (QFile::exists(candidate)) {
            const QString result = QUrl::fromLocalFile(candidate).toString();
            m_lyricsPathCache.insert(source, result);
            return result;
        }
    } else {
        // 普通本地路径
        QString hit = trySameDir(source);
        if (!hit.isEmpty()) {
            m_lyricsPathCache.insert(source, hit);
            return hit;
        }
    }

    // 回退：项目根目录第一个 .lrc 文件（避免完全无歌词）
    QString root = defaultProjectRoot();
    QDirIterator it(root, QStringList() << "*.lrc", QDir::Files, QDirIterator::NoIteratorFlags);
    if (it.hasNext()) {
        QString p = it.next();
        const QString result = QUrl::fromLocalFile(p).toString();
        m_lyricsPathCache.insert(source, result);
        return result;
    }
    return QString();
}

// 读取歌词文本（UTF-8优先，回退本地编码）
QString MusicLibrary::loadLyricsText(const QString &source)
{
    const QString lrcUrl = findLyricsFileForSource(source);
    return readLyricsTextOnWorker(source, lrcUrl).value(QStringLiteral("text")).toString();
}

void MusicLibrary::loadLyricsTextAsync(const QString &source)
{
    const quint64 generation = ++m_lyricsGeneration;
    if (m_lyricsCancellation)
        m_lyricsCancellation->store(true, std::memory_order_relaxed);

    if (source.isEmpty())
        return;

    // Do not resolve the path here. QFileInfo/entryList/QDirIterator can block
    // on a network-backed music folder, so lookup and bounded reading happen in
    // one worker task below.
    // applicationDirPath() is a value lookup. Resolve the directory tree only
    // after the task enters the worker, where a slow/UNC volume cannot stall
    // the QML event loop.
    const QString applicationDir = QCoreApplication::applicationDirPath();

    const ScanCancellationToken cancellationToken =
            std::make_shared<std::atomic_bool>(false);
    m_lyricsCancellation = cancellationToken;

    // Each request owns a short-lived watcher. This lets a new song supersede
    // an in-flight read without waiting for the old future on the GUI thread.
    auto *watcher = new QFutureWatcher<QVariantMap>(this);
    connect(watcher, &QFutureWatcher<QVariantMap>::finished, this,
            [this, watcher, source, generation] {
                const QVariantMap result = watcher->result();
                watcher->deleteLater();
                if (generation != m_lyricsGeneration || result.isEmpty())
                    return;
                const QString filePath = result.value(QStringLiteral("filePath")).toString();
                if (!filePath.isEmpty())
                    m_lyricsPathCache.insert(source, filePath);
                emit lyricsReady(source,
                                 result.value(QStringLiteral("text")).toString(),
                                 filePath);
            });
    watcher->setFuture(QtConcurrent::run(
            musicMediaThreadPool(),
            [source, applicationDir, cancellationToken] {
                if (isScanCancelled(cancellationToken))
                    return readLyricsTextOnWorker(source, QString(), cancellationToken);
                const QString projectRoot = findProjectRootOnWorker(applicationDir);
                const QString lyricsUrl = findLyricsFileOnWorker(source,
                                                                  projectRoot,
                                                                  cancellationToken);
                return readLyricsTextOnWorker(source, lyricsUrl, cancellationToken);
            }));
}

QVariantMap MusicLibrary::getMetadata(const QString &source)
{
    return m_metaCache.value(source);
}

void MusicLibrary::ensurePrefetchPlayer()
{
    if (m_prefetchPlayer)
        return;

    // The reader is created only after a view actually requests metadata. It
    // has no audio output because decoding silence is unnecessary for tags.
    m_prefetchPlayer = new QMediaPlayer(this);
    connect(m_prefetchPlayer, &QMediaPlayer::metaDataChanged,
            this, &MusicLibrary::onPrefetchMetaDataChanged);
    connect(m_prefetchPlayer, &QMediaPlayer::durationChanged,
            this, &MusicLibrary::onPrefetchDurationChanged);
    connect(m_prefetchPlayer, &QMediaPlayer::mediaStatusChanged,
            this, [this](QMediaPlayer::MediaStatus status) {
                if (status == QMediaPlayer::LoadedMedia
                        && !m_currentPrefetchSource.isEmpty()
                        && !m_prefetchAdvanceScheduled
                        && !m_prefetchPlayer->metaData().isEmpty()) {
                    // A few backends report LoadedMedia without emitting a
                    // separate metadataChanged signal.
                    onPrefetchMetaDataChanged();
                }
            });
    connect(m_prefetchPlayer, &QMediaPlayer::errorOccurred,
            this, [this](QMediaPlayer::Error, const QString &) {
                finishCurrentPrefetch(true);
            });
}

void MusicLibrary::storeMetadata(const QString &source, const QVariantMap &metadata)
{
    if (source.isEmpty())
        return;
    if (!m_metaCache.contains(source) && m_metaCache.size() >= kMaxMetadataCacheSize)
        m_metaCache.erase(m_metaCache.begin());
    m_metaCache.insert(source, metadata);
}

void MusicLibrary::prefetchMetadata(const QStringList &files)
{
    for (const QString &f : files) {
        if (f.isEmpty()) continue;
        QString local = f;
        if (f.startsWith("file:")) {
            QUrl u(f);
            if (u.isValid()) local = u.toLocalFile();
        }
        if (!isValidMusicFile(local)) continue;
        if (m_currentPrefetchSource == local || m_prefetchQueue.contains(local)
                || m_metaCache.contains(local)) {
            continue;
        }
        if (m_prefetchQueue.size() >= kMaxMetadataQueueSize)
            break;
        m_prefetchQueue.append(local);
    }
    if (!m_prefetchActive) {
        m_prefetchActive = true;
        QTimer::singleShot(0, this, &MusicLibrary::processNextPrefetch);
    }
}

void MusicLibrary::processNextPrefetch()
{
    if (m_prefetchAdvanceScheduled)
        return;
    if (m_prefetchQueue.isEmpty()) {
        m_prefetchActive = false;
        m_currentPrefetchSource.clear();
        m_prefetchTimeoutTimer->stop();
        return;
    }

    ensurePrefetchPlayer();
    m_currentPrefetchSource = m_prefetchQueue.takeFirst();
    m_prefetchTimeoutTimer->start();
    if (m_currentPrefetchSource.startsWith("qrc:/")) {
        m_prefetchPlayer->setSource(QUrl(m_currentPrefetchSource));
    } else {
        m_prefetchPlayer->setSource(QUrl::fromLocalFile(m_currentPrefetchSource));
    }
    // setSource is sufficient to ask the backend for tags. Do not call play()
    // for a metadata-only request: that starts a decoder and competes with
    // the visible player for CPU and audio-device resources.
}

void MusicLibrary::onPrefetchMetaDataChanged()
{
    if (m_currentPrefetchSource.isEmpty() || m_prefetchAdvanceScheduled)
        return;
    const QMediaMetaData md = m_prefetchPlayer->metaData();
    QVariantMap meta;
    QString title = md.value(QMediaMetaData::Title).toString();
    QString artist;
    if (md.value(QMediaMetaData::AlbumArtist).isValid()) artist = md.value(QMediaMetaData::AlbumArtist).toString();
    else if (md.value(QMediaMetaData::ContributingArtist).isValid()) artist = md.value(QMediaMetaData::ContributingArtist).toString();
    meta.insert("title", title);
    meta.insert("artist", artist);
    meta.insert("duration", m_prefetchPlayer->duration());
    storeMetadata(m_currentPrefetchSource, meta);
    emit metadataReady(m_currentPrefetchSource, meta);
    finishCurrentPrefetch(false);
}

void MusicLibrary::onPrefetchDurationChanged(qint64 duration)
{
    if (m_currentPrefetchSource.isEmpty() || m_prefetchAdvanceScheduled)
        return;
    auto meta = m_metaCache.value(m_currentPrefetchSource);
    meta.insert("duration", static_cast<int>(duration));
    storeMetadata(m_currentPrefetchSource, meta);
}

void MusicLibrary::finishCurrentPrefetch(bool cacheFallback)
{
    if (m_currentPrefetchSource.isEmpty() || m_prefetchAdvanceScheduled)
        return;

    const QString source = m_currentPrefetchSource;
    m_prefetchAdvanceScheduled = true;
    m_prefetchTimeoutTimer->stop();

    if (cacheFallback && !m_metaCache.contains(source)) {
        QVariantMap fallback;
        fallback.insert("title", QFileInfo(source).completeBaseName());
        fallback.insert("artist", QString());
        fallback.insert("duration", 0);
        storeMetadata(source, fallback);
        emit metadataReady(source, fallback);
    }

    if (m_prefetchPlayer)
        m_prefetchPlayer->stop();

    // Let any backend callbacks queued by stop() drain before starting the
    // next source. This prevents late duration/meta signals crossing sources.
    QTimer::singleShot(0, this, [this] {
        m_currentPrefetchSource.clear();
        m_prefetchAdvanceScheduled = false;
        processNextPrefetch();
    });
}

// 新增：文件监控功能
void MusicLibrary::startWatching()
{
    if (m_isWatching) return;
    
    m_isWatching = true;
    m_watchedPaths.clear();
    
    // 添加项目根目录到监控
    QString projectRoot = defaultProjectRoot();
    if (!projectRoot.isEmpty()) {
        addWatchPath(projectRoot);
    }
    
    // 添加Windows音乐文件夹到监控
    QString windowsMusic = getWindowsMusicFolder();
    if (!windowsMusic.isEmpty()) {
        addWatchPath(windowsMusic);
    }
    
}

void MusicLibrary::stopWatching()
{
    if (!m_isWatching) return;
    
    m_isWatching = false;
    m_watcher->removePaths(m_watchedPaths);
    m_watchedPaths.clear();
    m_scanTimer->stop();
}

bool MusicLibrary::isWatching() const
{
    return m_isWatching;
}

void MusicLibrary::addWatchDirectory(const QString &path)
{
    QString local = path;
    if (path.startsWith("file:")) {
        QUrl u(path);
        if (u.isValid()) local = u.toLocalFile();
    }
    addWatchPath(local);
}

// 新增：缓存管理
void MusicLibrary::clearCache()
{
    m_cachedFiles.clear();
    m_metaCache.clear();
    m_lyricsPathCache.clear();
    m_prefetchQueue.clear();
}

int MusicLibrary::getCachedFileCount() const
{
    return m_cachedFiles.size();
}

// 新增：文件监控槽函数
void MusicLibrary::onDirectoryChanged(const QString &path)
{
    // 检查路径是否仍然存在
    QDir dir(path);
    if (!dir.exists()) {
        // 重新添加父目录到监控（如果存在）
        QDir parentDir = dir;
        if (parentDir.cdUp() && parentDir.exists()) {
            m_watcher->addPath(parentDir.absolutePath());
        }
    }
    
    // 延迟扫描以避免频繁更新
    m_scanTimer->start();
}

void MusicLibrary::onFileChanged(const QString &path)
{
    // 检查文件是否仍然存在
    QFileInfo fileInfo(path);
    if (!fileInfo.exists()) {
        // 从监控中移除
        m_watcher->removePath(path);
    }
    
    // 延迟扫描以避免频繁更新
    m_scanTimer->start();
}

void MusicLibrary::performDelayedScan()
{
    if (!m_isWatching) return;
    const qint64 now = QDateTime::currentMSecsSinceEpoch();
    if (m_lastScanMs > 0 && (now - m_lastScanMs) < 7000) {
        // 退抖：7s 内不重复全量扫描
        m_scanTimer->start();
        return;
    }
    m_lastScanMs = now;

    // Keep watcher callbacks lightweight; the worker applies the same diff
    // and emits the legacy signals when the result returns to the GUI thread.
    const QStringList roots = m_watchedPaths.isEmpty()
            ? allAvailableScanRoots()
            : m_watchedPaths;
    requestAsyncScan(roots, true, false);
}

// 新增：辅助方法
QStringList MusicLibrary::getValidMusicExtensions() const
{
    return validMusicExtensions();
}

bool MusicLibrary::isValidMusicFile(const QString &filePath) const
{
    const QString local = normalizedLocalPath(filePath);
    QFileInfo fileInfo(local);
    if (!fileInfo.exists() || !fileInfo.isFile()) {
        return false;
    }
    
    const QString extension = fileInfo.suffix().toLower();
    return validMusicExtensions().contains(extension);
}

void MusicLibrary::addWatchPath(const QString &path)
{
    if (path.isEmpty() || m_watchedPaths.contains(path)) {
        return;
    }
    
    QDir dir(path);
    if (!dir.exists()) {
        return;
    }
    
    m_watchedPaths.append(path);
    m_watcher->addPath(path);
    // 取消递归子目录监控，避免大量事件导致频繁全量扫描
}

void MusicLibrary::updateFileCache()
{
    m_cachedFiles = scanAllAvailableMusic(true);
}

QStringList MusicLibrary::scanOnlyDirectory(const QString &path)
{
    const QString local = normalizedLocalPath(path);
    stopWatching();
    m_watchedPaths.clear();
    m_isWatching = true;
    addWatchPath(local);
    QStringList files = scanMusicFiles(local, true);
    m_cachedFiles = files;
    emit musicFilesChanged(files);
    return files;
}

void MusicLibrary::scanOnlyDirectoryAsync(const QString &path)
{
    const QString local = normalizedLocalPath(path);
    stopWatching();
    m_watchedPaths.clear();
    m_isWatching = true;
    addWatchPath(local);
    requestAsyncScan(QStringList{local}, true, true);
}

void MusicLibrary::startWatchingSingle(const QString &path)
{
    stopWatching();
    m_isWatching = true;
    m_watchedPaths.clear();
    QString local = path;
    if (path.startsWith("file:")) {
        QUrl u(path);
        if (u.isValid()) local = u.toLocalFile();
    }
    addWatchPath(local);
}
