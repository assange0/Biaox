#include "mobakeygen.hpp"

#include "mxtprowriter.hpp"

#include <QDesktopServices>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QRegularExpression>
#include <QSaveFile>
#include <QSet>
#include <QStandardPaths>
#include <QUrl>
#include <QtGlobal>

#include <algorithm>
#include <optional>

namespace {

constexpr int kLicenseKey = 0x787;

struct ParsedVersion
{
    int major = 0;
    int minor = 0;
};

std::optional<ParsedVersion> parseVersion(const QString &text)
{
    static const QRegularExpression pattern(
        QStringLiteral("^(\\d{1,4})\\.(\\d{1,4})$"));

    const QRegularExpressionMatch match = pattern.match(text.trimmed());
    if (!match.hasMatch())
        return std::nullopt;

    bool majorOk = false;
    bool minorOk = false;
    const int major = match.captured(1).toInt(&majorOk);
    const int minor = match.captured(2).toInt(&minorOk);
    if (!majorOk || !minorOk || major <= 0)
        return std::nullopt;

    return ParsedVersion{major, minor};
}

QString normalizedVersion(const ParsedVersion &version)
{
    return QStringLiteral("%1.%2").arg(version.major).arg(version.minor);
}

QStringList parseVersionContent(const QByteArray &content)
{
    QStringList result;
    QSet<QString> seen;

    const QStringList lines = QString::fromUtf8(content).split(QLatin1Char('\n'));
    for (QString line : lines) {
        if (line.startsWith(QChar(0xfeff)))
            line.remove(0, 1);
        line = line.trimmed();
        if (line.isEmpty() || line.startsWith(QLatin1Char('#')))
            continue;

        const auto parsed = parseVersion(line);
        if (!parsed)
            continue;

        const QString normalized = normalizedVersion(*parsed);
        if (seen.contains(normalized))
            continue;

        seen.insert(normalized);
        result.append(normalized);
    }

    return result;
}

void sortVersions(QStringList &versions)
{
    std::sort(versions.begin(), versions.end(),
              [](const QString &left, const QString &right) {
                  const auto leftVersion = parseVersion(left);
                  const auto rightVersion = parseVersion(right);
                  if (!leftVersion || !rightVersion)
                      return left < right;
                  if (leftVersion->major != rightVersion->major)
                      return leftVersion->major > rightVersion->major;
                  return leftVersion->minor > rightVersion->minor;
              });
}

QByteArray readAllFile(const QString &path)
{
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly))
        return {};
    return file.readAll();
}

bool isValidUserName(const QString &userName)
{
    if (userName.isEmpty())
        return false;

    for (const QChar character : userName) {
        if (character == QLatin1Char('#') || character == QLatin1Char('|'))
            return false;
        if (character.category() == QChar::Other_Control)
            return false;
    }

    return true;
}

QString appConfigDirectory()
{
    const QString override = qEnvironmentVariable("MOBAXKEYGEN_CONFIG_DIR");
    if (!override.isEmpty())
        return override;

    QString path = QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation);
    if (path.isEmpty())
        path = QDir::homePath() + QStringLiteral("/.mobaXterm-keygen");
    return path;
}

QUrl computeDefaultOutputUrl()
{
    QString directory = QStandardPaths::writableLocation(QStandardPaths::DownloadLocation);
    if (directory.isEmpty() || !QFileInfo(directory).isDir())
        directory = QStandardPaths::writableLocation(QStandardPaths::HomeLocation);
    if (directory.isEmpty())
        directory = QDir::currentPath();

    return QUrl::fromLocalFile(
        QDir(directory).filePath(QStringLiteral("Custom.mxtpro")));
}

} // namespace

MobaKeygen::MobaKeygen(QObject *parent)
    : QObject(parent)
    , m_versionsFilePath(
          QDir(appConfigDirectory()).filePath(QStringLiteral("versions.txt")))
    , m_defaultOutputUrl(computeDefaultOutputUrl())
{
    loadVersions();
}

QString MobaKeygen::userName() const
{
    return m_userName;
}

QString MobaKeygen::version() const
{
    return m_version;
}

QStringList MobaKeygen::versionList() const
{
    return m_versions;
}

QString MobaKeygen::licenseKey() const
{
    return m_licenseKey;
}

QString MobaKeygen::lastSavedPath() const
{
    return m_lastSavedPath;
}

QUrl MobaKeygen::defaultOutputUrl() const
{
    return m_defaultOutputUrl;
}

QString MobaKeygen::versionsFilePath() const
{
    return m_versionsFilePath;
}

QString MobaKeygen::versionsFilePathDisplay() const
{
    // UI 显示用：把用户主目录替换为 ~，避免在界面暴露绝对路径。
    const QString home = QDir::homePath();
    if (!home.isEmpty() && m_versionsFilePath.startsWith(home))
        return QLatin1Char('~') + m_versionsFilePath.mid(home.size());
    return m_versionsFilePath;
}

