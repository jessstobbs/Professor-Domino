package com.wisedom.professordomino;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.Service;
import android.content.Intent;
import android.graphics.Color;
import android.graphics.PixelFormat;
import android.os.Build;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;
import android.provider.Settings;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.View;
import android.view.WindowManager;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.TextView;

public final class DominoOverlayService extends Service {
    private static final String CHANNEL_ID = "professor_domino_overlay";

    private WindowManager windowManager;
    private FrameLayout container;
    private TextView bubble;
    private ImageView domino;
    private QuoteStore quoteStore;
    private final Handler handler = new Handler(Looper.getMainLooper());
    private final Runnable hideBubble = () -> bubble.setVisibility(View.GONE);

    @Override
    public void onCreate() {
        super.onCreate();
        quoteStore = new QuoteStore(this);
        startForeground(7, notification());
        if (Settings.canDrawOverlays(this)) {
            createOverlay();
        }
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (container == null && Settings.canDrawOverlays(this)) {
            createOverlay();
        }
        return START_STICKY;
    }

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    @Override
    public void onDestroy() {
        handler.removeCallbacks(hideBubble);
        if (container != null) {
            windowManager.removeView(container);
        }
        super.onDestroy();
    }

    private void createOverlay() {
        windowManager = (WindowManager) getSystemService(WINDOW_SERVICE);

        container = new FrameLayout(this);
        bubble = new TextView(this);
        bubble.setTextColor(Color.rgb(35, 31, 32));
        bubble.setTextSize(20);
        bubble.setGravity(Gravity.CENTER);
        bubble.setPadding(dp(14), dp(10), dp(14), dp(10));
        bubble.setBackgroundColor(Color.rgb(255, 250, 242));
        bubble.setVisibility(View.GONE);

        domino = new ImageView(this);
        domino.setImageResource(R.drawable.cat_companion);
        domino.setAdjustViewBounds(true);
        domino.setOnClickListener(view -> showQuote());

        FrameLayout.LayoutParams bubbleParams = new FrameLayout.LayoutParams(dp(230), dp(118));
        bubbleParams.gravity = Gravity.TOP | Gravity.CENTER_HORIZONTAL;
        container.addView(bubble, bubbleParams);

        FrameLayout.LayoutParams dominoParams = new FrameLayout.LayoutParams(dp(160), dp(160));
        dominoParams.gravity = Gravity.BOTTOM | Gravity.CENTER_HORIZONTAL;
        container.addView(domino, dominoParams);

        WindowManager.LayoutParams params = new WindowManager.LayoutParams(
            dp(260),
            dp(292),
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.O
                ? WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                : WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
                | WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        );
        params.gravity = Gravity.TOP | Gravity.START;
        params.x = dp(80);
        params.y = dp(160);

        container.setOnTouchListener(new DragTouchListener(params));
        windowManager.addView(container, params);
    }

    private void showQuote() {
        domino.setImageResource(R.drawable.cat_companion_hover);
        bubble.setText(quoteStore.randomQuote().displayText());
        bubble.setVisibility(View.VISIBLE);
        handler.removeCallbacks(hideBubble);
        handler.postDelayed(() -> {
            domino.setImageResource(R.drawable.cat_companion);
            hideBubble.run();
        }, 6500);
    }

    private Notification notification() {
        NotificationManager manager = getSystemService(NotificationManager.class);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(
                CHANNEL_ID,
                getString(R.string.notification_channel),
                NotificationManager.IMPORTANCE_LOW
            );
            manager.createNotificationChannel(channel);
        }

        Notification.Builder builder = Build.VERSION.SDK_INT >= Build.VERSION_CODES.O
            ? new Notification.Builder(this, CHANNEL_ID)
            : new Notification.Builder(this);

        return builder
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle(getString(R.string.app_name))
            .setContentText(getString(R.string.notification_text))
            .setOngoing(true)
            .build();
    }

    private int dp(int value) {
        return (int) (value * getResources().getDisplayMetrics().density);
    }

    private final class DragTouchListener implements View.OnTouchListener {
        private final WindowManager.LayoutParams params;
        private int startX;
        private int startY;
        private float touchX;
        private float touchY;
        private boolean moved;

        DragTouchListener(WindowManager.LayoutParams params) {
            this.params = params;
        }

        @Override
        public boolean onTouch(View view, MotionEvent event) {
            switch (event.getAction()) {
                case MotionEvent.ACTION_DOWN:
                    startX = params.x;
                    startY = params.y;
                    touchX = event.getRawX();
                    touchY = event.getRawY();
                    moved = false;
                    return true;
                case MotionEvent.ACTION_MOVE:
                    int dx = (int) (event.getRawX() - touchX);
                    int dy = (int) (event.getRawY() - touchY);
                    if (Math.abs(dx) > 6 || Math.abs(dy) > 6) {
                        moved = true;
                    }
                    params.x = startX + dx;
                    params.y = startY + dy;
                    windowManager.updateViewLayout(container, params);
                    return true;
                case MotionEvent.ACTION_UP:
                    if (!moved) {
                        showQuote();
                    }
                    return true;
                default:
                    return false;
            }
        }
    }
}
