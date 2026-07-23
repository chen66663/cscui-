#include <QCommandLineOption>
#include <QCommandLineParser>
#include <QCoreApplication>
#include <QDebug>
#include <QDir>
#include <QFileInfo>
#include <QGuiApplication>
#include <QIcon>
#include <QImage>
#include <QLoggingCategory>
#include <QQuickWindow>
#include <QRegularExpression>
#include <QSize>
#include <QTimer>
#include <QUrl>
#include <QQmlContext>
#include <QQmlApplicationEngine>
#include <QQmlComponent>
#include <QVariantMap>

#include <QElapsedTimer>

#include "core/music.h"

namespace {

QString buildMode()
{
#ifdef QT_DEBUG
    return QStringLiteral("Debug");
#else
    return QStringLiteral("Release");
#endif
}

QString normalizedTheme(const QString &value)
{
    const QString normalized = value.trimmed().toLower();
    return normalized == QStringLiteral("light") || normalized == QStringLiteral("dark")
            ? normalized
            : QStringLiteral("auto");
}

QString normalizedLanguage(const QString &value)
{
    const QString normalized = value.trimmed().toLower();
    return normalized == QStringLiteral("en") || normalized == QStringLiteral("zh")
            ? normalized
            : QStringLiteral("auto");
}

int parsePageIndex(const QString &value, bool *ok)
{
    const QString normalized = value.trimmed().toLower();
    if (normalized == QStringLiteral("core") || normalized == QStringLiteral("0")) {
        *ok = true;
        return 0;
    }
    if (normalized == QStringLiteral("light") || normalized == QStringLiteral("1")) {
        *ok = true;
        return 1;
    }
    if (normalized == QStringLiteral("extended") || normalized == QStringLiteral("2")) {
        *ok = true;
        return 2;
    }

    *ok = false;
    return 0;
}

QSize parseWindowSize(const QString &value, bool *ok)
{
    const QRegularExpression expression(QStringLiteral(R"(^\s*(\d+)\s*[xX]\s*(\d+)\s*$)"));
    const QRegularExpressionMatch match = expression.match(value);
    if (!match.hasMatch()) {
        *ok = false;
        return {};
    }

    const int width = match.captured(1).toInt(ok);
    if (!*ok)
        return {};
    const int height = match.captured(2).toInt(ok);
    if (!*ok)
        return {};
    return {width, height};
}

void scheduleScreenshot(QQuickWindow *window, const QString &path)
{
    // Page delegates are incubated asynchronously. Wait for the selected page
    // to become ready before capturing, then allow one rendered frame for
    // layout and Canvas content to settle. The timeout keeps a broken page from
    // hanging a CI smoke test indefinitely.
    auto *readinessTimer = new QTimer(window);
    readinessTimer->setInterval(100);
    auto *elapsed = new QElapsedTimer();
    elapsed->start();

    QObject::connect(readinessTimer, &QTimer::timeout, window,
                     [window, path, readinessTimer, elapsed] {
        const bool ready = window->property("currentPageReady").toBool();
        if (!ready && elapsed->elapsed() < 15000)
            return;

        readinessTimer->stop();
        readinessTimer->deleteLater();
        const bool timedOut = !ready;
        QTimer::singleShot(timedOut ? 0 : 220, window, [window, path, elapsed, timedOut] {
            delete elapsed;
            if (timedOut)
                qWarning().noquote() << "Timed out waiting for page readiness; capturing current surface.";

            const QFileInfo outputInfo(path);
            if (!QDir().mkpath(outputInfo.absolutePath())) {
                qCritical().noquote() << "Unable to create screenshot directory:" << outputInfo.absolutePath();
                QCoreApplication::exit(EXIT_FAILURE);
                return;
            }

            const QImage image = window->grabWindow();
            if (image.isNull() || !image.save(outputInfo.absoluteFilePath())) {
                qCritical().noquote() << "Unable to save screenshot:" << outputInfo.absoluteFilePath();
                QCoreApplication::exit(EXIT_FAILURE);
                return;
            }
            QCoreApplication::quit();
        });
    });
    readinessTimer->start();
}

} // namespace

