package com.wisedom.professordomino;

import android.Manifest;
import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.provider.Settings;
import android.view.Gravity;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

public final class MainActivity extends Activity {
    private static final int OVERLAY_REQUEST_CODE = 4801;

    @Override
    protected void onCreate(Bundle bundle) {
        super.onCreate(bundle);
        requestNotificationPermission();
        showContent();
    }

    @Override
    protected void onResume() {
        super.onResume();
        if (Settings.canDrawOverlays(this)) {
            startDomino();
        }
    }

    private void showContent() {
        LinearLayout layout = new LinearLayout(this);
        layout.setOrientation(LinearLayout.VERTICAL);
        layout.setGravity(Gravity.CENTER);
        int padding = dp(24);
        layout.setPadding(padding, padding, padding, padding);

        ImageView image = new ImageView(this);
        image.setImageResource(R.drawable.cat_companion);
        image.setAdjustViewBounds(true);
        layout.addView(image, new LinearLayout.LayoutParams(dp(180), dp(180)));

        TextView title = new TextView(this);
        title.setText("Professor Domino");
        title.setTextSize(32);
        title.setGravity(Gravity.CENTER);
        layout.addView(title);

        TextView body = new TextView(this);
        body.setText("Allow Domino to appear over other apps, then drag him anywhere on your screen.");
        body.setTextSize(18);
        body.setGravity(Gravity.CENTER);
        body.setPadding(0, dp(12), 0, dp(22));
        layout.addView(body);

        Button button = new Button(this);
        button.setText(Settings.canDrawOverlays(this) ? "Start Domino" : "Allow Screen Companion");
        button.setOnClickListener(view -> {
            if (Settings.canDrawOverlays(this)) {
                startDomino();
            } else {
                Intent intent = new Intent(
                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                    Uri.parse("package:" + getPackageName())
                );
                startActivityForResult(intent, OVERLAY_REQUEST_CODE);
            }
        });
        layout.addView(button);

        setContentView(layout);
    }

    private void startDomino() {
        Intent intent = new Intent(this, DominoOverlayService.class);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent);
        } else {
            startService(intent);
        }
    }

    private void requestNotificationPermission() {
        if (Build.VERSION.SDK_INT >= 33) {
            requestPermissions(new String[] { Manifest.permission.POST_NOTIFICATIONS }, 42);
        }
    }

    private int dp(int value) {
        return (int) (value * getResources().getDisplayMetrics().density);
    }
}
