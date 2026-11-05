#include <QtTest>

#include <QFile>
#include <QSignalSpy>
#include <QTemporaryDir>
#include <QUrl>

#include "filehasher.hpp"

namespace {

const QString kMd5 = QStringLiteral("900150983cd24fb0d6963f7d28e17f72");
const QString kSha1 = QStringLiteral("a9993e364706816aba3e25717850c26c9cd0d89d");
const QString kSha256 = QStringLiteral(
    "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad");

} // namespace

class TestFileHasher : public QObject
{
    Q_OBJECT

private slots:
    void initTestCase();

    void emptyFileHashes();
    void knownVectors();
    void rejectsInvalidFiles();
    void keepsPreviousSelectionOnFailure();
    void requiresFileBeforeCompute();
    void canAcceptFile();

    void expectedHashParsing_data();
    void expectedHashParsing();

    void matchesExpectedHash_data();
    void matchesExpectedHash();
    void reportsMismatch();

private:
    QString writeFile(const QString &name, const QByteArray &contents);
    bool computeAndWait(FileHasher &hasher);

    QTemporaryDir m_dir;
};

void TestFileHasher::initTestCase()
{
    QVERIFY(m_dir.isValid());
}

QString TestFileHasher::writeFile(const QString &name, const QByteArray &contents)
{
    const QString path = m_dir.filePath(name);
    QFile file(path);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate))
        return {};
    if (file.write(contents) != contents.size())
        return {};
    file.close();
    return path;
}

bool TestFileHasher::computeAndWait(FileHasher &hasher)
{
    QSignalSpy spy(&hasher, &FileHasher::computeFinished);
    hasher.compute();
    if (spy.isEmpty() && !spy.wait(10000))
        return false;
    return !spy.isEmpty();
}

void TestFileHasher::emptyFileHashes()
{
    const QString path = writeFile(QStringLiteral("empty.bin"), QByteArray());
    QVERIFY(!path.isEmpty());

    FileHasher hasher;
    QVERIFY(hasher.setFile(QUrl::fromLocalFile(path)));
    QCOMPARE(hasher.fileSize(), qint64(0));
    QVERIFY(computeAndWait(hasher));
    QVERIFY(!hasher.busy());
    QVERIFY(hasher.errorMessage().isEmpty());
    QVERIFY(hasher.hasResult());
    QCOMPARE(hasher.md5(), QStringLiteral("d41d8cd98f00b204e9800998ecf8427e"));
    QCOMPARE(hasher.sha1(), QStringLiteral("da39a3ee5e6b4b0d3255bfef95601890afd80709"));
    QCOMPARE(hasher.sha256(), QStringLiteral(
        "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"));
    QCOMPARE(hasher.matchState(), QStringLiteral("empty"));
}

void TestFileHasher::knownVectors()
{
    const QString path = writeFile(QStringLiteral("abc.bin"), QByteArrayLiteral("abc"));
    QVERIFY(!path.isEmpty());

    FileHasher hasher;
    QVERIFY(hasher.setFile(QUrl::fromLocalFile(path)));
    QCOMPARE(hasher.fileSize(), qint64(3));
    QVERIFY(computeAndWait(hasher));
    QVERIFY(!hasher.busy());
    QVERIFY(hasher.errorMessage().isEmpty());
    QVERIFY(hasher.hasResult());
    QCOMPARE(hasher.md5(), kMd5);
    QCOMPARE(hasher.sha1(), kSha1);
    QCOMPARE(hasher.sha256(), kSha256);
}

void TestFileHasher::rejectsInvalidFiles()
{
    FileHasher hasher;

    QVERIFY(!hasher.setFile(QUrl::fromLocalFile(m_dir.filePath(QStringLiteral("missing.bin")))));
    QVERIFY(!hasher.hasFile());
    QVERIFY(!hasher.errorMessage().isEmpty());

    QVERIFY(!hasher.setFile(QUrl::fromLocalFile(m_dir.path())));
    QVERIFY(!hasher.hasFile());
    QVERIFY(!hasher.errorMessage().isEmpty());

    QVERIFY(!hasher.setFile(QUrl(QStringLiteral("https://example.com/file.bin"))));
    QVERIFY(!hasher.hasFile());
    QVERIFY(!hasher.errorMessage().isEmpty());
}

