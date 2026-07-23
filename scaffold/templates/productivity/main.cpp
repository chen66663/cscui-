#include <cstdlib>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QIcon>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setWindowIcon(QIcon(":/cscui/fonts/icon.ico"));
    QQmlApplicationEngine engine;
    QObject::connect(&engine,
                     &QQmlApplicationEngine::objectCreationFailed,
                     &app,
                     [] { QCoreApplication::exit(EXIT_FAILURE); },
                     Qt::QueuedConnection);
    // Keep the generated application on the same versioned module contract.
    engine.loadFromModule("cscui", "Main");
    return app.exec();
}
