#ifndef MOBAKEYGEN_HPP
#define MOBAKEYGEN_HPP

#include <QObject>
#include <QStringList>
#include <QUrl>
#include <qqml.h>

class MobaKeygen : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QString userName READ userName WRITE setUserName NOTIFY userNameChanged)
    Q_PROPERTY(QString version READ version WRITE setVersion NOTIFY versionChanged)
    Q_PROPERTY(QStringList versionList READ versionList NOTIFY versionListChanged)
    Q_PROPERTY(QString licenseKey READ licenseKey NOTIFY licenseKeyChanged)
    Q_PROPERTY(QString lastSavedPath READ lastSavedPath NOTIFY lastSavedPathChanged)
    Q_PROPERTY(QUrl defaultOutputUrl READ defaultOutputUrl CONSTANT)
    Q_PROPERTY(QString versionsFilePath READ versionsFilePath CONSTANT)
    Q_PROPERTY(QString versionsFilePathDisplay READ versionsFilePathDisplay CONSTANT)

public:
    explicit MobaKeygen(QObject *parent = nullptr);

    enum LicenseType { Professional = 1, Educational = 3, Personal = 4 };
    Q_ENUM(LicenseType)

    QString userName() const;
    QString version() const;
    QStringList versionList() const;
    QString licenseKey() const;
    QString lastSavedPath() const;
    QUrl defaultOutputUrl() const;
    QString versionsFilePath() const;
    QString versionsFilePathDisplay() const;

    void setUserName(const QString &userName);
    void setVersion(const QString &version);

    Q_INVOKABLE bool generateLicense();
    Q_INVOKABLE bool saveLicense(const QUrl &url);
    Q_INVOKABLE void reloadVersions();
    Q_INVOKABLE void openVersionsFile();
    Q_INVOKABLE void openContainingFolder();

signals:
    void userNameChanged();
    void versionChanged();
    void versionListChanged();
    void licenseKeyChanged();
    void lastSavedPathChanged();
    void errorOccurred(const QString &message);
    void licenseSaved(const QString &path);

private:
    static QByteArray encryptBytes(int key, const QByteArray &data);
    static QString variantBase64Encode(const QByteArray &data);

    void setLicenseKey(const QString &key);
    void setLastSavedPath(const QString &path);
    void loadVersions();
    bool rememberVersion(const QString &version);
    void ensureVersionsFile(const QByteArray &defaults);

    QString m_userName;
    QString m_version;
    QStringList m_versions;
    QString m_licenseKey;
    QString m_lastSavedPath;
    QString m_versionsFilePath;
    QUrl m_defaultOutputUrl;
    LicenseType m_type = LicenseType::Professional;
};

#endif // MOBAKEYGEN_HPP