void TestFileHasher::keepsPreviousSelectionOnFailure()
{
    const QString path = writeFile(QStringLiteral("keep.bin"), QByteArrayLiteral("abc"));
    QVERIFY(!path.isEmpty());

    FileHasher hasher;
    QVERIFY(hasher.setFile(QUrl::fromLocalFile(path)));
    QVERIFY(computeAndWait(hasher));
    QVERIFY(hasher.hasResult());

    const QString previousPath = hasher.filePath();
    const QString previousSha256 = hasher.sha256();

    QVERIFY(!hasher.setFile(QUrl::fromLocalFile(m_dir.filePath(QStringLiteral("missing.bin")))));
    QVERIFY(hasher.hasFile());
    QCOMPARE(hasher.filePath(), previousPath);
    QCOMPARE(hasher.sha256(), previousSha256);
    QVERIFY(!hasher.errorMessage().isEmpty());
}

void TestFileHasher::requiresFileBeforeCompute()
{
    FileHasher hasher;
    QSignalSpy spy(&hasher, &FileHasher::computeFinished);
    hasher.compute();

    QCOMPARE(spy.count(), 1);
    QCOMPARE(spy.first().at(0).toBool(), false);
    QVERIFY(!hasher.errorMessage().isEmpty());
    QVERIFY(!hasher.hasResult());
}

void TestFileHasher::canAcceptFile()
{
    const QString path = writeFile(QStringLiteral("accept.bin"), QByteArrayLiteral("abc"));
    QVERIFY(!path.isEmpty());

    FileHasher hasher;
    QVERIFY(hasher.canAcceptFile(QUrl::fromLocalFile(path)));
    QVERIFY(!hasher.canAcceptFile(QUrl::fromLocalFile(m_dir.filePath(QStringLiteral("missing.bin")))));
    QVERIFY(!hasher.canAcceptFile(QUrl::fromLocalFile(m_dir.path())));
    QVERIFY(!hasher.canAcceptFile(QUrl(QStringLiteral("https://example.com/file.bin"))));
}

void TestFileHasher::expectedHashParsing_data()
{
    QTest::addColumn<QString>("input");
    QTest::addColumn<QString>("state");
    QTest::addColumn<QString>("algorithm");
    QTest::addColumn<bool>("hasError");

    QTest::newRow("empty") << QString() << QStringLiteral("empty") << QString() << false;
    QTest::newRow("whitespace") << QStringLiteral("   ") << QStringLiteral("empty") << QString() << false;
    QTest::newRow("md5") << kMd5 << QStringLiteral("waiting") << QStringLiteral("MD5") << false;
    QTest::newRow("md5-uppercase") << kMd5.toUpper()
        << QStringLiteral("waiting") << QStringLiteral("MD5") << false;
    QTest::newRow("md5-prefix") << (QStringLiteral("MD5: ") + kMd5)
        << QStringLiteral("waiting") << QStringLiteral("MD5") << false;
    QTest::newRow("md5-grouped") << QStringLiteral("90015098 3cd24fb0 d6963f7d 28e17f72")
        << QStringLiteral("waiting") << QStringLiteral("MD5") << false;
    QTest::newRow("sha1") << kSha1 << QStringLiteral("waiting") << QStringLiteral("SHA-1") << false;
    QTest::newRow("sha1-prefix") << (QStringLiteral("SHA-1: ") + kSha1)
        << QStringLiteral("waiting") << QStringLiteral("SHA-1") << false;
    QTest::newRow("sha1-grouped")
        << QStringLiteral("a9993e36-4706816a-ba3e2571-7850c26c-9cd0d89d")
        << QStringLiteral("waiting") << QStringLiteral("SHA-1") << false;
    QTest::newRow("sha256") << kSha256
        << QStringLiteral("waiting") << QStringLiteral("SHA-256") << false;
    QTest::newRow("sha256-prefix") << (QStringLiteral("SHA256: ") + kSha256)
        << QStringLiteral("waiting") << QStringLiteral("SHA-256") << false;
    QTest::newRow("sha256-filename") << (kSha256 + QStringLiteral(" *file.iso"))
        << QStringLiteral("waiting") << QStringLiteral("SHA-256") << false;
    QTest::newRow("sha256-file-format")
        << (QStringLiteral("SHA256 (file.iso) = ") + kSha256)
        << QStringLiteral("waiting") << QStringLiteral("SHA-256") << false;
    QTest::newRow("sha256-grouped")
        << QStringLiteral("ba7816bf 8f01cfea 414140de 5dae2223 "
                          "b00361a3 96177a9c b410ff61 f20015ad")
        << QStringLiteral("waiting") << QStringLiteral("SHA-256") << false;
    QTest::newRow("invalid-length") << QStringLiteral("a").repeated(33)
        << QStringLiteral("invalid") << QString() << true;
    QTest::newRow("invalid-nonhex") << QStringLiteral("z").repeated(32)
        << QStringLiteral("invalid") << QString() << true;
    QTest::newRow("multiple") << (kMd5 + QLatin1Char(' ') + kSha1)
        << QStringLiteral("invalid") << QString() << true;
    QTest::newRow("prefix-mismatch") << (QStringLiteral("SHA256: ") + kSha1)
        << QStringLiteral("invalid") << QString() << true;
}

