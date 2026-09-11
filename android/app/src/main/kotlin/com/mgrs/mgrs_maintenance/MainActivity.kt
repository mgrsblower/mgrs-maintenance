package com.mgrs.mgrs_maintenance

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Environment
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Native PDF Channel per spec (mgrs/native_pdf)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            NATIVE_PDF_CHANNEL,
        ).setMethodCallHandler { call, result ->
            handleNativePdfCall(call, result)
        }

        // Legacy invoice PDF channel for saving / compatibility
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            INVOICE_PDF_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "openInvoicePdf" -> {
                    val location = call.argument<String>("location")
                    handlePreviewPdf(location, result)
                }
                "shareInvoicePdf" -> {
                    val location = call.argument<String>("location")
                    val fileName = call.argument<String>("fileName")
                    handleSharePdf(location, fileName, result)
                }
                "saveInvoicePdf" -> {
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
                else -> result.notImplemented()
            }
        }
    }

    private fun handleNativePdfCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "previewPdf" -> {
                val path = call.argument<String>("path")
                handlePreviewPdf(path, result)
            }
            "sharePdf" -> {
                val path = call.argument<String>("path")
                val title = call.argument<String>("title")
                handleSharePdf(path, title, result)
            }
            else -> result.notImplemented()
        }
    }

    private fun handlePreviewPdf(path: String?, result: MethodChannel.Result) {
        if (path.isNullOrBlank()) {
            result.error("EMPTY_PATH", "Path file PDF tidak boleh kosong.", null)
            return
        }

        val file = File(path)
        if (!file.exists()) {
            result.error("FILE_NOT_FOUND", "File PDF tidak ditemukan: $path", null)
            return
        }

        if (!file.name.endsWith(".pdf", ignoreCase = true)) {
            result.error("NOT_A_PDF", "Format file bukan dokumen PDF yang valid.", null)
            return
        }

        val uri: Uri = try {
            FileProvider.getUriForFile(
                applicationContext,
                "${applicationContext.packageName}.fileprovider",
                file,
            )
        } catch (e: Exception) {
            result.error("URI_ERROR", "Gagal membuat Content URI dari FileProvider: ${e.message}", e.message)
            return
        }

        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "application/pdf")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        try {
            startActivity(intent)
            result.success(null)
        } catch (e: ActivityNotFoundException) {
            result.error("NO_PDF_APP", "Tidak ada aplikasi untuk membuka file PDF.", e.message)
        } catch (e: Exception) {
            result.error("PREVIEW_FAILED", "Gagal membuka pratinjau PDF: ${e.message}", e.message)
        }
    }

    private fun handleSharePdf(path: String?, title: String?, result: MethodChannel.Result) {
        if (path.isNullOrBlank()) {
            result.error("EMPTY_PATH", "Path file PDF tidak boleh kosong.", null)
            return
        }

        val file = File(path)
        if (!file.exists()) {
            result.error("FILE_NOT_FOUND", "File PDF tidak ditemukan: $path", null)
            return
        }

        if (!file.name.endsWith(".pdf", ignoreCase = true)) {
            result.error("NOT_A_PDF", "Format file bukan dokumen PDF yang valid.", null)
            return
        }

        val uri: Uri = try {
            FileProvider.getUriForFile(
                applicationContext,
                "${applicationContext.packageName}.fileprovider",
                file,
            )
        } catch (e: Exception) {
            result.error("URI_ERROR", "Gagal membuat Content URI dari FileProvider: ${e.message}", e.message)
            return
        }

        val shareIntent = Intent(Intent.ACTION_SEND).apply {
            type = "application/pdf"
            putExtra(Intent.EXTRA_STREAM, uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            if (!title.isNullOrBlank()) {
                putExtra(Intent.EXTRA_SUBJECT, title)
            }
        }

        val chooser = Intent.createChooser(shareIntent, title ?: "Bagikan PDF").apply {
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        try {
            startActivity(chooser)
            result.success(null)
        } catch (e: Exception) {
            result.error("SHARE_FAILED", "Gagal membagikan file PDF: ${e.message}", e.message)
        }
    }

    private fun saveInvoicePdf(bytes: ByteArray, fileName: String): String {
        val baseDir = getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS) ?: filesDir
        val directory = File(baseDir, "MGRS").apply { mkdirs() }
        val file = File(directory, fileName)
        file.writeBytes(bytes)
        return file.absolutePath
    }

    private companion object {
        const val NATIVE_PDF_CHANNEL = "mgrs/native_pdf"
        const val INVOICE_PDF_CHANNEL = "com.mgrs.mgrs_maintenance/invoice_pdf"
    }
}
