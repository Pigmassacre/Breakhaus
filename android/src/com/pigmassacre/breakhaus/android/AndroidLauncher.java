package com.pigmassacre.breakhaus.android;

import android.graphics.Point;
import android.view.Display;
import com.badlogic.gdx.backends.android.AndroidApplication;
import com.badlogic.gdx.backends.android.AndroidApplicationConfiguration;
import com.pigmassacre.breakhaus.Breakhaus;
import com.pigmassacre.breakhaus.Settings;

public class AndroidLauncher extends AndroidApplication {
	public void onCreate (android.os.Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);

		Display display = getWindowManager().getDefaultDisplay();
		int newScale;
		if (android.os.Build.VERSION.SDK_INT >= 13) {
			Point size = new Point();
			display.getSize(size);
			newScale = size.x / 285;
		} else {
			newScale = display.getWidth() / 285;
		}
		Settings.GAME_SCALE = 4 + newScale - 1;

		AndroidApplicationConfiguration cfg = new AndroidApplicationConfiguration();
		cfg.hideStatusBar = true;
		//cfg.useGLSurfaceView20API18 = true;
		cfg.useAccelerometer = false;
		cfg.useCompass = false;
		initialize(new Breakhaus(), cfg);
	}
}
