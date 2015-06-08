package com.pigmassacre.breakhaus;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Preferences;

public class Settings {

	private static final String PREFS_NAME = "mBreak";
	
	private static final String DEBUG_MODE = "debug_mode";
	
	public static int GAME_SCALE = 4;
	public static int GAME_FPS = 60;
	
	public static float LEVEL_WIDTH, LEVEL_HEIGHT, LEVEL_X, LEVEL_MAX_X, LEVEL_Y, LEVEL_MAX_Y;
	
	protected static Preferences getPreferences() {
		return Gdx.app.getPreferences(PREFS_NAME);
	}
	
	public static void savePreferences() {
		getPreferences().flush();
	}
	
	public static boolean getDebugMode() {
		return getPreferences().getBoolean(DEBUG_MODE, false);
	}
	
	public static void setDebugMode(boolean mode) {
		getPreferences().putBoolean(DEBUG_MODE, mode);
	}
	
	private static float levelYOffset = -2 * Settings.GAME_SCALE;
	
	public static float getLevelYOffset() {
		return Settings.levelYOffset;
	}
	
	public static void setLevelYOffset(float levelYOffset) {
		Settings.levelYOffset = levelYOffset;
	}

}
