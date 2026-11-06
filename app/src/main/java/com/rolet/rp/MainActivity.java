package com.rolet.rp;

import android.app.Activity;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.os.Bundle;
import android.webkit.JavascriptInterface;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.Toast;
import java.util.List;
import java.util.Locale;

public class MainActivity extends Activity {
    private WebView web;

    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        web = new WebView(this);
        web.setWebViewClient(new WebViewClient());
        web.getSettings().setJavaScriptEnabled(true);
        web.getSettings().setDomStorageEnabled(true);
        web.addJavascriptInterface(new GameBridge(), "RoleT");
        setContentView(web);
        web.loadUrl("file:///android_asset/index.html");
    }

    private class GameBridge {
        @JavascriptInterface
        public void openGame() {
            runOnUiThread(() -> {
                PackageManager pm = getPackageManager();
                Intent launcher = new Intent(Intent.ACTION_MAIN, null);
                launcher.addCategory(Intent.CATEGORY_LAUNCHER);
                List<ResolveInfo> apps = pm.queryIntentActivities(launcher, 0);
                ResolveInfo match = null;
                for (ResolveInfo app : apps) {
                    CharSequence label = app.loadLabel(pm);
                    String name = label == null ? "" : label.toString().toLowerCase(Locale.ROOT);
                    if (name.contains("samp") || name.contains("sa-mp")) {
                        match = app;
                        break;
                    }
                }
                if (match != null) {
                    Intent launch = pm.getLaunchIntentForPackage(match.activityInfo.packageName);
                    if (launch != null) {
                        try {
                            startActivity(launch);
                            return;
                        } catch (Exception ignored) { }
                    }
                }
                Toast.makeText(MainActivity.this,
                    "Не удалось автоматически найти SA-MP Mobile. Проверь, что клиент установлен.",
                    Toast.LENGTH_LONG).show();
                if (web != null) {
                    web.evaluateJavascript("showPlayMessage('SA-MP Mobile не найден автоматически. Проверь название приложения или сообщи мне, как оно называется.')", null);
                }
            });
        }
    }
}
