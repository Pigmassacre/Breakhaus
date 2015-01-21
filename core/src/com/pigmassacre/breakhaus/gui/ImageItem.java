package com.pigmassacre.breakhaus.gui;

import com.badlogic.gdx.graphics.g2d.Batch;
import com.badlogic.gdx.graphics.g2d.TextureRegion;
import com.pigmassacre.breakhaus.Assets;
import com.pigmassacre.breakhaus.Settings;

public class ImageItem extends RectItem {

	private TextureRegion image;
	
	public ImageItem(String atlasRegion) {
		super();
		
		image = Assets.getTextureRegion(atlasRegion);
	}
	
	protected float getImageWidth() {
		return image.getRegionWidth() * Settings.GAME_SCALE;
	}
	
	protected float getImageHeight() {
		return image.getRegionHeight() * Settings.GAME_SCALE;
	}
	
	public void drawBeforeDisabled(Batch batch, float parentAlpha) {
		batch.draw(image, rectangle.getX() + (rectangle.getWidth() - getImageWidth()) / 2, 
						  rectangle.getY() + (rectangle.getHeight() - getImageHeight()) / 2, 
						  getImageWidth(), 
						  getImageHeight());
	}
	
}
