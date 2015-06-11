package com.pigmassacre.breakhaus;

import com.badlogic.gdx.assets.AssetManager;
import com.badlogic.gdx.audio.Music;
import com.badlogic.gdx.audio.Sound;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.TextureAtlas;
import com.badlogic.gdx.graphics.g2d.TextureRegion;
import com.pigmassacre.breakhaus.objects.GrayscaleShader;

public class Assets {

	private static AssetManager assetManager;
	
	public static void loadAssetManager() {
		assetManager = new AssetManager();
	}
	
	public static AssetManager getAssetManager() {
		if (assetManager == null) {
			System.err.println("AssetManager not loaded.");
		}
		return assetManager;
	}
	
	public static void loadFonts() {
		getAssetManager();
		
		if (!assetManager.isLoaded("fonts/ADDLG__.fnt")) {
			assetManager.load("fonts/ADDLG__.fnt", BitmapFont.class);
		}
		if (!assetManager.isLoaded("sound/select.ogg")) {
			assetManager.load("sound/select.ogg", Sound.class);
		}
	}
	
	public static void loadMenuAssets() {
		getAssetManager();
		
		if (!assetManager.isLoaded("images/menutextures.atlas")) {
			assetManager.load("images/menutextures.atlas", TextureAtlas.class);
		}
		if (!assetManager.isLoaded("music/title/goluigi-nonuniform.ogg")) {
			assetManager.load("music/title/goluigi-nonuniform.ogg", Music.class);
		}
		if (!assetManager.isLoaded("images/gametextures.atlas")) {
			assetManager.load("images/gametextures.atlas", TextureAtlas.class);
		}
	}
	
	public static void loadGameAssets() {
		getAssetManager();
		
		GrayscaleShader.loadShader();
		
		if (!assetManager.isLoaded("sound/ball.ogg")) {
			assetManager.load("sound/ball.ogg", Sound.class);
		}
		if (!assetManager.isLoaded("sound/blockDestroyed.wav")) {
			assetManager.load("sound/blockDestroyed.wav", Sound.class);
		}
		if (!assetManager.isLoaded("music/game/choke.ogg")) {
			assetManager.load("music/game/choke.ogg", Music.class);
		}
		if (!assetManager.isLoaded("music/game/divine_intervention.ogg")) {
			assetManager.load("music/game/divine_intervention.ogg", Music.class);
		}
		if (!assetManager.isLoaded("music/game/socialmoron.ogg")) {
			assetManager.load("music/game/socialmoron.ogg", Music.class);
		}
		if (!assetManager.isLoaded("music/game/stardstm.ogg")) {
			assetManager.load("music/game/stardstm.ogg", Music.class);
		}
	}
	
	public static void unloadGameAssets() {
		getAssetManager();
		
		if (assetManager.isLoaded("sound/ball.ogg")) {
			assetManager.unload("sound/ball.ogg");
		}
		if (assetManager.isLoaded("sound/blockDestroyed.wav")) {
			assetManager.unload("sound/blockDestroyed.wav");
		}
		if (assetManager.isLoaded("music/game/choke.ogg")) {
			assetManager.unload("music/game/choke.ogg");
		}
		if (assetManager.isLoaded("music/game/divine_intervention.ogg")) {
			assetManager.unload("music/game/divine_intervention.ogg");
		}
		if (assetManager.isLoaded("music/game/socialmoron.ogg")) {
			assetManager.unload("music/game/socialmoron.ogg");
		}
		if (assetManager.isLoaded("music/game/stardstm.ogg")) {
			assetManager.unload("music/game/stardstm.ogg");
		}
	}
	
	private static TextureAtlas getMenuTextureAtlas() {
		return assetManager.get("images/menutextures.atlas", TextureAtlas.class);
	}
	
	private static TextureAtlas getGameTextureAtlas() {
		return assetManager.get("images/gametextures.atlas", TextureAtlas.class);
	}
	
	public static TextureRegion getTextureRegion(String name) {
		TextureRegion region;
		region = getMenuTextureAtlas().findRegion(name);
		if (region != null) {
			return region;
		}
		region = getGameTextureAtlas().findRegion(name);
		if (region != null) {
			return region;
		}
		return null;
	}

	public static Sound getSound(String name) {
		return assetManager.get(name, Sound.class);
	}
	
	public static Music getMusic(String name) {
		return assetManager.get(name, Music.class);
	}

	public static BitmapFont getStandardFont() {
		return assetManager.get("fonts/ADDLG__.fnt", BitmapFont.class);
	}

	public static BitmapFont getFont(String name) {
		return assetManager.get(name, BitmapFont.class);
	}
	
}
