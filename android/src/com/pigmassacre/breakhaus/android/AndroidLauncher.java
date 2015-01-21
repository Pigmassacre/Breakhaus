package com.pigmassacre.breakhaus.android;

import android.os.Bundle;
import com.badlogic.gdx.backends.android.AndroidApplication;
import com.badlogic.gdx.backends.android.AndroidApplicationConfiguration;
import com.pigmassacre.breakhaus.Breakhaus;

public class AndroidLauncher extends AndroidApplication {
	public void onCreate (android.os.Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);

		Display display = getWindowManager().getDefaultDisplay();
		int newScale;
		if (android.os.Build.VERSION.SDK_INT >= 13) {
			Point size = new Point();
			display.getSize(size);
			newScale = size.x / Settings.BASE_SCREEN_WIDTH;
		} else {
			newScale = display.getWidth() / Settings.BASE_SCREEN_WIDTH;
		}
		Settings.GAME_SCALE = newScale + 1;

		AndroidApplicationConfiguration cfg = new AndroidApplicationConfiguration();
		cfg.hideStatusBar = true;
		cfg.useGLSurfaceView20API18 = true;
		initialize(new Breakhaus(), cfg);
	}
}
