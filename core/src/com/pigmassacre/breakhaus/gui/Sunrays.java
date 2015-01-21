package com.pigmassacre.breakhaus.gui;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.g2d.Batch;
import com.badlogic.gdx.graphics.g2d.TextureRegion;
import com.badlogic.gdx.scenes.scene2d.ui.Widget;
import com.pigmassacre.breakhaus.Assets;
import com.pigmassacre.breakhaus.Settings;

public class Sunrays extends Widget {
	
	private TextureRegion image;
	
	private float rotation;
	
	private Widget target;
	public float offsetX, offsetY;
	
	public Sunrays() {
		image = Assets.getTextureRegion("cheatysunrays");
		setColor(1f, 1f, 1f, 0.25f);
	}
	
	public void attachTo(Widget widget, float offsetX, float offsetY) {
		target = widget;
		this.offsetX = offsetX;
		this.offsetY = offsetY;
	}
	
	public void removeTarget() {
		target = null;
//		this.offsetX = 0;
//		this.offsetY = 0;
	}
	
	@Override
	public float getWidth() {
		return image.getRegionWidth() * Settings.GAME_SCALE;
	}
	
	@Override
	public float getHeight() {
		return image.getRegionHeight() * Settings.GAME_SCALE;
	}
	
	public void act(float delta) {
		if (target != null) {
			setX(target.getX() + target.getWidth() / 2 - getWidth() / 2);
			setY(target.getY() + target.getHeight() / 2 - getHeight() / 2);
		}
		
		rotation += delta * 6;
	}
	
	private Color temp;
	
	@Override
	public void draw(Batch batch, float parentAlpha) {
		temp = batch.getColor();
		batch.setColor(getColor());
		batch.draw(image, getX() + offsetX, getY() + offsetY, getWidth() / 2, getHeight() / 2, getWidth(), getHeight(), 1f, 1f, rotation);
		batch.setColor(temp);
	}
	
}
