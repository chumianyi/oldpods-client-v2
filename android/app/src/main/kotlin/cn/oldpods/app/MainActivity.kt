package cn.oldpods.app

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.DisplayMetrics
import android.util.Log
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {

    private val channelName = "cn.oldpods.app/device"
    private var pendingBrowser: MethodChannel.Result? = null
    private val downloads by lazy { NativeDownloads(this) }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openDownloadBrowser" -> {
                        if (pendingBrowser != null) {
                            result.error("BUSY", "下载网页已打开", null)
                        } else {
                            pendingBrowser = result
                            try {
                                startActivityForResult(Intent(this, DownloadBrowserActivity::class.java).apply {
                                    for (key in listOf("url", "cookie", "apiKey", "userAgent", "appTitle")) {
                                        putExtra(key, call.argument<String>(key))
                                    }
                                    putExtra("dark", call.argument<Boolean>("dark") ?: false)
                                }, REQUEST_BROWSER)
                            } catch (e: Exception) {
                                pendingBrowser = null
                                result.error("BROWSER_FAILED", e.message, null)
                            }
                        }
                    }
                    "enqueueDownload" -> try {
                        result.success(downloads.enqueue(call.arguments as Map<*, *>))
                    } catch (e: Exception) { result.error("DOWNLOAD_FAILED", e.message, null) }
                    "listDownloads" -> try {
                        result.success(downloads.list())
                    } catch (e: Exception) { result.error("DOWNLOAD_QUERY_FAILED", e.message, null) }
                    "cancelDownload" -> {
                        downloads.cancel((call.argument<Number>("id") ?: 0).toLong())
                        result.success(true)
                    }
                    "forgetDownload" -> {
                        downloads.forget((call.argument<Number>("id") ?: 0).toLong(), call.argument<Boolean>("deleteFile") ?: false)
                        result.success(true)
                    }
                    "clearWebSession" -> {
                        android.webkit.CookieManager.getInstance().removeAllCookies { result.success(true) }
                        android.webkit.CookieManager.getInstance().flush()
                    }
                    "getDeviceInfo" -> result.success(buildDeviceInfo())
                    "getVersionInfo" -> result.success(buildVersionInfo())
                    "getDownloadDir" -> result.success(downloadDir())
                    "openApk" -> {
                        val path = call.argument<String>("path")
                        if (path.isNullOrEmpty()) {
                            result.error("BAD_ARGS", "path is required", null)
                        } else if (openApk(path)) {
                            result.success(true)
                        } else {
                            result.error("OPEN_FAILED", "cannot open apk", null)
                        }
                    }
                    "openUrl" -> {
                        val url = call.argument<String>("url")
                        if (url.isNullOrEmpty()) {
                            result.error("BAD_ARGS", "url is required", null)
                        } else if (openUrl(url)) {
                            result.success(true)
                        } else {
                            result.error("OPEN_FAILED", "cannot open url", null)
                        }
                    }
                    "pickImage" -> {
                        pickImage { path ->
                            if (path != null) result.success(path) else result.error("CANCELED", "user canceled", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun buildDeviceInfo(): Map<String, Any> {
        val metrics: DisplayMetrics = resources.displayMetrics
        val screen = "${metrics.widthPixels}x${metrics.heightPixels}"
        val abis: List<String> = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            Build.SUPPORTED_ABIS?.toList() ?: emptyList()
        } else {
            listOf(Build.CPU_ABI, Build.CPU_ABI2).filter { it.isNotEmpty() }
        }
        return mapOf(
            "manufacturer" to (Build.MANUFACTURER ?: ""),
            "brand" to (Build.BRAND ?: ""),
            "model" to (Build.MODEL ?: ""),
            "device" to (Build.DEVICE ?: ""),
            "display_id" to (Build.DISPLAY ?: ""),
            "hardware" to (Build.HARDWARE ?: ""),
            "abis" to abis,
            "android_version" to (Build.VERSION.RELEASE ?: ""),
            "sdk_int" to Build.VERSION.SDK_INT,
            "screen" to screen,
            "density" to metrics.densityDpi
        )
    }

    private fun buildVersionInfo(): Map<String, Any> {
        return try {
            val info = packageManager.getPackageInfo(packageName, 0)
            mapOf(
                "versionName" to (info.versionName ?: "1.0.0"),
                "versionCode" to (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) info.longVersionCode.toInt() else info.versionCode)
            )
        } catch (e: Exception) {
            mapOf("versionName" to "1.0.0", "versionCode" to 1)
        }
    }

    private fun downloadDir(): String {
        val dir = getExternalFilesDir(null)
        return dir?.absolutePath ?: filesDir.absolutePath
    }

    private fun openApk(path: String): Boolean {
        return try {
            val file = File(path)
            if (!file.exists()) return false
            val uri = FileProvider.getUriForFile(this, "$packageName.fileprovider", file)
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, "application/vnd.android.package-archive")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                if (!packageManager.canRequestPackageInstalls()) {
                    val settingsIntent = Intent(
                        Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                        Uri.parse("package:$packageName")
                    ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(settingsIntent)
                    return true
                }
            }
            startActivity(intent)
            true
        } catch (e: Exception) {
            Log.e("OldPods", "openApk failed", e)
            false
        }
    }

    private fun openUrl(url: String): Boolean {
        return try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
            true
        } catch (e: Exception) {
            Log.e("OldPods", "openUrl failed", e)
            false
        }
    }

    private fun pickImage(callback: (String?) -> Unit) {
        val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
            type = "image/*"
            addCategory(Intent.CATEGORY_OPENABLE)
        }
        try {
            startActivityForResult(intent, REQUEST_PICK_IMAGE)
            pendingPickCallback = callback
        } catch (e: Exception) {
            callback(null)
        }
    }

    private var pendingPickCallback: ((String?) -> Unit)? = null

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_BROWSER) {
            val callback = pendingBrowser
            pendingBrowser = null
            if (resultCode == RESULT_OK && data != null) {
                callback?.success(mapOf(
                    "url" to data.getStringExtra("url"),
                    "fileName" to data.getStringExtra("fileName"),
                    "mime" to data.getStringExtra("mime"),
                    "cookie" to data.getStringExtra("cookie"),
                    "userAgent" to data.getStringExtra("userAgent"),
                    "referer" to data.getStringExtra("referer"),
                    "sourceUrl" to data.getStringExtra("sourceUrl"),
                    "total" to data.getLongExtra("total", 0)
                ))
            } else callback?.success(null)
        }
        if (requestCode == REQUEST_PICK_IMAGE) {
            val callback = pendingPickCallback
            pendingPickCallback = null
            val uri = data?.data
            if (resultCode == RESULT_OK && uri != null) {
                callback?.invoke(copyUriToCache(uri))
            } else {
                callback?.invoke(null)
            }
        }
    }

    private fun copyUriToCache(uri: Uri): String? {
        return try {
            val input = contentResolver.openInputStream(uri) ?: return null
            val outFile = File(cacheDir, "avatar_${System.currentTimeMillis()}.jpg")
            outFile.outputStream().use { out -> input.copyTo(out) }
            input.close()
            outFile.absolutePath
        } catch (e: Exception) {
            Log.e("OldPods", "copyUriToCache failed", e)
            null
        }
    }

    companion object {
        private const val REQUEST_PICK_IMAGE = 4711
        private const val REQUEST_BROWSER = 4712
    }
}
