#include <QColor>
#include <QCoreApplication>
#include <QGuiApplication>
#include <QIcon>
#include <QLibraryInfo>
#include <QLocale>
#include <QPalette>
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

    // Seed the application palette with the dark Biaox surfaces. This keeps the
    // window background dark before the QML scene is ready. The full dark
    // palette used by Basic-style popups (such as the text-field context menu)
    // is defined on the ApplicationWindow in qml/Main.qml; keep both in sync
    // with qml/Theme.qml.
    QPalette palette = app.palette();
    palette.setColor(QPalette::Window, QColor(0x00, 0x00, 0x00));
    palette.setColor(QPalette::WindowText, QColor(0xFF, 0xFF, 0xFF));
    palette.setColor(QPalette::Base, QColor(0x0F, 0x0F, 0x0F));
    palette.setColor(QPalette::AlternateBase, QColor(0x1A, 0x1A, 0x1A));
    palette.setColor(QPalette::Text, QColor(0xFF, 0xFF, 0xFF));
    palette.setColor(QPalette::Button, QColor(0x1A, 0x1A, 0x1A));
    palette.setColor(QPalette::ButtonText, QColor(0xFF, 0xFF, 0xFF));
    palette.setColor(QPalette::Highlight, QColor(0xFF, 0x99, 0x00));
    palette.setColor(QPalette::HighlightedText, QColor(0x00, 0x00, 0x00));
    palette.setColor(QPalette::PlaceholderText, QColor(0x8A, 0x8A, 0x8A));
    palette.setColor(QPalette::Mid, QColor(0x5A, 0x5A, 0x5A));
    palette.setColor(QPalette::Dark, QColor(0x2A, 0x2A, 0x2A));
    palette.setColor(QPalette::Shadow, QColor(0x00, 0x00, 0x00));
    palette.setColor(QPalette::ToolTipBase, QColor(0x1A, 0x1A, 0x1A));
    palette.setColor(QPalette::ToolTipText, QColor(0xFF, 0xFF, 0xFF));
    app.setPalette(palette);

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

    // Basic is the neutral Qt Quick Controls style; the Biaox look is provided
    // by the project-local Theme singleton and App* components in qml/.
    QQuickStyle::setStyle(QStringLiteral("Basic"));

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
