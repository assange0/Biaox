#include "filehasher.hpp"

#include <QClipboard>
#include <QCoreApplication>
#include <QCryptographicHash>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QGuiApplication>
#include <QLocale>
#include <QRegularExpression>
#include <QStringList>
#include <QtConcurrent>

#include <algorithm>

namespace {

constexpr qint64 kChunkSize = 1024 * 1024;

bool isHexString(const QString &value)
{
    if (value.isEmpty())
        return false;

    for (const QChar character : value) {
        const ushort code = character.unicode();
        const bool isHex = (code >= '0' && code <= '9')
            || (code >= 'a' && code <= 'f')
            || (code >= 'A' && code <= 'F');
        if (!isHex)
            return false;
    }

    return true;
}

QString algorithmForLength(int length)
{
    switch (length) {
    case 32:
        return QStringLiteral("MD5");
    case 40:
        return QStringLiteral("SHA-1");
    case 64:
        return QStringLiteral("SHA-256");
    default:
        return {};
    }
}

QString normalizedAlgorithm(const QString &token)
{
    QString compact = token.toUpper();
    compact.remove(QLatin1Char('-'));
    compact.remove(QLatin1Char(' '));
    if (compact == QLatin1String("MD5"))
        return QStringLiteral("MD5");
    if (compact == QLatin1String("SHA1"))
        return QStringLiteral("SHA-1");
    if (compact == QLatin1String("SHA256"))
        return QStringLiteral("SHA-256");
    return {};
}

// Accept hashes grouped with spaces or hyphens, for example
// "90015098 3cd24fb0 d6963f7d 28e17f72". Requiring equal-sized groups and
// rejecting 32-character groups keeps two whole hashes from being mistaken
// for one 64-character SHA-256 value.
QString groupedHashCandidate(const QString &input)
{
    const QStringList groups = input.split(
        QRegularExpression(QStringLiteral("[\\s-]+")), Qt::SkipEmptyParts);
    if (groups.size() < 2)
        return {};

    const int groupLength = groups.first().size();
    if (groupLength <= 0 || groupLength >= 32)
        return {};

    int totalLength = 0;
    for (const QString &group : groups) {
        if (group.size() != groupLength || !isHexString(group))
            return {};
        totalLength += groupLength;
    }

    if (totalLength != 32 && totalLength != 40 && totalLength != 64)
        return {};

    return groups.join(QString());
}

} // namespace

FileHasher::FileHasher(QObject *parent)
    : QObject(parent)
{
    connect(&m_watcher, &QFutureWatcher<HashResult>::finished,
            this, &FileHasher::handleComputeFinished);
}

FileHasher::~FileHasher()
{
    if (m_job)
        m_job->canceled.store(true, std::memory_order_relaxed);
    if (m_watcher.isRunning())
        m_watcher.waitForFinished();
}

QString FileHasher::filePath() const
{
    return m_filePath;
}

QString FileHasher::fileName() const
{
    return m_fileName;
}

qint64 FileHasher::fileSize() const
{
    return m_fileSize;
}

QString FileHasher::fileSizeText() const
{
    return m_fileSizeText;
}

bool FileHasher::hasFile() const
{
    return !m_filePath.isEmpty();
}

bool FileHasher::busy() const
{
    return m_busy;
}

bool FileHasher::hasResult() const
{
    return !m_md5.isEmpty() && !m_sha1.isEmpty() && !m_sha256.isEmpty();
}

QString FileHasher::md5() const
{
    return m_md5;
}

QString FileHasher::sha1() const
{
    return m_sha1;
}

QString FileHasher::sha256() const
{
    return m_sha256;
}

QString FileHasher::errorMessage() const
{
    return m_errorMessage;
}

QString FileHasher::expectedHash() const
{
    return m_expectedHash;
}

QString FileHasher::expectedAlgorithm() const
{
    return m_expectedAlgorithm;
}

QString FileHasher::expectedHashError() const
{
    return m_expectedHashError;
}

QString FileHasher::matchState() const
{
    return m_matchState;
}

QString FileHasher::matchedAlgorithm() const
{
    return m_matchedAlgorithm;
}

void FileHasher::setExpectedHash(const QString &expectedHash)
{
    if (m_expectedHash == expectedHash)
        return;

    m_expectedHash = expectedHash;
    emit expectedHashChanged();
    updateMatch();
}

