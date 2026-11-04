#include "mxtprowriter.hpp"

#include <QtCore/private/qzipwriter_p.h>

#include <QBuffer>
#include <QDir>
#include <QFileInfo>
#include <QSaveFile>
#include <QStringLiteral>

namespace {

QString zipStatusText(QZipWriter::Status status)
{
    switch (status) {
    case QZipWriter::NoError:
        return QStringLiteral("无错误");
    case QZipWriter::FileWriteError:
        return QStringLiteral("写入 ZIP 数据失败");
    case QZipWriter::FileOpenError:
        return QStringLiteral("无法创建 ZIP 文件");
    case QZipWriter::FilePermissionsError:
        return QStringLiteral("文件权限不足");
    case QZipWriter::FileError:
        return QStringLiteral("ZIP 文件读写错误");
    }

    return QStringLiteral("未知 ZIP 错误");
}

} // namespace

namespace MxtproWriter {

bool write(const QString &filePath, const QByteArray &licenseKey,
           QString *errorMessage)
{
    const auto fail = [errorMessage](const QString &message) {
        if (errorMessage)
            *errorMessage = message;
        return false;
    };

    if (filePath.isEmpty())
        return fail(QStringLiteral("保存路径为空"));
    if (licenseKey.isEmpty())
        return fail(QStringLiteral("激活密钥为空"));

    const QFileInfo fileInfo(filePath);
    if (!fileInfo.absoluteDir().exists()) {
        return fail(QStringLiteral("保存目录不存在：%1")
                        .arg(QDir::toNativeSeparators(fileInfo.absolutePath())));
    }

    QByteArray zipData;
    QBuffer buffer(&zipData);
    if (!buffer.open(QIODevice::WriteOnly))
        return fail(QStringLiteral("无法创建内存 ZIP 缓冲区"));

    {
        QZipWriter zip(&buffer);
        zip.setCompressionPolicy(QZipWriter::NeverCompress);
        zip.addFile(QStringLiteral("Pro.key"), licenseKey);
        zip.close();

        if (zip.status() != QZipWriter::NoError)
            return fail(zipStatusText(zip.status()));
    }

    if (zipData.isEmpty())
        return fail(QStringLiteral("生成的 ZIP 数据为空"));

    QSaveFile file(filePath);
    if (!file.open(QIODevice::WriteOnly)) {
        return fail(QStringLiteral("无法写入 %1：%2")
                        .arg(QDir::toNativeSeparators(filePath),
                             file.errorString()));
    }

    if (file.write(zipData) != zipData.size()) {
        file.cancelWriting();
        return fail(QStringLiteral("写入 %1 失败：%2")
                        .arg(QDir::toNativeSeparators(filePath),
                             file.errorString()));
    }

    if (!file.commit()) {
        return fail(QStringLiteral("保存 %1 失败：%2")
                        .arg(QDir::toNativeSeparators(filePath),
                             file.errorString()));
    }

    return true;
}

} // namespace MxtproWriter
