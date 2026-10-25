package cn.oldpods.app

import android.app.Activity
import android.content.Intent
import android.webkit.WebView
import android.view.ViewGroup
import androidx.test.core.app.ActivityScenario
import androidx.test.platform.app.InstrumentationRegistry
import androidx.test.uiautomator.By
import androidx.test.uiautomator.UiDevice
import androidx.test.uiautomator.Until
import org.junit.Assert.*
import org.junit.Test
import java.net.ServerSocket
import java.util.concurrent.Executors

class DownloadFlowTest {
    private fun findWeb(group: ViewGroup): WebView? {
        for (i in 0 until group.childCount) {
            val view = group.getChildAt(i)
            if (view is WebView) return view
            if (view is ViewGroup) findWeb(view)?.let { return it }
        }
        return null
    }

    @Test fun webDetectionConfirmationAndSystemQueue() {
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val context = instrumentation.targetContext
        val server = ServerSocket(0)
        val executor = Executors.newSingleThreadExecutor()
        val base = "http://127.0.0.1:${server.localPort}"
        executor.execute {
            while (!server.isClosed) {
                try {
                    server.accept().use { socket ->
                        val reader = socket.getInputStream().bufferedReader()
                        val path = reader.readLine()?.split(" ")?.getOrNull(1) ?: "/"
                        while (!reader.readLine().isNullOrEmpty()) { }
                        val file = path.startsWith("/file")
                        val body = if (file) ByteArray(4096) { 42 } else
                            "<html><body><a id='file' href='$base/file.bin'>Download fixture</a></body></html>".toByteArray()
                        val headers = "HTTP/1.1 200 OK\r\nContent-Type: ${if (file) "application/octet-stream" else "text/html"}\r\n" +
                            (if (file) "Content-Disposition: attachment; filename=fixture.bin\r\n" else "") +
                            "Content-Length: ${body.size}\r\nConnection: close\r\n\r\n"
                        socket.getOutputStream().apply { write(headers.toByteArray()); write(body); flush() }
                    }
                } catch (_: Exception) { }
            }
        }
        val device = UiDevice.getInstance(instrumentation)
        val native = NativeDownloads(context)
        val before = native.list().size
        try {
            val intent = Intent(context, DownloadBrowserActivity::class.java).putExtra("url", "$base/page")
            val scenario = ActivityScenario.launchActivityForResult<DownloadBrowserActivity>(intent)
            try {
                Thread.sleep(2500)
                scenario.onActivity { activity ->
                    findWeb(activity.findViewById(android.R.id.content))!!.evaluateJavascript("document.getElementById('file').click()", null)
                }
                assertTrue("Download dialog must appear", device.wait(Until.hasObject(By.text("发现下载文件")), 10000))
                assertEquals("Detection alone must not enqueue", before, native.list().size)
                device.findObject(By.text("取消")).click()
                assertEquals("Cancel must not enqueue", before, native.list().size)
                scenario.onActivity { activity ->
                    findWeb(activity.findViewById(android.R.id.content))!!.evaluateJavascript("document.getElementById('file').click()", null)
                }
                assertTrue(device.wait(Until.hasObject(By.text("下载")), 10000))
                device.findObject(By.text("下载")).click()
                Thread.sleep(1000)
                val result = scenario.result
                assertEquals(Activity.RESULT_OK, result.resultCode)
                val data = result.resultData!!
                assertEquals("$base/file.bin", data.getStringExtra("url"))
                val args = mutableMapOf<String, Any>("appId" to 99, "appTitle" to "Fixture")
                for (key in listOf("url", "sourceUrl", "fileName", "mime", "cookie", "referer", "userAgent")) {
                    args[key] = data.getStringExtra(key).orEmpty()
                }
                val id = native.enqueue(args)
                try {
                    var done = false
                    for (i in 0 until 30) {
                        val row = native.list().find { (it["nativeId"] as Number).toLong() == id }
                        if (row?.get("status") == "completed") { done = true; break }
                        Thread.sleep(500)
                    }
                    assertTrue("Confirmed file must complete in system queue", done)
                } finally { native.forget(id, true) }
            } finally { scenario.close() }
        } finally { server.close(); executor.shutdownNow() }
    }
}
