package com.example.project3

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.IOException

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.toktok.app/storage"
    private val TAG = "TokTok"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getAndroidVersion" -> {
                    Log.d(TAG, "Getting Android SDK version: ${Build.VERSION.SDK_INT}")
                    result.success(Build.VERSION.SDK_INT)
                }
                "moveToDownloads" -> {
                    try {
                        Log.d(TAG, "Starting moveToDownloads operation")
                        val sourcePath = call.argument<String>("sourcePath")
                        val fileName = call.argument<String>("fileName")
                        
                        if (sourcePath == null || fileName == null) {
                            Log.e(TAG, "Invalid arguments: sourcePath=$sourcePath, fileName=$fileName")
                            result.error("INVALID_ARGUMENTS", "Source path and file name are required", null)
                            return@setMethodCallHandler
                        }

                        Log.d(TAG, "Source path: $sourcePath")
                        Log.d(TAG, "File name: $fileName")

                        val sourceFile = File(sourcePath)
                        if (!sourceFile.exists()) {
                            Log.e(TAG, "Source file does not exist: $sourcePath")
                            result.error("FILE_NOT_FOUND", "Source file does not exist", null)
                            return@setMethodCallHandler
                        }

                        Log.d(TAG, "Android SDK version: ${Build.VERSION.SDK_INT}")
                        val success = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                            Log.d(TAG, "Using MediaStore API (Android 10+)")
                            // Use MediaStore for Android 10 and above
                            val contentValues = ContentValues().apply {
                                put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                                put(MediaStore.MediaColumns.MIME_TYPE, "video/mp4")
                                put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
                            }

                            val resolver = context.contentResolver
                            val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues)
                            
                            uri?.let { 
                                Log.d(TAG, "MediaStore URI created: $it")
                                resolver.openOutputStream(it)?.use { outputStream ->
                                    FileInputStream(sourceFile).use { inputStream ->
                                        inputStream.copyTo(outputStream)
                                        Log.d(TAG, "File copied successfully")
                                    }
                                }
                                true
                            } ?: run {
                                Log.e(TAG, "Failed to create MediaStore entry")
                                false
                            }
                        } else {
                            Log.d(TAG, "Using legacy storage API")
                            // Legacy approach for older Android versions
                            val destination = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS), fileName)
                            Log.d(TAG, "Destination path: ${destination.absolutePath}")
                            sourceFile.copyTo(destination, overwrite = true)
                            Log.d(TAG, "File copied successfully")
                            true
                        }

                        // Clean up the source file
                        if (sourceFile.exists()) {
                            sourceFile.delete()
                            Log.d(TAG, "Source file cleaned up")
                        }
                        
                        Log.d(TAG, "Operation completed with success=$success")
                        result.success(success)
                    } catch (e: IOException) {
                        Log.e(TAG, "Failed to save file", e)
                        result.error("SAVE_FAILED", "Failed to save file: ${e.message}", e.stackTraceToString())
                    } catch (e: Exception) {
                        Log.e(TAG, "Unexpected error", e)
                        result.error("UNEXPECTED_ERROR", "An unexpected error occurred: ${e.message}", e.stackTraceToString())
                    }
                }
                else -> {
                    Log.w(TAG, "Method not implemented: ${call.method}")
                    result.notImplemented()
                }
            }
        }
    }
}

