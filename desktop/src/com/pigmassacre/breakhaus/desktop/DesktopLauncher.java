package com.pigmassacre.breakhaus.desktop;

import com.badlogic.gdx.backends.lwjgl.LwjglApplication;
import com.badlogic.gdx.backends.lwjgl.LwjglApplicationConfiguration;
import com.badlogic.gdx.tools.texturepacker.TexturePacker;
import com.pigmassacre.breakhaus.Breakhaus;
import com.pigmassacre.breakhaus.Settings;

public class DesktopLauncher {
	public static void main (String[] arg) {
		LwjglApplicationConfiguration config = new LwjglApplicationConfiguration();

		TexturePacker.processIfModified("../../texturepackerassets/menu", "images", "menutextures");
		TexturePacker.processIfModified("../../texturepackerassets/game", "images", "gametextures");

		config.fullscreen = false;

		if (config.fullscreen) {
			config.setFromDisplayMode(LwjglApplicationConfiguration.getDesktopDisplayMode());
			float newScale = LwjglApplicationConfiguration.getDesktopDisplayMode().width / Settings.BASE_SCREEN_WIDTH;
			Settings.GAME_SCALE = (int) Math.ceil(newScale + 1);
		} else {
			config.width = (int) (285 * Settings.GAME_SCALE);
			config.height = (int) (160 * Settings.GAME_SCALE);
		}

		System.out.println("Set GAME_SCALE to " + Settings.GAME_SCALE);

		new LwjglApplication(new Breakhaus(), config);
	}
}
