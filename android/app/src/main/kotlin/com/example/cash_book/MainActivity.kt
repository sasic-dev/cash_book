package com.example.cash_book

import android.app.Activity
import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.provider.OpenableColumns
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.cash_book/pdf_export"
    private val RC_CREATE_DOCUMENT = 1001

    private var pendingPdfBytes: ByteArray? = null
    private var pendingFileName: String? = null
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "savePdfWithLocationPicker" -> {
                    val bytes = call.argument<ByteArray>("bytes")
                    val fileName = call.argument<String>("fileName") ?: "cash_book_report.pdf"

                    if (bytes == null) {
                        result.error("INVALID_ARGS", "Bytes cannot be null", null)
                        return@setMethodCallHandler
                    }

                    pendingPdfBytes = bytes
                    pendingFileName = fileName
                    pendingResult = result

                    try {
                        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = "application/pdf"
                            putExtra(Intent.EXTRA_TITLE, fileName)
                        }
                        startActivityForResult(intent, RC_CREATE_DOCUMENT)
                    } catch (e: Exception) {
                        pendingPdfBytes = null
                        pendingFileName = null
                        pendingResult = null
                        result.error("PICKER_ERROR", e.localizedMessage, null)
                    }
                }
                "saveToDownloads" -> {
                    val bytes = call.argument<ByteArray>("bytes")
                    val fileName = call.argument<String>("fileName") ?: "cash_book_report.pdf"

                    if (bytes == null) {
                        result.error("INVALID_ARGS", "Bytes cannot be null", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val savedInfo = savePdfToDownloads(bytes, fileName)
                        result.success(savedInfo)
                    } catch (e: Exception) {
                        result.error("SAVE_FAILED", e.localizedMessage, null)
                    }
                }
                "openPdf" -> {
                    val uriString = call.argument<String>("uri")
                    val filePath = call.argument<String>("filePath")

                    try {
                        openPdfFile(uriString, filePath)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("OPEN_FAILED", e.localizedMessage, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == RC_CREATE_DOCUMENT) {
            val resultCallback = pendingResult
            val bytes = pendingPdfBytes
            val defaultName = pendingFileName ?: "cash_book_report.pdf"

            pendingResult = null
            pendingPdfBytes = null
            pendingFileName = null

            if (resultCallback == null) return

            if (resultCode == Activity.RESULT_OK && data?.data != null) {
                val uri = data.data!!
                try {
                    contentResolver.openOutputStream(uri)?.use { output ->
                        if (bytes != null) {
                            output.write(bytes)
                            output.flush()
                        }
                    }

                    val resolvedName = queryName(uri) ?: defaultName

                    resultCallback.success(mapOf(
                        "success" to true,
                        "uri" to uri.toString(),
                        "fileName" to resolvedName,
                        "userCancelled" to false
                    ))
                } catch (e: Exception) {
                    resultCallback.error("WRITE_ERROR", e.localizedMessage, null)
                }
            } else {
                resultCallback.success(mapOf(
                    "success" to false,
                    "userCancelled" to true
                ))
            }
        }
    }

    private fun queryName(uri: Uri): String? {
        var name: String? = null
        try {
            contentResolver.query(uri, null, null, null, null)?.use { cursor ->
                val nameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                if (nameIndex != -1 && cursor.moveToFirst()) {
                    name = cursor.getString(nameIndex)
                }
            }
        } catch (_: Exception) {}
        return name
    }

    private fun savePdfToDownloads(bytes: ByteArray, fileName: String): Map<String, Any?> {
        val resolver = applicationContext.contentResolver

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val contentValues = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                put(MediaStore.MediaColumns.MIME_TYPE, "application/pdf")
                put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }

            val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues)
                ?: throw IllegalStateException("Failed to create MediaStore entry in Downloads")

            resolver.openOutputStream(uri)?.use { output ->
                output.write(bytes)
                output.flush()
            }

            contentValues.clear()
            contentValues.put(MediaStore.MediaColumns.IS_PENDING, 0)
            resolver.update(uri, contentValues, null, null)

            val publicPath = "${Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS).path}/$fileName"

            return mapOf(
                "success" to true,
                "uri" to uri.toString(),
                "filePath" to publicPath,
                "fileName" to fileName
            )
        } else {
            val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
            if (!downloadsDir.exists()) {
                downloadsDir.mkdirs()
            }
            val file = File(downloadsDir, fileName)
            FileOutputStream(file).use { output ->
                output.write(bytes)
                output.flush()
            }

            val uri = Uri.fromFile(file)
            return mapOf(
                "success" to true,
                "uri" to uri.toString(),
                "filePath" to file.absolutePath,
                "fileName" to fileName
            )
        }
    }

    private fun openPdfFile(uriString: String?, filePath: String?) {
        val uri: Uri = if (!uriString.isNullOrEmpty()) {
            Uri.parse(uriString)
        } else if (!filePath.isNullOrEmpty()) {
            val file = File(filePath)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                FileProvider.getUriForFile(
                    applicationContext,
                    "${applicationContext.packageName}.fileprovider",
                    file
                )
            } else {
                Uri.fromFile(file)
            }
        } else {
            throw IllegalArgumentException("Both URI and file path are empty")
        }

        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "application/pdf")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        val chooser = Intent.createChooser(intent, "Open PDF Statement").apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(chooser)
    }
}
