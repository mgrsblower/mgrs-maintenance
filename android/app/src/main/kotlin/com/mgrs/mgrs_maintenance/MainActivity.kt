package com.mgrs.mgrs_maintenance

import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            INVOICE_PDF_CHANNEL,
        ).setMethodCallHandler { call, result ->
            if (call.method == "openInvoicePdf") {
                try {
                    openInvoicePdf(call.argument<String>("location"))
                    result.success(null)
                } catch (error: Exception) {
                    result.error("open_failed", "PDF invoice tidak dapat dibuka.", error.message)
                }
                return@setMethodCallHandler
            }

            if (call.method == "shareInvoicePdf") {
                try {
                    shareInvoicePdf(call.argument<String>("location"))
                    result.success(null)
                } catch (error: Exception) {
                    result.error("share_failed", "PDF invoice tidak dapat dibagikan.", error.message)
                }
                return@setMethodCallHandler
            }

            if (call.method != "saveInvoicePdf") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val bytes = call.argument<ByteArray>("bytes")
            val fileName = call.argument<String>("fileName")
            if (bytes == null || fileName.isNullOrBlank()) {
                result.error("invalid_arguments", "PDF bytes atau nama file tidak valid.", null)
                return@setMethodCallHandler
            }

            try {
                result.success(saveInvoicePdf(bytes, fileName))
            } catch (error: Exception) {
                result.error("save_failed", "PDF invoice tidak dapat disimpan.", error.message)
            }
        }
    }

    private fun saveInvoicePdf(bytes: ByteArray, fileName: String): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                put(MediaStore.MediaColumns.MIME_TYPE, "application/pdf")
                put(
                    MediaStore.MediaColumns.RELATIVE_PATH,
                    "${Environment.DIRECTORY_DOWNLOADS}/MGRS",
                )
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }
            val resolver = applicationContext.contentResolver
            val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                ?: error("Tidak dapat membuat file PDF di Downloads.")
            try {
                resolver.openOutputStream(uri)?.use { it.write(bytes) }
                    ?: error("Tidak dapat membuka file PDF di Downloads.")
                values.clear()
                values.put(MediaStore.MediaColumns.IS_PENDING, 0)
                resolver.update(uri, values, null, null)
                return uri.toString()
            } catch (error: Exception) {
                resolver.delete(uri, null, null)
                throw error
            }
        }

        val downloads = getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS)
            ?: error("Folder Downloads tidak tersedia.")
        val directory = File(downloads, "MGRS").apply { mkdirs() }
        return File(directory, fileName).apply { writeBytes(bytes) }.absolutePath
    }

    private fun openInvoicePdf(location: String?) {
        val uri = location?.let(Uri::parse) ?: error("Lokasi PDF tidak valid.")
        startActivity(Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "application/pdf")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        })
    }

    private fun shareInvoicePdf(location: String?) {
        val uri = location?.let(Uri::parse) ?: error("Lokasi PDF tidak valid.")
        startActivity(Intent.createChooser(Intent(Intent.ACTION_SEND).apply {
            type = "application/pdf"
            putExtra(Intent.EXTRA_STREAM, uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }, "Bagikan PDF invoice"))
    }

    private companion object {
        const val INVOICE_PDF_CHANNEL = "com.mgrs.mgrs_maintenance/invoice_pdf"
    }
}
