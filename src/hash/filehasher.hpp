#ifndef FILEHASHER_HPP
#define FILEHASHER_HPP

#include <QByteArray>
#include <QFutureWatcher>
#include <QObject>
#include <QString>
#include <QUrl>
#include <qqml.h>

#include <atomic>
#include <memory>

// QML backend for the file hash / checksum page.
//
// Hashing runs on a worker thread so large files never block the GUI. The page
// intentionally exposes no progress or cancel UI; cancellation exists only to
// make page teardown safe.
class FileHasher : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QString filePath READ filePath NOTIFY fileChanged)
    Q_PROPERTY(QString fileName READ fileName NOTIFY fileChanged)
    Q_PROPERTY(qint64 fileSize READ fileSize NOTIFY fileChanged)
    Q_PROPERTY(QString fileSizeText READ fileSizeText NOTIFY fileChanged)
    Q_PROPERTY(bool hasFile READ hasFile NOTIFY fileChanged)
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(bool hasResult READ hasResult NOTIFY resultChanged)
    Q_PROPERTY(QString md5 READ md5 NOTIFY resultChanged)
    Q_PROPERTY(QString sha1 READ sha1 NOTIFY resultChanged)
    Q_PROPERTY(QString sha256 READ sha256 NOTIFY resultChanged)
    Q_PROPERTY(QString errorMessage READ errorMessage NOTIFY errorMessageChanged)
    Q_PROPERTY(QString expectedHash READ expectedHash WRITE setExpectedHash
                   NOTIFY expectedHashChanged)
    Q_PROPERTY(QString expectedAlgorithm READ expectedAlgorithm NOTIFY matchChanged)
    Q_PROPERTY(QString expectedHashError READ expectedHashError NOTIFY matchChanged)
    Q_PROPERTY(QString matchState READ matchState NOTIFY matchChanged)
    Q_PROPERTY(QString matchedAlgorithm READ matchedAlgorithm NOTIFY matchChanged)

public:
    explicit FileHasher(QObject *parent = nullptr);
    ~FileHasher() override;

    QString filePath() const;
    QString fileName() const;
    qint64 fileSize() const;
    QString fileSizeText() const;
    bool hasFile() const;
    bool busy() const;
    bool hasResult() const;
    QString md5() const;
    QString sha1() const;
    QString sha256() const;
    QString errorMessage() const;
    QString expectedHash() const;
    QString expectedAlgorithm() const;
    QString expectedHashError() const;
    QString matchState() const;
    QString matchedAlgorithm() const;

    void setExpectedHash(const QString &expectedHash);

    // Accepts a single local regular file. On failure the previous selection
    // (and its results) is kept; errorMessage() explains why.
    Q_INVOKABLE bool setFile(const QUrl &url);

    // Pure validation used by the DropArea for hover feedback.
    Q_INVOKABLE bool canAcceptFile(const QUrl &url) const;

    Q_INVOKABLE void compute();

    Q_INVOKABLE bool copyToClipboard(const QString &text) const;

signals:
    void fileChanged();
    void busyChanged();
    void resultChanged();
    void errorMessageChanged();
    void expectedHashChanged();
    void matchChanged();
    void computeFinished(bool success);

private:
    struct HashJob
    {
        std::atomic_bool canceled{false};
    };

    struct HashResult
    {
        enum Error {
            NoError,
            OpenFailed,
            ReadFailed,
        };

        Error error = NoError;
        QString errorDetail;
        bool canceled = false;
        QByteArray md5;
        QByteArray sha1;
        QByteArray sha256;
    };

    struct ParsedExpectedHash
    {
        bool valid = false;
        QString hash;
        QString algorithm;
        QString error;
    };

    static HashResult hashFileContents(const QString &path,
                                       const std::shared_ptr<HashJob> &job);
    static ParsedExpectedHash parseExpectedHash(const QString &input);

    void setBusy(bool busy);
    void setErrorMessage(const QString &message);
    void clearResults();
    void updateMatch();
    void handleComputeFinished();

    QString m_filePath;
    QString m_fileName;
    qint64 m_fileSize = 0;
    QString m_fileSizeText;
    QString m_md5;
    QString m_sha1;
    QString m_sha256;
    QString m_errorMessage;
    QString m_expectedHash;
    QString m_expectedAlgorithm;
    QString m_expectedHashError;
    QString m_matchState = QStringLiteral("empty");
    QString m_matchedAlgorithm;
    bool m_busy = false;

    std::shared_ptr<HashJob> m_job;
    QFutureWatcher<HashResult> m_watcher;
};

#endif // FILEHASHER_HPP
