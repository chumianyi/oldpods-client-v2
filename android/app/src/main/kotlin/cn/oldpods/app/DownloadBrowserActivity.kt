package cn.oldpods.app

import android.app.Activity
import android.app.AlertDialog
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.net.Uri
import android.os.Bundle
import android.view.View
import android.webkit.*
import android.widget.*

/** Download detection belongs to WebView: no scraping and no external browser. */
class DownloadBrowserActivity : Activity() {
    private lateinit var web: WebView
    private lateinit var progress: ProgressBar
    private lateinit var address: TextView
    private lateinit var errorPanel: LinearLayout
    private var dialog: AlertDialog? = null
    private var lastPage = ""
    private val accent = Color.rgb(24, 112, 91)
    private val font by lazy {
        try { Typeface.createFromAsset(assets, "flutter_assets/assets/fonts/LXGWWenKai-Light.ttf") }
        catch (_: Exception) { Typeface.create("sans-serif-light", Typeface.NORMAL) }
    }

    override fun onCreate(state: Bundle?) {
        super.onCreate(state)
        val initial = intent.getStringExtra("url") ?: ""
        if (!isWebUrl(initial)) { finish(); return }
        val dark = intent.getBooleanExtra("dark", false)
        val bg = if (dark) Color.rgb(18, 29, 27) else Color.rgb(248, 247, 243)
        val fg = if (dark) Color.rgb(232, 241, 237) else Color.rgb(26, 48, 41)
        val root = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL; setBackgroundColor(bg) }
        val toolbar = LinearLayout(this).apply { gravity = android.view.Gravity.CENTER_VERTICAL; setPadding(dp(8), dp(8), dp(8), dp(8)) }
        val close = button("关闭") { finish() }
        val refresh = button("刷新") { errorPanel.visibility = View.GONE; web.reload() }
        address = TextView(this).apply {
            typeface = font; textSize = 14f; setTextColor(fg)
            maxLines = 2; ellipsize = android.text.TextUtils.TruncateAt.END
            setPadding(dp(10), 0, dp(10), 0)
        }
        toolbar.addView(close)
        toolbar.addView(address, LinearLayout.LayoutParams(0, dp(54), 1f))
        toolbar.addView(refresh)
        root.addView(toolbar)
        progress = ProgressBar(this, null, android.R.attr.progressBarStyleHorizontal).apply { max = 100 }
        root.addView(progress, LinearLayout.LayoutParams(-1, dp(3)))
        errorPanel = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL; setPadding(dp(24), dp(24), dp(24), dp(24)); visibility = View.GONE
            addView(TextView(this@DownloadBrowserActivity).apply {
                typeface = font; text = "网页暂时无法打开\n请检查网络后重试。下载不会在未确认时开始。"; textSize = 16f; setTextColor(fg)
            })
            addView(button("重新加载") { visibility = View.GONE; web.loadUrl(lastPage.ifEmpty { initial }) })
        }
        root.addView(errorPanel)
        web = WebView(this)
        root.addView(web, LinearLayout.LayoutParams(-1, 0, 1f))
        setContentView(root)
        window.statusBarColor = bg
        window.navigationBarColor = bg
        web.settings.apply {
            javaScriptEnabled = true
            domStorageEnabled = true
            allowFileAccess = false
            allowContentAccess = false
            javaScriptCanOpenWindowsAutomatically = false
            // Keep target=_blank in this WebView so the download listener is retained.
            setSupportMultipleWindows(false)
            mixedContentMode = WebSettings.MIXED_CONTENT_NEVER_ALLOW
            userAgentString = intent.getStringExtra("userAgent") ?: userAgentString
        }
        val cookies = CookieManager.getInstance()
        cookies.setAcceptCookie(true)
        cookies.setAcceptThirdPartyCookies(web, true)
        // Never inject API session cookies into a file host.
        if (Uri.parse(initial).host.equals("oldpods.cn", true)) {
            intent.getStringExtra("cookie")?.split(";")?.forEach { cookie ->
                if (cookie.contains("=")) cookies.setCookie("http://oldpods.cn", cookie.trim())
            }
            cookies.flush()
        }
        web.webViewClient = object : WebViewClient() {
            override fun shouldOverrideUrlLoading(view: WebView, request: WebResourceRequest): Boolean = !isWebUrl(request.url.toString())
            @Deprecated("Android compatibility")
            override fun shouldOverrideUrlLoading(view: WebView, url: String): Boolean = !isWebUrl(url)
            override fun onPageStarted(view: WebView, url: String, icon: android.graphics.Bitmap?) {
                lastPage = url; address.text = Uri.parse(url).host ?: "下载网页"; progress.visibility = View.VISIBLE
                errorPanel.visibility = View.GONE
            }
            override fun onPageFinished(view: WebView, url: String) { cookies.flush() }
            override fun onReceivedError(view: WebView, request: WebResourceRequest, error: WebResourceError) {
                if (request.isForMainFrame) { errorPanel.visibility = View.VISIBLE; progress.visibility = View.GONE }
            }
            override fun onReceivedHttpError(view: WebView, request: WebResourceRequest, response: WebResourceResponse) {
                if (request.isForMainFrame && response.statusCode >= 400) { errorPanel.visibility = View.VISIBLE; progress.visibility = View.GONE }
            }
            override fun onReceivedSslError(view: WebView, handler: SslErrorHandler, error: android.net.http.SslError) {
                handler.cancel(); errorPanel.visibility = View.VISIBLE; progress.visibility = View.GONE
            }
        }
        web.webChromeClient = object : WebChromeClient() {
            override fun onProgressChanged(view: WebView, value: Int) {
                progress.progress = value; progress.visibility = if (value >= 100) View.GONE else View.VISIBLE
            }
            override fun onCreateWindow(view: WebView, isDialog: Boolean, isUserGesture: Boolean, resultMsg: android.os.Message): Boolean {
                if (!isUserGesture) return false
                // Capture target=_blank without launching another application.
                val child = WebView(this@DownloadBrowserActivity)
                child.webViewClient = object : WebViewClient() {
                    override fun shouldOverrideUrlLoading(v: WebView, request: WebResourceRequest): Boolean {
                        if (isWebUrl(request.url.toString())) web.loadUrl(request.url.toString())
                        child.destroy(); return true
                    }
                }
                (resultMsg.obj as WebView.WebViewTransport).webView = child
                resultMsg.sendToTarget()
                return true
            }
        }
        web.setDownloadListener { url, ua, disposition, mime, length ->
            if (!isWebUrl(url)) {
                Toast.makeText(this, "该网页使用了暂不支持的下载方式，请选择 HTTP 下载链接", Toast.LENGTH_LONG).show()
                return@setDownloadListener
            }
            if (dialog?.isShowing == true || isFinishing) return@setDownloadListener
            val name = NativeDownloads.safeName(URLUtil.guessFileName(url, disposition, mime))
            val size = if (length > 0) "%.1f MB".format(length / 1048576.0) else "由下载服务器提供"
            val source = Uri.parse(url).host ?: "未知来源"
            val text = TextView(this).apply {
                typeface = font; textSize = 16f; setTextColor(fg); setPadding(dp(24), dp(12), dp(24), dp(12))
                this.text = "$name\n\n大小：$size\n来源：$source\n\n添加后可在下载管理中查看进度。请仅下载可信来源的文件。"
            }
            dialog = AlertDialog.Builder(this)
                .setTitle("发现下载文件")
                .setView(text)
                .setNegativeButton("取消", null)
                .setPositiveButton("下载") { _, _ ->
                    setResult(RESULT_OK, Intent().apply {
                        putExtra("url", url); putExtra("fileName", name); putExtra("mime", mime ?: "application/octet-stream")
                        putExtra("userAgent", ua ?: web.settings.userAgentString)
                        putExtra("cookie", cookies.getCookie(url) ?: "")
                        putExtra("referer", web.url ?: initial); putExtra("total", length)
                        putExtra("sourceUrl", initial)
                    })
                    finish()
                }.create()
            dialog?.show()
            dialog?.getButton(AlertDialog.BUTTON_POSITIVE)?.apply { typeface = font; setTextColor(accent) }
            dialog?.getButton(AlertDialog.BUTTON_NEGATIVE)?.typeface = font
        }
        val headers = mutableMapOf<String, String>()
        if (Uri.parse(initial).host.equals("oldpods.cn", true)) {
            intent.getStringExtra("apiKey")?.takeIf { it.isNotEmpty() }?.let { headers["API-Key"] = it }
        }
        if (state == null) web.loadUrl(initial, headers) else web.restoreState(state)
    }

    override fun onSaveInstanceState(outState: Bundle) {
        if (::web.isInitialized) web.saveState(outState)
        super.onSaveInstanceState(outState)
    }
    @Deprecated("Activity back compatibility")
    override fun onBackPressed() { if (::web.isInitialized && web.canGoBack()) web.goBack() else super.onBackPressed() }
    override fun onDestroy() {
        dialog?.dismiss()
        if (::web.isInitialized) { web.stopLoading(); web.destroy() }
        super.onDestroy()
    }
    private fun button(label: String, action: () -> Unit) = Button(this).apply {
        text = label; typeface = font; textSize = 14f; isAllCaps = false; setTextColor(accent)
        minHeight = dp(48); setOnClickListener { action() }
    }
    private fun dp(value: Int): Int = (value * resources.displayMetrics.density).toInt()
    private fun isWebUrl(value: String): Boolean {
        val u = Uri.parse(value)
        return (u.scheme == "http" || u.scheme == "https") && !u.host.isNullOrEmpty() && u.userInfo == null
    }
}
