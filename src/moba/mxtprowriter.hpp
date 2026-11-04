#ifndef MXTPROWRITER_HPP
#define MXTPROWRITER_HPP

#include <QByteArray>
#include <QString>

namespace MxtproWriter {

bool write(const QString &filePath, const QByteArray &licenseKey,
           QString *errorMessage);

} // namespace MxtproWriter

#endif // MXTPROWRITER_HPP