void MobaKeygen::setUserName(const QString &userName)
{
    if (m_userName == userName)
        return;

    m_userName = userName;
    emit userNameChanged();
}

void MobaKeygen::setVersion(const QString &version)
{
    if (m_version == version)
        return;

    m_version = version;
    emit versionChanged();
}

void MobaKeygen::setLicenseKey(const QString &key)
{
    if (m_licenseKey == key)
        return;

    m_licenseKey = key;
    emit licenseKeyChanged();
}

void MobaKeygen::setLastSavedPath(const QString &path)
{
    if (m_lastSavedPath == path)
        return;

    m_lastSavedPath = path;
    emit lastSavedPathChanged();
}

void MobaKeygen::loadVersions()
{
    const QByteArray defaults = readAllFile(QStringLiteral(":/resources/versions.txt"));
    ensureVersionsFile(defaults);

    QStringList versions = parseVersionContent(readAllFile(m_versionsFilePath));
    if (versions.isEmpty())
        versions = parseVersionContent(defaults);
    if (versions.isEmpty())
        versions = {QStringLiteral("26.6")};

    sortVersions(versions);

    const QStringList oldVersions = m_versions;
    const QString oldVersion = m_version;

    m_versions = versions;
    if (m_version.isEmpty()) {
        m_version = m_versions.first();
    } else {
        const auto parsed = parseVersion(m_version);
        m_version = parsed ? normalizedVersion(*parsed) : m_versions.first();
    }

    if (m_versions != oldVersions)
        emit versionListChanged();
    if (m_version != oldVersion)
        emit versionChanged();
}

void MobaKeygen::ensureVersionsFile(const QByteArray &defaults)
{
    if (m_versionsFilePath.isEmpty() || QFile::exists(m_versionsFilePath))
        return;

    const QFileInfo info(m_versionsFilePath);
    QDir().mkpath(info.absolutePath());

    QSaveFile file(m_versionsFilePath);
    if (!file.open(QIODevice::WriteOnly))
        return;

    file.write(defaults);
    file.commit();
}

bool MobaKeygen::rememberVersion(const QString &version)
{
    const auto parsed = parseVersion(version);
    if (!parsed)
        return false;

    const QString normalized = normalizedVersion(*parsed);
    if (m_versions.contains(normalized))
        return false;

    const QFileInfo info(m_versionsFilePath);
    if (!info.absolutePath().isEmpty())
        QDir().mkpath(info.absolutePath());

    QByteArray content = readAllFile(m_versionsFilePath);
    const QStringList existing = parseVersionContent(content);
    if (existing.isEmpty()) {
        QStringList all = m_versions;
        all.append(normalized);
        sortVersions(all);
        content.clear();
        for (const QString &entry : all)
            content += entry.toUtf8() + '\n';
    } else {
        if (!content.isEmpty() && !content.endsWith('\n'))
            content.append('\n');
        content += normalized.toUtf8();
        content += '\n';
    }

    QSaveFile file(m_versionsFilePath);
    if (file.open(QIODevice::WriteOnly)) {
        file.write(content);
        file.commit();
    }

    m_versions.append(normalized);
    sortVersions(m_versions);
    emit versionListChanged();
    return true;
}

bool MobaKeygen::generateLicense()
{
    setLicenseKey(QString());
    setLastSavedPath(QString());

    const QString name = m_userName.trimmed();
    if (name.isEmpty()) {
        emit errorOccurred(tr("请输入用户名"));
        return false;
    }
    if (!isValidUserName(name)) {
        emit errorOccurred(tr("用户名不能包含 #、| 或控制字符"));
        return false;
    }

    const auto parsedVersion = parseVersion(m_version);
    if (!parsedVersion) {
        emit errorOccurred(tr("版本号格式应为 主版本.次版本，例如 26.6"));
        return false;
    }

    const QString normalized = normalizedVersion(*parsedVersion);
    const QString major = QString::number(parsedVersion->major);
    const QString minor = QString::number(parsedVersion->minor);

    QString licenseString;
    licenseString.reserve(64 + name.size());
    licenseString += QString::number(static_cast<int>(m_type));
    licenseString += QLatin1Char('#');
    licenseString += name;
    licenseString += QLatin1Char('|');
    licenseString += major;
    licenseString += minor;
    licenseString += QLatin1Char('#');
    licenseString += QLatin1Char('1');
    licenseString += QLatin1Char('#');
    licenseString += major;
    licenseString += QLatin1Char('3');
    licenseString += minor;
    licenseString += QLatin1Char('6');
    licenseString += minor;
    licenseString += QStringLiteral("#0#0#0#");

    const QByteArray encrypted = encryptBytes(kLicenseKey, licenseString.toUtf8());
    const QString key = variantBase64Encode(encrypted);
    if (key.isEmpty()) {
        emit errorOccurred(tr("生成激活密钥失败"));
        return false;
    }

    setVersion(normalized);
    setLicenseKey(key);
    rememberVersion(normalized);
    return true;
}

