#include "mxtprowriter.hpp"

#include <QDateTime>
#include <QDir>
#include <QFileInfo>
#include <QSaveFile>

namespace {

// Little-endian append helpers for the ZIP structures below.
void appendU16(QByteArray &out, quint16 value)
{
    out.append(static_cast<char>(value & 0xFF));
    out.append(static_cast<char>((value >> 8) & 0xFF));
}

void appendU32(QByteArray &out, quint32 value)
{
    out.append(static_cast<char>(value & 0xFF));
    out.append(static_cast<char>((value >> 8) & 0xFF));
    out.append(static_cast<char>((value >> 16) & 0xFF));
    out.append(static_cast<char>((value >> 24) & 0xFF));
}

struct Crc32Table
{
    quint32 entries[256];

    Crc32Table()
    {
        // Standard CRC-32 (reflected) polynomial 0xEDB88320.
        for (quint32 i = 0; i < 256; ++i) {
            quint32 value = i;
            for (int bit = 0; bit < 8; ++bit)
                value = (value & 1) ? (0xEDB88320u ^ (value >> 1)) : (value >> 1);
            entries[i] = value;
        }
    }
};

quint32 crc32(const QByteArray &data)
{
    static const Crc32Table table;

    quint32 crc = 0xFFFFFFFFu;
    for (const char ch : data) {
        crc = table.entries[(crc ^ static_cast<quint8>(ch)) & 0xFF] ^ (crc >> 8);
    }
    return crc ^ 0xFFFFFFFFu;
}

void dosDateTime(quint16 *time, quint16 *date)
{
    const QDateTime now = QDateTime::currentDateTime();
    const QDate day = now.date();
    if (!day.isValid() || day.year() < 1980) {
        *time = 0;
        *date = (1u << 5) | 1u; // 1980-01-01 00:00:00
        return;
    }

    const QTime clock = now.time();
    *time = static_cast<quint16>((clock.hour() << 11) | (clock.minute() << 5)
                                 | (clock.second() / 2));
    *date = static_cast<quint16>(((day.year() - 1980) << 9) | (day.month() << 5)
                                 | day.day());
}

// Builds a single-entry (STORE, no compression) ZIP archive in memory.
QByteArray buildZip(const QByteArray &payload)
{
    static const QByteArray fileName = QByteArrayLiteral("Pro.key");

    const quint32 dataSize = static_cast<quint32>(payload.size());
    const quint32 dataCrc = crc32(payload);
    quint16 dosTime = 0;
    quint16 dosDate = 0;
    dosDateTime(&dosTime, &dosDate);

    QByteArray zip;
    zip.reserve(payload.size() + 128);

    // Local file header, at offset 0.
    appendU32(zip, 0x04034b50u);           // local file header signature
    appendU16(zip, 20);                    // version needed to extract
    appendU16(zip, 0);                     // general purpose bit flag
    appendU16(zip, 0);                     // compression method: store
    appendU16(zip, dosTime);               // last mod file time
    appendU16(zip, dosDate);               // last mod file date
    appendU32(zip, dataCrc);               // crc-32
    appendU32(zip, dataSize);              // compressed size
    appendU32(zip, dataSize);              // uncompressed size
    appendU16(zip, static_cast<quint16>(fileName.size()));
    appendU16(zip, 0);                     // extra field length
    zip.append(fileName);
    zip.append(payload);

    const quint32 centralOffset = static_cast<quint32>(zip.size());

    // Central directory entry.
    appendU32(zip, 0x02014b50u);           // central file header signature
    appendU16(zip, 20);                    // version made by
    appendU16(zip, 20);                    // version needed to extract
    appendU16(zip, 0);                     // general purpose bit flag
    appendU16(zip, 0);                     // compression method: store
    appendU16(zip, dosTime);               // last mod file time
    appendU16(zip, dosDate);               // last mod file date
    appendU32(zip, dataCrc);               // crc-32
    appendU32(zip, dataSize);              // compressed size
    appendU32(zip, dataSize);              // uncompressed size
    appendU16(zip, static_cast<quint16>(fileName.size()));
    appendU16(zip, 0);                     // extra field length
    appendU16(zip, 0);                     // file comment length
    appendU16(zip, 0);                     // disk number start
    appendU16(zip, 0);                     // internal file attributes
    appendU32(zip, 0);                     // external file attributes
    appendU32(zip, 0);                     // relative offset of local header
    zip.append(fileName);

    const quint32 centralSize = static_cast<quint32>(zip.size()) - centralOffset;

    // End of central directory record.
    appendU32(zip, 0x06054b50u);           // end of central dir signature
    appendU16(zip, 0);                     // number of this disk
    appendU16(zip, 0);                     // disk with start of central dir
    appendU16(zip, 1);                     // entries on this disk
    appendU16(zip, 1);                     // total entries
    appendU32(zip, centralSize);           // size of central directory
    appendU32(zip, centralOffset);         // offset of central directory
    appendU16(zip, 0);                     // comment length

    return zip;
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

    if (static_cast<quint64>(licenseKey.size()) > 0xFFFFFFFFull)
        return fail(QStringLiteral("激活密钥过大"));

    const QByteArray zipData = buildZip(licenseKey);
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
