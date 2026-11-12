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
#include <QSettings>
#include <QStringList>
#include <QStyleHints>
#include <QTranslator>
#include <QUrl>

#include <cstdio>

int main(int argc, char *argv[])
{
    QCoreApplication::setApplicationName(QStringLiteral("Biaox"));
    QCoreApplication::setOrganizationName(QStringLiteral("Biaox"));
    QCoreApplication::setApplicationVersion(QStringLiteral("0.1.0"));

    QGuiApplication app(argc, argv);

    // 启动防白闪：按持久化的主题偏好设置窗口底色（默认跟随系统配色；无 portal
    // 环境 colorScheme 为 Unknown 时回退深色）。QML 场景就绪后运行期颜色全部
    // 由 qml/Theme.qml 的 token 接管（在 qml/Main.qml 中绑定到 ApplicationWindow）。
    const QSettings settings;
    const QString theme = settings.value(QStringLiteral("appearance/theme"),
                                         QStringLiteral("system")).toString();
    const bool lightTheme = theme == QLatin1String("light")
        || (theme == QLatin1String("system")
            && app.styleHints()->colorScheme() == Qt::ColorScheme::Light);
    QPalette palette = app.palette();
    palette.setColor(QPalette::Window,
                     lightTheme ? QColor(0xFA, 0xFA, 0xFA) : QColor(0x00, 0x00, 0x00));
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
