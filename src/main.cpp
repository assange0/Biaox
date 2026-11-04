#include <QCoreApplication>
#include <QGuiApplication>
#include <QIcon>
#include <QLibraryInfo>
#include <QLocale>
#include <QQmlApplicationEngine>
#include <QQmlEngine>
#include <QQmlError>
#include <QQuickStyle>
#include <QStringList>
#include <QTranslator>
#include <QUrl>

#include <cstdio>

int main(int argc, char *argv[])
{
    QCoreApplication::setApplicationName(QStringLiteral("Biaox"));
    QCoreApplication::setApplicationVersion(QStringLiteral("0.1.0"));

    QGuiApplication app(argc, argv);

    // Translate Qt's own dialog/standard-button strings into the system locale.
    const QString translationsPath =
        QLibraryInfo::path(QLibraryInfo::TranslationsPath);
    QTranslator qtBaseTranslator;
    QTranslator qtDeclarativeTranslator;
    if (qtBaseTranslator.load(QLocale::system(), QStringLiteral("qtbase"),
                              QStringLiteral("_"), translationsPath)) {
        app.installTranslator(&qtBaseTranslator);
    }
    if (qtDeclarativeTranslator.load(QLocale::system(), QStringLiteral("qtdeclarative"),
                                     QStringLiteral("_"), translationsPath)) {
        app.installTranslator(&qtDeclarativeTranslator);
    }

    // The menu/back icons are bundled with the application as an icon theme.
    QIcon::setThemeSearchPaths(QStringList{QStringLiteral(":/icons")}
                               + QIcon::themeSearchPaths());
    QIcon::setThemeName(QStringLiteral("biaox"));
    QGuiApplication::setWindowIcon(QIcon(QStringLiteral(":/icons/biaox/app.png")));

    QQuickStyle::setStyle(QStringLiteral("Material"));

    QQmlApplicationEngine engine;
    QObject::connect(&engine, &QQmlEngine::warnings, &engine,
                     [](const QList<QQmlError> &warnings) {
                         for (const QQmlError &warning : warnings) {
                             const QByteArray text = warning.toString().toLocal8Bit();
                             std::fprintf(stderr, "QML: %s\n", text.constData());
                         }
                     });

    engine.loadFromModule(QStringLiteral("Biaox"), QStringLiteral("Main"));
    if (engine.rootObjects().isEmpty())
        return 1;

    return app.exec();
}
