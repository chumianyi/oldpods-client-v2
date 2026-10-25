package cn.oldpods.app

import android.app.DownloadManager
import android.content.Context
import android.net.Uri
import android.os.Environment
import org.json.JSONArray
import org.json.JSONObject
import java.io.File

/** System-owned transfers survive process death and network changes. */
class NativeDownloads(private val context: Context) {
    private val manager = context.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
    private val prefs = context.getSharedPreferences("download_queue", Context.MODE_PRIVATE)
    private fun records(): JSONArray = try { JSONArray(prefs.getString("records", "[]")) } catch (_: Exception) { JSONArray() }

    fun enqueue(args: Map<*, *>): Long {
        val url = args["url"]?.toString() ?: error("缺少下载地址")
        val uri = Uri.parse(url)
        require(uri.scheme in listOf("https", "http") && !uri.host.isNullOrEmpty() && uri.userInfo == null) { "不支持的下载地址" }
        val mime = args["mime"]?.toString() ?: "application/octet-stream"
        require(!mime.contains("text/html", true) && !mime.contains("application/json", true)) { "服务器返回网页而不是文件" }
        val fileName = safeName(args["fileName"]?.toString() ?: "download.bin")
        val storedName = "${System.currentTimeMillis()}_$fileName"
        val request = DownloadManager.Request(uri)
            .setTitle(args["appTitle"]?.toString() ?: fileName)
            .setDescription(fileName)
            .setMimeType(mime)
            .setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
            .setAllowedOverMetered(true)
            .setAllowedOverRoaming(false)
            .setDestinationInExternalFilesDir(context, Environment.DIRECTORY_DOWNLOADS, "oldpods/$storedName")
        for (key in listOf("cookie", "userAgent", "referer")) {
            val value = args[key]?.toString().orEmpty()
            require(!value.contains('\r') && !value.contains('\n')) { "非法请求头" }
            if (value.isNotEmpty()) request.addRequestHeader(when (key) { "cookie" -> "Cookie"; "userAgent" -> "User-Agent"; else -> "Referer" }, value)
        }
        val id = manager.enqueue(request)
        val record = JSONObject().apply {
            put("nativeId", id); put("appId", args["appId"] ?: 0)
            put("appTitle", args["appTitle"] ?: fileName); put("fileName", fileName)
            put("url", url); put("sourceUrl", args["sourceUrl"] ?: url)
            put("mime", mime); put("createdAt", System.currentTimeMillis())
            put("storedPath", File(context.getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS), "oldpods/$storedName").absolutePath)
        }
        val all = records(); all.put(record)
        // No authentication cookies or API keys persisted with download history.
        prefs.edit().putString("records", all.toString()).apply()
        return id
    }

    fun list(): List<Map<String, Any?>> {
        val all = records()
        val result = mutableListOf<Map<String, Any?>>()
        for (i in all.length() - 1 downTo 0) {
            val row = all.getJSONObject(i)
            val id = row.getLong("nativeId")
            val data = mutableMapOf<String, Any?>()
            row.keys().forEach { key -> data[key] = row.opt(key) }
            data["status"] = if (row.optBoolean("canceled")) "canceled" else "failed"
            data["received"] = 0L; data["total"] = 0L
            data["error"] = "系统下载记录已不存在，请重新打开来源网页"
            manager.query(DownloadManager.Query().setFilterById(id))?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val status = cursor.getInt(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_STATUS))
                    val reason = cursor.getInt(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_REASON))
                    data["status"] = when (status) {
                        DownloadManager.STATUS_PENDING -> "queued"
                        DownloadManager.STATUS_PAUSED -> "queued"
                        DownloadManager.STATUS_RUNNING -> "downloading"
                        DownloadManager.STATUS_SUCCESSFUL -> "completed"
                        else -> "failed"
                    }
                    data["received"] = cursor.getLong(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_BYTES_DOWNLOADED_SO_FAR)).coerceAtLeast(0)
                    data["total"] = cursor.getLong(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_TOTAL_SIZE_BYTES)).coerceAtLeast(0)
                    data["error"] = when (status) {
                        DownloadManager.STATUS_PAUSED -> when (reason) {
                            DownloadManager.PAUSED_WAITING_FOR_NETWORK -> "等待网络连接"
                            DownloadManager.PAUSED_QUEUED_FOR_WIFI -> "等待 Wi-Fi"
                            else -> "等待系统重试"
                        }
                        DownloadManager.STATUS_FAILED -> when (reason) {
                            DownloadManager.ERROR_INSUFFICIENT_SPACE -> "存储空间不足"
                            DownloadManager.ERROR_FILE_ERROR -> "文件写入失败"
                            DownloadManager.ERROR_HTTP_DATA_ERROR -> "传输中断，请重新打开下载网页"
                            else -> "下载失败（$reason），请重新打开下载网页"
                        }
                        else -> null
                    }
                    if (status == DownloadManager.STATUS_SUCCESSFUL) {
                        val local = cursor.getString(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_LOCAL_URI))
                        val path = local?.let { Uri.parse(it).path } ?: row.optString("storedPath")
                        data["filePath"] = path
                        if (!File(path).exists()) { data["status"] = "failed"; data["error"] = "下载文件已被移除" }
                    }
                }
            }
            result.add(data)
        }
        return result
    }

    fun cancel(id: Long) {
        manager.remove(id)
        val all = records()
        for (i in 0 until all.length()) {
            val row = all.getJSONObject(i)
            if (row.optLong("nativeId") == id) row.put("canceled", true)
        }
        prefs.edit().putString("records", all.toString()).apply()
    }

    fun forget(id: Long, deleteFile: Boolean) {
        val source = records(); val target = JSONArray()
        for (i in 0 until source.length()) {
            val row = source.getJSONObject(i)
            if (row.optLong("nativeId") != id) target.put(row)
            else if (deleteFile) manager.remove(id)
        }
        prefs.edit().putString("records", target.toString()).apply()
    }

    companion object {
        fun safeName(name: String): String {
            val result = name.replace(Regex("[\\\\/:*?\"<>|\\p{Cntrl}]"), "_").trim().trim('.')
            return result.take(140).ifEmpty { "download.bin" }
        }
    }
}