bool FileHasher::setFile(const QUrl &url)
{
    if (m_busy) {
        setErrorMessage(tr("正在计算，请稍候"));
        return false;
    }

    if (!url.isLocalFile()) {
        setErrorMessage(tr("请选择一个本地文件"));
        return false;
    }

    const QFileInfo info(url.toLocalFile());
    if (!info.exists()) {
        setErrorMessage(tr("文件不存在"));
        return false;
    }
    if (!info.isFile()) {
        setErrorMessage(tr("请选择文件，而不是文件夹或设备文件"));
        return false;
    }
    if (!info.isReadable()) {
        setErrorMessage(tr("文件不可读"));
        return false;
    }

    m_filePath = QDir::toNativeSeparators(info.absoluteFilePath());
    m_fileName = info.fileName();
    m_fileSize = info.size();
    m_fileSizeText = QLocale::system().formattedDataSize(m_fileSize);

    setErrorMessage(QString());
    clearResults();
    updateMatch();
    emit fileChanged();
    return true;
}

bool FileHasher::canAcceptFile(const QUrl &url) const
{
    if (m_busy || !url.isLocalFile())
        return false;

    const QFileInfo info(url.toLocalFile());
    return info.exists() && info.isFile() && info.isReadable();
}

void FileHasher::compute()
{
    if (m_busy)
        return;

    if (!hasFile()) {
        setErrorMessage(tr("请先选择文件"));
        emit computeFinished(false);
        return;
    }

    const QFileInfo info(m_filePath);
    if (!info.exists() || !info.isFile()) {
        setErrorMessage(tr("文件不存在或已不是普通文件"));
        clearResults();
        updateMatch();
        emit computeFinished(false);
        return;
    }
    if (!info.isReadable()) {
        setErrorMessage(tr("文件不可读"));
        clearResults();
        updateMatch();
        emit computeFinished(false);
        return;
    }

    m_fileSize = info.size();
    m_fileSizeText = QLocale::system().formattedDataSize(m_fileSize);
    emit fileChanged();

    setErrorMessage(QString());
    clearResults();
    setBusy(true);
    updateMatch();

    m_job = std::make_shared<HashJob>();
    const QString path = info.absoluteFilePath();
    const std::shared_ptr<HashJob> job = m_job;
    m_watcher.setFuture(QtConcurrent::run([path, job] {
        return FileHasher::hashFileContents(path, job);
    }));
}

bool FileHasher::copyToClipboard(const QString &text) const
{
    if (text.isEmpty())
        return false;

    auto *app = qobject_cast<QGuiApplication *>(QCoreApplication::instance());
    if (!app)
        return false;

    QClipboard *clipboard = QGuiApplication::clipboard();
    if (!clipboard)
        return false;

    clipboard->setText(text);
    return true;
}

FileHasher::HashResult FileHasher::hashFileContents(
    const QString &path, const std::shared_ptr<HashJob> &job)
{
    HashResult result;

    QFile file(path);
    if (!file.open(QIODevice::ReadOnly)) {
        result.error = HashResult::OpenFailed;
        result.errorDetail = file.errorString();
        return result;
    }

    QCryptographicHash md5(QCryptographicHash::Md5);
    QCryptographicHash sha1(QCryptographicHash::Sha1);
    QCryptographicHash sha256(QCryptographicHash::Sha256);

    for (;;) {
        if (job->canceled.load(std::memory_order_relaxed)) {
            result.canceled = true;
            return result;
        }

        const QByteArray chunk = file.read(kChunkSize);
        if (chunk.isEmpty()) {
            if (file.error() != QFileDevice::NoError) {
                result.error = HashResult::ReadFailed;
                result.errorDetail = file.errorString();
            }
            break;
        }

        md5.addData(chunk);
        sha1.addData(chunk);
        sha256.addData(chunk);
    }

    result.md5 = md5.result();
    result.sha1 = sha1.result();
    result.sha256 = sha256.result();
    return result;
}

