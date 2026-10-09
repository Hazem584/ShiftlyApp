package com.example.shiftly

import android.Manifest
import android.content.ContentValues
import android.content.pm.PackageManager
import android.media.MediaScannerConnection
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val galleryWorker = Executors.newSingleThreadExecutor()
    private data class SaveRequest(val bytes: ByteArray, val mime: String, val name: String, val result: MethodChannel.Result)
    private var pendingSave: SaveRequest? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "shiftly/chat_gallery")
            .setMethodCallHandler { call, result ->
                if (call.method != "saveImage") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val bytes = call.argument<ByteArray>("bytes")
                val mime = call.argument<String>("mimeType")
                val name = call.argument<String>("name")
                if (bytes == null || bytes.isEmpty() || bytes.size > 5 * 1024 * 1024 ||
                    mime !in setOf("image/jpeg", "image/png", "image/webp") ||
                    name == null || !Regex("shiftly_[0-9]+\\.(jpg|png|webp)").matches(name)) {
                    result.error("INVALID_IMAGE", "Invalid image", null)
                    return@setMethodCallHandler
                }
                val request = SaveRequest(bytes, mime!!, name, result)
                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q &&
                    checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED) {
                    if (pendingSave != null) {
                        result.error("SAVE_BUSY", "A save is already pending", null)
                    } else {
                        pendingSave = request
                        requestPermissions(arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE), 8041)
                    }
                } else {
                    save(request)
                }
            }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != 8041) return
        val request = pendingSave ?: return
        pendingSave = null
        if (grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED) save(request)
        else request.result.error("PHOTO_PERMISSION_DENIED", "Photo access was denied", null)
    }

    private fun save(request: SaveRequest) {
        galleryWorker.execute {
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    val values = ContentValues().apply {
                        put(MediaStore.Images.Media.DISPLAY_NAME, request.name)
                        put(MediaStore.Images.Media.MIME_TYPE, request.mime)
                        put(MediaStore.Images.Media.RELATIVE_PATH, "${Environment.DIRECTORY_PICTURES}/Shiftly")
                        put(MediaStore.Images.Media.IS_PENDING, 1)
                    }
                    val uri = contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
                        ?: throw IllegalStateException("Could not create image")
                    try {
                        val stream = contentResolver.openOutputStream(uri)
                            ?: throw IllegalStateException("Could not open image")
                        stream.use { it.write(request.bytes) }
                        val published = contentResolver.update(uri, ContentValues().apply {
                            put(MediaStore.Images.Media.IS_PENDING, 0)
                        }, null, null)
                        if (published != 1) throw IllegalStateException("Could not publish image")
                    } catch (error: Exception) {
                        contentResolver.delete(uri, null, null)
                        throw error
                    }
                } else {
                    @Suppress("DEPRECATION")
                    val directory = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES), "Shiftly")
                    if (!directory.isDirectory && !directory.mkdirs()) throw IllegalStateException("Could not create folder")
                    val target = File(directory, request.name)
                    try {
                        target.outputStream().use { it.write(request.bytes) }
                        MediaScannerConnection.scanFile(this, arrayOf(target.absolutePath), arrayOf(request.mime), null)
                    } catch (error: Exception) {
                        target.delete()
                        throw error
                    }
                }
                runOnUiThread { request.result.success(true) }
            } catch (error: Exception) {
                runOnUiThread { request.result.error("PHOTO_SAVE_FAILED", "Could not save image", null) }
            }
        }
    }
}
