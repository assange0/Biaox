#include <QtTest>

#include <QtCore/private/qzipreader_p.h>

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QTemporaryDir>
#include <QUrl>

#include "mobakeygen.hpp"

class TestMobaKeygen : public QObject
{
    Q_OBJECT

private slots:
    void initTestCase();
    void cleanupTestCase();

    void licenseVectors_data();
    void licenseVectors();

    void rejectsInvalidInput();
    void writesMxtpro();
    void versionListReloads();
    void remembersTypedVersion();

private:
    QString configDirectory() const;
    QTemporaryDir m_configDir;
};

void TestMobaKeygen::initTestCase()
{
    QVERIFY(m_configDir.isValid());
    qputenv("MOBAXKEYGEN_CONFIG_DIR", m_configDir.path().toLocal8Bit());

    QCoreApplication::setOrganizationName(QStringLiteral("mykeygens"));
    QCoreApplication::setApplicationName(QStringLiteral("MobaXtermKeygenTest"));

    QDir(configDirectory()).removeRecursively();
    QDir().mkpath(configDirectory());
}

void TestMobaKeygen::cleanupTestCase()
{
    QDir(configDirectory()).removeRecursively();
    qunsetenv("MOBAXKEYGEN_CONFIG_DIR");
}

QString TestMobaKeygen::configDirectory() const
{
    return QString::fromLocal8Bit(qgetenv("MOBAXKEYGEN_CONFIG_DIR"));
}

void TestMobaKeygen::licenseVectors_data()
{
    QTest::addColumn<QString>("user");
    QTest::addColumn<QString>("version");
    QTest::addColumn<QString>("expected");

    QTest::newRow("10.9-ascii")
        << QStringLiteral("roger") << QStringLiteral("10.9")
        << QStringLiteral("2smOn8SL6QTe4F3a5tWe4tXc+F3a4tGerh3a");
    QTest::newRow("20.2-ascii")
        << QStringLiteral("roger") << QStringLiteral("20.2")
        << QStringLiteral("2smOn8SL6Qje4p3a5tme4tne+p3a4tGerh3a");
    QTest::newRow("26.6-ascii")
        << QStringLiteral("test") << QStringLiteral("26.6")
        << QStringLiteral("2sGPtsDP0onf+tWerpnf75nf+tGerh3a4tG");
    QTest::newRow("10.9-unicode")
        << QStringLiteral("请输入用户名") << QStringLiteral("10.9")
        << QStringLiteral("2sGon/Po2vdrN3+rcDurA/frYXMN5hXcrl3a5h3ex5Xcrh3a4tGerB");
}

void TestMobaKeygen::licenseVectors()
{
    QFETCH(QString, user);
    QFETCH(QString, version);
    QFETCH(QString, expected);

    MobaKeygen keygen;
    keygen.setUserName(user);
    keygen.setVersion(version);

    QVERIFY2(keygen.generateLicense(), "license generation failed");
    QCOMPARE(keygen.licenseKey(), expected);
}

void TestMobaKeygen::rejectsInvalidInput()
{
    MobaKeygen keygen;
    keygen.setVersion(QStringLiteral("26.6"));

    keygen.setUserName(QString());
    QVERIFY(!keygen.generateLicense());

    keygen.setUserName(QStringLiteral("bad#name"));
    QVERIFY(!keygen.generateLicense());

    keygen.setUserName(QStringLiteral("bad|name"));
    QVERIFY(!keygen.generateLicense());

    keygen.setUserName(QStringLiteral("roger"));
    keygen.setVersion(QStringLiteral("26"));
    QVERIFY(!keygen.generateLicense());

    keygen.setVersion(QStringLiteral("26.6.1"));
    QVERIFY(!keygen.generateLicense());

    keygen.setVersion(QStringLiteral("abc"));
    QVERIFY(!keygen.generateLicense());

    keygen.setVersion(QStringLiteral("26.6"));
    QVERIFY(keygen.generateLicense());
}

void TestMobaKeygen::writesMxtpro()
{
    QTemporaryDir directory;
    QVERIFY(directory.isValid());

    MobaKeygen keygen;
    keygen.setUserName(QStringLiteral("roger"));
    keygen.setVersion(QStringLiteral("10.9"));
    QVERIFY(keygen.generateLicense());

    const QString path = directory.filePath(QStringLiteral("Custom.mxtpro"));
    QVERIFY(keygen.saveLicense(QUrl::fromLocalFile(path)));
    QVERIFY(QFileInfo::exists(path));
    QCOMPARE(keygen.lastSavedPath(), QDir::toNativeSeparators(path));

    QZipReader reader(path);
    QVERIFY(reader.isReadable());
    QCOMPARE(reader.fileData(QStringLiteral("Pro.key")),
             keygen.licenseKey().toUtf8());
}

void TestMobaKeygen::versionListReloads()
{
    MobaKeygen keygen;
    QVERIFY(!keygen.versionsFilePath().isEmpty());

    QFile file(keygen.versionsFilePath());
    const bool opened = file.open(QIODevice::WriteOnly | QIODevice::Truncate | QIODevice::Text);
    QVERIFY2(opened, qPrintable(QStringLiteral("path=%1 error=%2").arg(keygen.versionsFilePath(), file.errorString())));
    file.write("# test list\n26.6\n99.9\nnot-a-version\n");
    file.close();

    keygen.reloadVersions();

    QVERIFY(keygen.versionList().contains(QStringLiteral("26.6")));
    QVERIFY(keygen.versionList().contains(QStringLiteral("99.9")));
    QVERIFY(!keygen.versionList().contains(QStringLiteral("not-a-version")));
}

void TestMobaKeygen::remembersTypedVersion()
{
    MobaKeygen keygen;
    keygen.setUserName(QStringLiteral("roger"));
    keygen.setVersion(QStringLiteral("88.8"));

    QVERIFY(keygen.generateLicense());
    QVERIFY(keygen.versionList().contains(QStringLiteral("88.8")));

    QFile file(keygen.versionsFilePath());
    QVERIFY(file.open(QIODevice::ReadOnly | QIODevice::Text));
    QVERIFY(QString::fromUtf8(file.readAll()).contains(QStringLiteral("88.8")));
}

QTEST_GUILESS_MAIN(TestMobaKeygen)

#include "tst_mobakeygen.moc"