bool MobaKeygen::saveLicense(const QUrl &url)
{
    if (m_licenseKey.isEmpty()) {
        emit errorOccurred(tr("请先生成激活密钥"));
        return false;
    }
    if (!url.isLocalFile()) {
        emit errorOccurred(tr("保存路径无效"));
        return false;
    }

    const QString localPath = url.toLocalFile();
    if (localPath.isEmpty()) {
        emit errorOccurred(tr("保存路径无效"));
        return false;
    }

    const QString path = QFileInfo(localPath).absoluteFilePath();
    QString error;
    if (!MxtproWriter::write(path, m_licenseKey.toUtf8(), &error)) {
        emit errorOccurred(error);
        return false;
    }

    setLastSavedPath(QDir::toNativeSeparators(path));
    emit licenseSaved(m_lastSavedPath);
    return true;
}

void MobaKeygen::reloadVersions()
{
    loadVersions();
}

void MobaKeygen::openVersionsFile()
{
    if (m_versionsFilePath.isEmpty()) {
        emit errorOccurred(tr("版本列表路径无效"));
        return;
    }

    if (!QFile::exists(m_versionsFilePath))
        ensureVersionsFile(readAllFile(QStringLiteral(":/resources/versions.txt")));

    if (!QFile::exists(m_versionsFilePath)) {
        emit errorOccurred(
            tr("无法创建版本列表文件：%1")
                .arg(QDir::toNativeSeparators(m_versionsFilePath)));
        return;
    }

    if (!QDesktopServices::openUrl(QUrl::fromLocalFile(m_versionsFilePath))) {
        emit errorOccurred(
            tr("无法打开版本列表文件：%1")
                .arg(QDir::toNativeSeparators(m_versionsFilePath)));
    }
}

void MobaKeygen::openContainingFolder()
{
    if (m_lastSavedPath.isEmpty()) {
        emit errorOccurred(tr("尚未保存激活文件"));
        return;
    }

    const QString directory = QFileInfo(m_lastSavedPath).absolutePath();
    if (!QDesktopServices::openUrl(QUrl::fromLocalFile(directory))) {
        emit errorOccurred(
            tr("无法打开文件夹：%1").arg(QDir::toNativeSeparators(directory)));
    }
}

QByteArray MobaKeygen::encryptBytes(int key, const QByteArray &data)
{
    QByteArray result;
    result.reserve(data.size());

    for (const char character : data) {
        const quint8 byte = static_cast<quint8>(character);
        const quint8 encrypted = static_cast<quint8>(byte ^ ((key >> 8) & 0xff));
        result.append(static_cast<char>(encrypted));
        key = (static_cast<int>(encrypted) & key) | 0x482d;
    }

    return result;
}

QString MobaKeygen::variantBase64Encode(const QByteArray &data)
{
    static constexpr char table[] =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";

    const qsizetype size = data.size();
    const qsizetype fullBlocks = size / 3;

    QString result;
    result.reserve(fullBlocks * 4 + 4);

    const auto *bytes = reinterpret_cast<const quint8 *>(data.constData());

    for (qsizetype i = 0; i < fullBlocks; ++i) {
        const quint32 value = static_cast<quint32>(bytes[3 * i])
            | (static_cast<quint32>(bytes[3 * i + 1]) << 8)
            | (static_cast<quint32>(bytes[3 * i + 2]) << 16);

        result += QLatin1Char(table[value & 0x3f]);
        result += QLatin1Char(table[(value >> 6) & 0x3f]);
        result += QLatin1Char(table[(value >> 12) & 0x3f]);
        result += QLatin1Char(table[(value >> 18) & 0x3f]);
    }

    const qsizetype remainder = size % 3;
    if (remainder == 1) {
        const quint32 value = static_cast<quint32>(bytes[fullBlocks * 3]);
        result += QLatin1Char(table[value & 0x3f]);
        result += QLatin1Char(table[(value >> 6) & 0x3f]);
    } else if (remainder == 2) {
        const quint32 value = static_cast<quint32>(bytes[fullBlocks * 3])
            | (static_cast<quint32>(bytes[fullBlocks * 3 + 1]) << 8);
        result += QLatin1Char(table[value & 0x3f]);
        result += QLatin1Char(table[(value >> 6) & 0x3f]);
        result += QLatin1Char(table[(value >> 12) & 0x3f]);
    }

    return result;
}
