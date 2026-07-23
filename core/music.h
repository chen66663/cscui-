// core/music.h
#ifndef CORE_MUSIC_H
#define CORE_MUSIC_H

// Public media services exposed to QML. Implementation stays in core/music.cpp
// so UI components do not need to know about filesystem or multimedia details.
#include <QObject>
#include <QString>
#include <QStringList>
#include <QUrl>
#include <QMediaMetaData>
#include <QTimer>
#include <QFileSystemWatcher>
#include <QFutureWatcher>
#include <QHash>
#include <QVariantMap>

#include <atomic>
#include <memory>

class QMediaPlayer;
class QFileInfo;

// Reads metadata for one source without taking ownership of the source path.
class AudioMetadata : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString title READ title NOTIFY titleChanged)
    Q_PROPERTY(QString artist READ artist NOTIFY artistChanged)
    Q_PROPERTY(QString album READ album NOTIFY albumChanged)
    Q_PROPERTY(QUrl coverImageUrl READ coverImageUrl NOTIFY coverImageUrlChanged)
    Q_PROPERTY(QString source READ source WRITE setSource NOTIFY sourceChanged)
    Q_PROPERTY(int duration READ duration NOTIFY durationChanged)

public:
    explicit AudioMetadata(QObject *parent = nullptr);
    ~AudioMetadata() override;

    QString title() const { return m_title; }
    QString artist() const { return m_artist; }
    QString album() const { return m_album; }
    QUrl coverImageUrl() const { return m_coverImageUrl; }
    QString source() const { return m_source; }
    int duration() const { return m_duration; }

    Q_INVOKABLE void setSource(const QString &source);
    Q_INVOKABLE void loadMetadata();

signals:
    void titleChanged();
    void artistChanged();
    void albumChanged();
    void coverImageUrlChanged();
    void sourceChanged();
    void durationChanged();
    void metadataLoaded();

private slots:
    void onMetaDataChanged();
    void onDurationChanged(qint64 duration);

private:
    void extractCoverArt();
    QString extractFileNameTitle(const QString &filePath);

    QMediaPlayer *m_mediaPlayer;
    QString m_title;
    QString m_artist;
    QString m_album;
    QUrl m_coverImageUrl;
    QString m_source;
    int m_duration;
    QString m_tempCoverPath;
    QString m_pendingCoverPath;
    std::shared_ptr<std::atomic_bool> m_coverCancellation;
    quint64 m_coverGeneration = 0;
    bool m_coverExtractionPending = false;
};

// Scans user-approved locations and emits debounced change notifications.
class MusicLibrary : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool scanInProgress READ isScanInProgress NOTIFY scanInProgressChanged)
public:
    explicit MusicLibrary(QObject *parent = nullptr);
    ~MusicLibrary() override;

    Q_INVOKABLE QStringList scanMusicFiles(const QString &rootPath, bool recursive = true);
    Q_INVOKABLE QString defaultProjectRoot();
    Q_INVOKABLE QStringList scanDefaultProjectMusic(bool recursive = true);
    
    // 新增：Windows音乐文件夹支持
    Q_INVOKABLE QString getWindowsMusicFolder();
    Q_INVOKABLE QStringList scanWindowsMusic(bool recursive = true);
    Q_INVOKABLE QStringList scanAllAvailableMusic(bool recursive = true);

    // Non-blocking scan APIs are intended for QML views. The legacy
    // synchronous methods above remain available for source compatibility.
    Q_INVOKABLE void scanAllAvailableMusicAsync(bool recursive = true);
    Q_INVOKABLE void scanOnlyDirectoryAsync(const QString &path);
    Q_INVOKABLE bool isScanInProgress() const;

    // 新增：歌词支持（返回文本或文件URL）
    Q_INVOKABLE QString loadLyricsText(const QString &source);
    Q_INVOKABLE void loadLyricsTextAsync(const QString &source);
    Q_INVOKABLE QString findLyricsFileForSource(const QString &source);
    Q_INVOKABLE QVariantMap getMetadata(const QString &source);
    Q_INVOKABLE void prefetchMetadata(const QStringList &files);
    Q_INVOKABLE QStringList scanOnlyDirectory(const QString &path);
    
    // 新增：文件监控功能
    Q_INVOKABLE void startWatching();
    Q_INVOKABLE void stopWatching();
    Q_INVOKABLE bool isWatching() const;
    Q_INVOKABLE void addWatchDirectory(const QString &path);
    Q_INVOKABLE void startWatchingSingle(const QString &path);
    
    // 新增：缓存和性能优化
    Q_INVOKABLE void clearCache();
    Q_INVOKABLE int getCachedFileCount() const;
    Q_INVOKABLE bool isValidMusicFile(const QString &filePath) const;

signals:
    void musicFilesChanged(const QStringList &newFiles);
    void fileAdded(const QString &filePath);
    void fileRemoved(const QString &filePath);
    void metadataReady(const QString &source, const QVariantMap &meta);
    void lyricsReady(const QString &source, const QString &text, const QString &filePath);
    void scanInProgressChanged();
    void musicScanStarted(quint64 generation);
    void musicScanFinished(const QStringList &files, quint64 generation);

private slots:
    void onDirectoryChanged(const QString &path);
    void onFileChanged(const QString &path);
    void performDelayedScan();
    void processNextPrefetch();
    void onPrefetchMetaDataChanged();
    void onPrefetchDurationChanged(qint64 duration);
    void onAsyncScanFinished();

private:
    QString findProjectRootFromAppDir() const;
    QStringList getValidMusicExtensions() const;
    QStringList allAvailableScanRoots() const;
    void addWatchPath(const QString &path);
    void updateFileCache();
    void requestAsyncScan(const QStringList &roots, bool recursive, bool forceNotification);
    void launchAsyncScan(const QStringList &roots,
                         bool recursive,
                         bool forceNotification,
                         quint64 generation);
    void applyScanResult(const QStringList &files, bool forceNotification);
    void ensurePrefetchPlayer();
    void finishCurrentPrefetch(bool cacheFallback);
    void storeMetadata(const QString &source, const QVariantMap &metadata);
    QFileSystemWatcher *m_watcher;
    QTimer *m_scanTimer;
    QStringList m_cachedFiles;
    QStringList m_watchedPaths;
    bool m_isWatching;
    QMediaPlayer *m_prefetchPlayer;
    QTimer *m_prefetchTimeoutTimer;
    QStringList m_prefetchQueue;
    bool m_prefetchActive;
    bool m_prefetchAdvanceScheduled = false;
    QString m_currentPrefetchSource;
    QHash<QString, QVariantMap> m_metaCache;
    QHash<QString, QString> m_lyricsPathCache;
    bool m_singleMode = false;

    // One watcher serializes requests for this object. The shared worker pool
    // is capped separately in music.cpp to avoid competing disk walks.
    QFutureWatcher<QStringList> *m_scanWatcher;
    std::shared_ptr<std::atomic_bool> m_activeScanCancellation;
    std::shared_ptr<std::atomic_bool> m_lyricsCancellation;
    quint64 m_scanGeneration = 0;
    quint64 m_lyricsGeneration = 0;
    quint64 m_activeScanGeneration = 0;
    bool m_scanInProgress = false;
    bool m_activeScanForceNotification = false;
    bool m_hasPendingScan = false;
    QStringList m_pendingScanRoots;
    bool m_pendingScanRecursive = true;
    bool m_pendingScanForceNotification = false;
    quint64 m_pendingScanGeneration = 0;

    static const int SCAN_DELAY_MS = 4000;
    qint64 m_lastScanMs = 0;
};

#endif // CORE_MUSIC_H