FileHasher::ParsedExpectedHash FileHasher::parseExpectedHash(const QString &input)
{
    ParsedExpectedHash result;

    static const QRegularExpression prefixPattern(
        QStringLiteral("^\\s*(MD5|SHA[- ]?1|SHA[- ]?256)\\s*[:=]\\s*"),
        QRegularExpression::CaseInsensitiveOption);

    QString remainder = input;
    QString declaredAlgorithm;
    const QRegularExpressionMatch prefixMatch = prefixPattern.match(input);
    if (prefixMatch.hasMatch()) {
        declaredAlgorithm = normalizedAlgorithm(prefixMatch.captured(1));
        remainder = input.mid(prefixMatch.capturedEnd());
    }
    remainder = remainder.trimmed();

    QStringList candidates;

    const QString grouped = groupedHashCandidate(remainder);
    if (!grouped.isEmpty()) {
        candidates.append(grouped);
    } else {
        static const QRegularExpression hashPattern(
            QStringLiteral("(?<![0-9A-Fa-f])[0-9A-Fa-f]{32,64}(?![0-9A-Fa-f])"));
        QRegularExpressionMatchIterator iterator = hashPattern.globalMatch(remainder);
        while (iterator.hasNext())
            candidates.append(iterator.next().captured(0));
    }

    if (candidates.isEmpty()) {
        result.error = tr("未找到有效的哈希值，需要 32、40 或 64 个十六进制字符");
        return result;
    }

    if (candidates.size() > 1) {
        result.error = tr("一次只支持粘贴一个哈希值");
        return result;
    }

    const QString candidate = candidates.first();
    const QString byLength = algorithmForLength(candidate.size());
    if (byLength.isEmpty()) {
        result.error = tr("无法识别哈希算法");
        return result;
    }

    if (!declaredAlgorithm.isEmpty() && declaredAlgorithm != byLength) {
        result.error = tr("前缀声明的算法与哈希长度不一致");
        return result;
    }

    result.valid = true;
    result.hash = candidate.toLower();
    result.algorithm = declaredAlgorithm.isEmpty() ? byLength : declaredAlgorithm;
    return result;
}

void FileHasher::setBusy(bool busy)
{
    if (m_busy == busy)
        return;

    m_busy = busy;
    emit busyChanged();
}

void FileHasher::setErrorMessage(const QString &message)
{
    if (m_errorMessage == message)
        return;

    m_errorMessage = message;
    emit errorMessageChanged();
}

void FileHasher::clearResults()
{
    if (m_md5.isEmpty() && m_sha1.isEmpty() && m_sha256.isEmpty())
        return;

    m_md5.clear();
    m_sha1.clear();
    m_sha256.clear();
    emit resultChanged();
}

void FileHasher::updateMatch()
{
    const QString trimmed = m_expectedHash.trimmed();
    ParsedExpectedHash parsed;
    if (!trimmed.isEmpty())
        parsed = parseExpectedHash(m_expectedHash);

    const QString algorithm = parsed.valid ? parsed.algorithm : QString();
    const QString error = (!trimmed.isEmpty() && !parsed.valid)
        ? parsed.error : QString();

    QString state;
    QString matched;

    if (trimmed.isEmpty()) {
        state = QStringLiteral("empty");
    } else if (!parsed.valid) {
        state = QStringLiteral("invalid");
    } else if (!hasResult()) {
        state = QStringLiteral("waiting");
    } else {
        QString actual;
        if (parsed.algorithm == QLatin1String("MD5"))
            actual = m_md5;
        else if (parsed.algorithm == QLatin1String("SHA-1"))
            actual = m_sha1;
        else if (parsed.algorithm == QLatin1String("SHA-256"))
            actual = m_sha256;

        if (actual.isEmpty()) {
            state = QStringLiteral("waiting");
        } else if (actual.compare(parsed.hash, Qt::CaseInsensitive) == 0) {
            state = QStringLiteral("match");
            matched = parsed.algorithm;
        } else {
            state = QStringLiteral("mismatch");
        }
    }

    const bool changed = m_expectedAlgorithm != algorithm
        || m_expectedHashError != error
        || m_matchState != state
        || m_matchedAlgorithm != matched;

    m_expectedAlgorithm = algorithm;
    m_expectedHashError = error;
    m_matchState = state;
    m_matchedAlgorithm = matched;

    if (changed)
        emit matchChanged();
}

void FileHasher::handleComputeFinished()
{
    if (!m_watcher.isFinished())
        return;

    const HashResult result = m_watcher.result();
    m_job.reset();
    setBusy(false);

    if (result.canceled)
        return;

    if (result.error != HashResult::NoError) {
        clearResults();
        if (result.error == HashResult::OpenFailed) {
            setErrorMessage(result.errorDetail.isEmpty()
                ? tr("无法打开文件")
                : tr("无法打开文件：%1").arg(result.errorDetail));
        } else {
            setErrorMessage(result.errorDetail.isEmpty()
                ? tr("读取文件失败")
                : tr("读取文件失败：%1").arg(result.errorDetail));
        }
        updateMatch();
        emit computeFinished(false);
        return;
    }

    m_md5 = QString::fromLatin1(result.md5.toHex());
    m_sha1 = QString::fromLatin1(result.sha1.toHex());
    m_sha256 = QString::fromLatin1(result.sha256.toHex());
    setErrorMessage(QString());
    emit resultChanged();
    updateMatch();
    emit computeFinished(true);
}