int main(int argc, char *argv[])
{
    QGuiApplication application(argc, argv);
    QCoreApplication::setApplicationName(QStringLiteral("cscui"));
    QCoreApplication::setApplicationVersion(QStringLiteral("1.0.0"));
    QCoreApplication::setOrganizationName(QStringLiteral("cscui"));
    QCoreApplication::setOrganizationDomain(QStringLiteral("cscui.local"));

    QCommandLineParser parser;
    parser.setApplicationDescription(QStringLiteral("cscui Qt Quick component workbench"));
    parser.addHelpOption();
    parser.addVersionOption();

    const QCommandLineOption debugUiOption(
            QStringList{QStringLiteral("debug-ui")},
            QStringLiteral("Open the runtime UI inspector at startup."));
    const QCommandLineOption screenshotOption(
            QStringList{QStringLiteral("screenshot")},
            QStringLiteral("Save a startup screenshot and exit."),
            QStringLiteral("path"));
    const QCommandLineOption themeOption(
            QStringList{QStringLiteral("theme")},
            QStringLiteral("Select the appearance: auto, light or dark."),
            QStringLiteral("mode"),
            QStringLiteral("auto"));
    const QCommandLineOption languageOption(
            QStringList{QStringLiteral("language")},
            QStringLiteral("Select the interface language: auto, en or zh."),
            QStringLiteral("language"),
            QStringLiteral("auto"));
    const QCommandLineOption windowSizeOption(
            QStringList{QStringLiteral("window-size")},
            QStringLiteral("Set the initial window size for smoke tests (WIDTHxHEIGHT)."),
            QStringLiteral("size"));
    const QCommandLineOption pageOption(
            QStringList{QStringLiteral("page")},
            QStringLiteral("Select the startup catalogue page: core, light or extended."),
            QStringLiteral("name"),
            QStringLiteral("core"));
    parser.addOption(debugUiOption);
    parser.addOption(screenshotOption);
    parser.addOption(themeOption);
    parser.addOption(languageOption);
    parser.addOption(windowSizeOption);
    parser.addOption(pageOption);
    parser.process(application);

    const QString themeMode = normalizedTheme(parser.value(themeOption));
    const QString languageMode = normalizedLanguage(parser.value(languageOption));
    const bool debugUiEnabled = parser.isSet(debugUiOption);
    const QString screenshotPath = parser.value(screenshotOption);
    bool pageValid = false;
    const int requestedPage = parsePageIndex(parser.value(pageOption), &pageValid);
    if (!pageValid) {
        qCritical().noquote() << "--page must be core, light or extended.";
        return 2;
    }
    QSize windowSize;
    if (parser.isSet(windowSizeOption)) {
        bool sizeValid = false;
        windowSize = parseWindowSize(parser.value(windowSizeOption), &sizeValid);
        if (!sizeValid || windowSize.width() < 760 || windowSize.height() < 560
                || windowSize.width() > 4096 || windowSize.height() > 4096) {
            qCritical().noquote() << "--window-size must be WIDTHxHEIGHT between 760x560 and 4096x4096.";
            return 2;
        }
    }

    QString loggingRules = QStringLiteral(
            "qt.multimedia.ffmpeg.*=false\n"
            "qt.multimedia.audio.*=false\n"
            "qt.multimedia.playback.*=false\n"
            "qt.multimedia.video.*=false\n"
            "cscui.debug=%1\n")
                                             .arg(debugUiEnabled ? QStringLiteral("true")
                                                                 : QStringLiteral("false"));
    // Keep release output quiet while allowing deterministic Qt category
    // profiling without recompiling the application. The app-specific name
    // prevents unrelated process-wide QT_LOGGING_RULES from changing policy.
    const QString diagnosticRules = qEnvironmentVariable("CSCUI_LOGGING_RULES").trimmed();
    if (!diagnosticRules.isEmpty()) {
        loggingRules.append(QLatin1Char('\n'));
        loggingRules.append(diagnosticRules);
    }
    QLoggingCategory::setFilterRules(loggingRules);

    application.setWindowIcon(QIcon(QStringLiteral(":/cscui/fonts/icon.ico")));

    // Product types are registered in the cscui module so pages can keep their
    // versioned imports while the shell receives runtime settings explicitly.
    qmlRegisterType<AudioMetadata>("cscui", 1, 0, "AudioMetadata");
    qmlRegisterType<MusicLibrary>("cscui", 1, 0, "MusicLibrary");

    QQmlApplicationEngine engine;

    // Create one theme object before loading Main so every legacy component
    // inherits the same root-context value during construction. This avoids
    // light-theme fallbacks in controls that predate an explicit theme API.
    QQmlComponent themeComponent(
            &engine, QUrl(QStringLiteral("qrc:/qt/qml/cscui/components/Theme.qml")));
    QObject *sharedTheme = themeComponent.create();
    if (!sharedTheme) {
        qCritical() << "Unable to create cscui theme:" << themeComponent.errors();
        return EXIT_FAILURE;
    }
    sharedTheme->setParent(&engine);
    // Set language before Main.qml is instantiated so translated bindings do
    // not briefly render in the host locale when a CLI override is requested.
    sharedTheme->setProperty("language", languageMode);
    engine.rootContext()->setContextProperty(QStringLiteral("theme"), sharedTheme);

    // Initial properties are part of Main.qml's public contract. Unlike context
    // properties, this path is visible to qmllint and is type-checked at load.
    engine.setInitialProperties({
            {QStringLiteral("debugUi"), debugUiEnabled},
            {QStringLiteral("buildMode"), buildMode()},
            {QStringLiteral("themeMode"), themeMode},
            {QStringLiteral("languageMode"), languageMode},
            {QStringLiteral("screenshotPath"), screenshotPath},
            {QStringLiteral("requestedWidth"), windowSize.width()},
            {QStringLiteral("requestedHeight"), windowSize.height()},
            {QStringLiteral("requestedPage"), requestedPage}
    });

    QObject::connect(&engine,
                     &QQmlApplicationEngine::objectCreationFailed,
                     &application,
                     [] { QCoreApplication::exit(EXIT_FAILURE); },
                     Qt::QueuedConnection);

    engine.loadFromModule(QStringLiteral("cscui"), QStringLiteral("Main"));

    if (!screenshotPath.isEmpty() && !engine.rootObjects().isEmpty()) {
        auto *window = qobject_cast<QQuickWindow *>(engine.rootObjects().constFirst());
        if (!window) {
            qCritical() << "The cscui root object is not a QQuickWindow.";
            return EXIT_FAILURE;
        }
        scheduleScreenshot(window, screenshotPath);
    }
    return application.exec();
}
