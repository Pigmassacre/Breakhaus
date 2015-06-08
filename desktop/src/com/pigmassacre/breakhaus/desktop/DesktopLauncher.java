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

		config.width = LwjglApplicationConfiguration.getDesktopDisplayMode().width;
		config.height = LwjglApplicationConfiguration.getDesktopDisplayMode().height;

		//config.setFromDisplayMode(LwjglApplicationConfiguration.getDesktopDisplayMode());
		//float newScale = LwjglApplicationConfiguration.getDesktopDisplayMode().width / 285;
		//Settings.GAME_SCALE = (int) Math.ceil(newScale + 1);

		new LwjglApplication(new Breakhaus(), config);
	}
}
