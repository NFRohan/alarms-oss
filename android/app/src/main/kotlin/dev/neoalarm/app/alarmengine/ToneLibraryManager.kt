package dev.neoalarm.app.alarmengine

import android.content.ContentResolver
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.util.UUID

class ToneLibraryManager(
    private val context: Context,
    private val store: ToneLibraryStore,
) {
    fun listToneMaps(): List<Map<String, Any?>> {
        return store.list().map { tone ->
            tone.toChannelMap(isHealthy = isHealthy(tone))
        }
    }

    fun importTone(uri: Uri): Map<String, Any?> {
        val contentResolver = context.contentResolver
        val mimeType = contentResolver.getType(uri)
            ?: throw ToneImportException("Unsupported file type. Select an MP3 or WAV tone.")
        if (mimeType !in SUPPORTED_MIME_TYPES) {
            throw ToneImportException("Unsupported file type. Select an MP3 or WAV tone.")
        }

        val metadata = queryMetadata(contentResolver, uri)
        if (metadata.sizeBytes <= 0) {
            throw ToneImportException("Unable to read the selected file.")
        }
        if (metadata.sizeBytes > MAX_IMPORT_BYTES) {
            throw ToneImportException("File too large. Please select a tone under 15 MB.")
        }

        tryTakePersistablePermission(uri)

        val fileExtension = extensionForMimeType(mimeType)
        val toneId = UUID.randomUUID().toString()
        val importedFileName = "$toneId.$fileExtension"
        val importedFile = store.resolveFile(importedFileName)

        val toneRecord = try {
            copyIntoManagedStorage(
                contentResolver = contentResolver,
                uri = uri,
                destinationPath = importedFile.absolutePath,
            )

            ToneRecord(
                id = toneId,
                displayName = metadata.displayName,
                sourceKind = ToneRecord.SOURCE_IMPORTED_COPY,
                localFileName = importedFileName,
                sourceUri = null,
                mimeType = mimeType,
                sizeBytes = metadata.sizeBytes,
                warning = null,
                createdAtEpochMillis = System.currentTimeMillis(),
            )
        } catch (error: IOException) {
            ToneRecord(
                id = toneId,
                displayName = metadata.displayName,
                sourceKind = ToneRecord.SOURCE_EXTERNAL_REFERENCE,
                localFileName = null,
                sourceUri = uri.toString(),
                mimeType = mimeType,
                sizeBytes = metadata.sizeBytes,
                warning = "Stored as a live file reference because the app could not copy it locally.",
                createdAtEpochMillis = System.currentTimeMillis(),
            )
        }

        store.upsert(toneRecord)
        return toneRecord.toChannelMap(isHealthy = isHealthy(toneRecord))
    }

    fun deleteTone(id: String): List<String> {
        store.delete(id) ?: return emptyList()
        return AlarmStore(context).getAll()
            .filter { it.customToneId == id }
            .map(AlarmRecord::id)
    }

    fun resolveToneUri(record: ToneRecord): Uri? {
        return when (record.sourceKind) {
            ToneRecord.SOURCE_IMPORTED_COPY -> {
                val fileName = record.localFileName ?: return null
                val file = store.resolveFile(fileName)
                if (!file.exists()) {
                    null
                } else {
                    Uri.fromFile(file)
                }
            }

            ToneRecord.SOURCE_EXTERNAL_REFERENCE -> {
                record.sourceUri?.let(Uri::parse)
            }

            else -> null
        }
    }

    fun isHealthy(record: ToneRecord): Boolean {
        return when (record.sourceKind) {
            ToneRecord.SOURCE_IMPORTED_COPY -> {
                val fileName = record.localFileName ?: return false
                store.resolveFile(fileName).exists()
            }

            ToneRecord.SOURCE_EXTERNAL_REFERENCE -> {
                val uri = record.sourceUri?.let(Uri::parse) ?: return false
                try {
                    context.contentResolver.openAssetFileDescriptor(uri, "r")?.close()
                    true
                } catch (_: Exception) {
                    false
                }
            }

            else -> false
        }
    }

    private fun copyIntoManagedStorage(
        contentResolver: ContentResolver,
        uri: Uri,
        destinationPath: String,
    ) {
        val destinationFile = File(destinationPath)
        try {
            contentResolver.openInputStream(uri)?.use { input ->
                FileOutputStream(destinationFile).use { output ->
                    input.copyTo(output)
                }
            } ?: throw IOException("Unable to open selected tone.")
        } catch (error: IOException) {
            destinationFile.delete()
            throw error
        } catch (error: RuntimeException) {
            destinationFile.delete()
            throw error
        }
    }

    private fun queryMetadata(contentResolver: ContentResolver, uri: Uri): ToneMetadata {
        contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE), null, null, null)
            ?.use { cursor ->
                val nameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                val sizeIndex = cursor.getColumnIndex(OpenableColumns.SIZE)
                if (cursor.moveToFirst()) {
                    val displayName = if (nameIndex >= 0) {
                        cursor.getString(nameIndex)
                    } else {
                        "Custom tone"
                    }
                    val sizeBytes = if (sizeIndex >= 0) {
                        cursor.getLong(sizeIndex)
                    } else {
                        0L
                    }
                    return ToneMetadata(displayName = displayName, sizeBytes = sizeBytes)
                }
            }

        return ToneMetadata(displayName = "Custom tone", sizeBytes = 0L)
    }

    private fun tryTakePersistablePermission(uri: Uri) {
        try {
            context.contentResolver.takePersistableUriPermission(
                uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION,
            )
        } catch (_: SecurityException) {
        } catch (_: UnsupportedOperationException) {
        }
    }

    private fun extensionForMimeType(mimeType: String): String {
        return when (mimeType) {
            "audio/mpeg" -> "mp3"
            "audio/x-wav",
            "audio/wav",
            -> "wav"

            else -> "bin"
        }
    }

    private data class ToneMetadata(
        val displayName: String,
        val sizeBytes: Long,
    )

    companion object {
        private const val MAX_IMPORT_BYTES = 15L * 1024L * 1024L
        private val SUPPORTED_MIME_TYPES = setOf(
            "audio/mpeg",
            "audio/x-wav",
            "audio/wav",
        )
    }
}

class ToneImportException(message: String) : IllegalStateException(message)
