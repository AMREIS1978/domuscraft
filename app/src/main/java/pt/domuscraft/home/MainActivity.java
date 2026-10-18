package pt.domuscraft.home;
import android.app.Activity;
import android.os.Bundle;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.view.View;
public class MainActivity extends Activity {
  private WebView web;
  @Override public void onCreate(Bundle b) { super.onCreate(b);
    getWindow().getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_FULLSCREEN | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN);
    web = new WebView(this); setContentView(web);
    web.setWebViewClient(new WebViewClient()); web.setWebChromeClient(new WebChromeClient());
    WebSettings s=web.getSettings(); s.setJavaScriptEnabled(true); s.setDomStorageEnabled(true);
    s.setAllowFileAccess(true); web.loadUrl("file:///android_asset/index.html");
  }
  @Override public void onBackPressed() { if(web.canGoBack()) web.goBack(); else super.onBackPressed(); }
}