void TestFileHasher::expectedHashParsing()
{
    QFETCH(QString, input);
    QFETCH(QString, state);
    QFETCH(QString, algorithm);
    QFETCH(bool, hasError);

    FileHasher hasher;
    hasher.setExpectedHash(input);

    QCOMPARE(hasher.matchState(), state);
    QCOMPARE(hasher.expectedAlgorithm(), algorithm);
    QCOMPARE(!hasher.expectedHashError().isEmpty(), hasError);
}

void TestFileHasher::matchesExpectedHash_data()
{
    QTest::addColumn<QString>("expected");
    QTest::addColumn<QString>("algorithm");

    QTest::newRow("md5") << kMd5 << QStringLiteral("MD5");
    QTest::newRow("sha1") << kSha1 << QStringLiteral("SHA-1");
    QTest::newRow("sha256") << kSha256 << QStringLiteral("SHA-256");
    QTest::newRow("sha256-uppercase") << kSha256.toUpper() << QStringLiteral("SHA-256");
    QTest::newRow("sha256-prefix") << (QStringLiteral("SHA256: ") + kSha256)
        << QStringLiteral("SHA-256");
}

void TestFileHasher::matchesExpectedHash()
{
    QFETCH(QString, expected);
    QFETCH(QString, algorithm);

    const QString path = writeFile(QStringLiteral("match.bin"), QByteArrayLiteral("abc"));
    QVERIFY(!path.isEmpty());

    FileHasher hasher;
    QVERIFY(hasher.setFile(QUrl::fromLocalFile(path)));
    QVERIFY(computeAndWait(hasher));
    QVERIFY(hasher.hasResult());

    hasher.setExpectedHash(expected);
    QCOMPARE(hasher.matchState(), QStringLiteral("match"));
    QCOMPARE(hasher.matchedAlgorithm(), algorithm);
    QVERIFY(hasher.expectedHashError().isEmpty());
}

void TestFileHasher::reportsMismatch()
{
    const QString path = writeFile(QStringLiteral("mismatch.bin"), QByteArrayLiteral("abc"));
    QVERIFY(!path.isEmpty());

    FileHasher hasher;
    QVERIFY(hasher.setFile(QUrl::fromLocalFile(path)));
    QVERIFY(computeAndWait(hasher));

    hasher.setExpectedHash(QStringLiteral("0").repeated(64));
    QCOMPARE(hasher.matchState(), QStringLiteral("mismatch"));
    QCOMPARE(hasher.expectedAlgorithm(), QStringLiteral("SHA-256"));
    QVERIFY(hasher.matchedAlgorithm().isEmpty());
    QVERIFY(hasher.expectedHashError().isEmpty());

    hasher.setExpectedHash(QString());
    QCOMPARE(hasher.matchState(), QStringLiteral("empty"));
}

QTEST_GUILESS_MAIN(TestFileHasher)

#include "tst_filehasher.moc"
