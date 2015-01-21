package com.pigmassacre.breakhaus.gui;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.g2d.Batch;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.BitmapFont.HAlignment;
import com.badlogic.gdx.math.Rectangle;
import com.pigmassacre.breakhaus.Assets;
import com.pigmassacre.breakhaus.Settings;

public class TextItem extends Item {
	
	private static BitmapFont font;
	private CharSequence string;
	
	private Color shadowColor;
	
	public boolean blink = false;
	private float blinkRate = 0.75f;
	private float stateBlinkTime;
	
	private boolean wrapped;
	
	private float textSideBounds;

	private HAlignment alignment;
	
	public TextItem() {
		this("");
	}
	
	public TextItem(CharSequence string) {
		super();

		if (font == null) {
			font = Assets.getBitmapFont("fonts/ADDLG__.fnt");
		}
		setScale(Settings.GAME_SCALE);
		shadowColor = new Color(0.196f, 0.196f, 0.196f, 1.0f);
		
		this.string = string;
		
		shadowOffsetX = 0f;
		shadowOffsetY = -1f * Settings.GAME_SCALE;
		
		textSideBounds = 25f * Settings.GAME_SCALE;
		wrapped = false;
		alignment = HAlignment.LEFT;
		
		stateBlinkTime = 0f;

		float selectionWidthIncrease = 1.0f;
		float selectionHeightIncrease = 1.5f;
		rectangle = new Rectangle(getX() + (getWidth() - getWidth() * selectionWidthIncrease), 
								  getY() + (getHeight() - getHeight() * selectionHeightIncrease), 
								  getWidth() * selectionWidthIncrease, 
								  getHeight() * selectionHeightIncrease);
	}
	
	public void setString(CharSequence string) {
		this.string = string;
	}
	
	public void setAlignment(HAlignment alignment) {
		this.alignment = alignment;
	}
	
	public HAlignment getAlignment() {
		return alignment;
	}
	
	public boolean isWrapped() {
		return wrapped;
	}

	public void setWrapped(boolean wrapped) {
		this.wrapped = wrapped;
	}
	
	public float getWrapWidth() {
		return Gdx.graphics.getWidth() - textSideBounds;
	}
	
	public float getWidth() {
		font.setScale(getScaleX(), getScaleY());
		if (wrapped) {
			return font.getWrappedBounds(string, Gdx.graphics.getWidth() - textSideBounds).width;
		} else {
			return font.getBounds(string).width;
		}
	}
	
	public float getHeight() {
		font.setScale(getScaleX(), getScaleY());
		if (wrapped) {
			return font.getWrappedBounds(string, Gdx.graphics.getWidth() - textSideBounds).height;
		} else {
			return font.getBounds(string).height;
		}
	}
	
	/*
	 *  Static methods for accessing width and height of a given string.
	 */
	
	public static float getWidth(String string) {
		return getWidth(string, Settings.GAME_SCALE, Settings.GAME_SCALE, false, 0f);
	}
	
	public static float getWidth(String string, float scaleX, float scaleY) {
		return getWidth(string, scaleX, scaleY, false, 0f);
	}
	
	public static float getWidth(String string, boolean wrapped) {
		return getWidth(string, Settings.GAME_SCALE, Settings.GAME_SCALE, wrapped, 25 * Settings.GAME_SCALE);
	}
	
	public static float getWidth(String string, float scaleX, float scaleY, boolean wrapped) {
		return getWidth(string, scaleX, scaleY, wrapped, 25 * Settings.GAME_SCALE);
	}
	
	public static float getWidth(String string, float scaleX, float scaleY, boolean wrapped, float textSideBounds) {
		font.setScale(scaleX, scaleY);
		if (wrapped) {
			return font.getWrappedBounds(string, Gdx.graphics.getWidth() - textSideBounds).width;
		} else {
			return font.getBounds(string).width;
		}
	}
	
	public static float getHeight(String string) {
		return getHeight(string, Settings.GAME_SCALE, Settings.GAME_SCALE, false, 0f);
	}
	
	public static float getHeight(String string, float scaleX, float scaleY) {
		return getHeight(string, scaleX, scaleY, false, 0f);
	}
	
	public static float getHeight(String string, boolean wrapped) {
		return getHeight(string, Settings.GAME_SCALE, Settings.GAME_SCALE, wrapped, 25 * Settings.GAME_SCALE);
	}
	
	public static float getHeight(String string, float scaleX, float scaleY, boolean wrapped) {
		return getHeight(string, scaleX, scaleY, wrapped, 25 * Settings.GAME_SCALE);
	}
	
	public static float getHeight(String string, float scaleX, float scaleY, boolean wrapped, float textSideBounds) {
		font.setScale(scaleX, scaleY);
		if (wrapped) {
			return font.getWrappedBounds(string, Gdx.graphics.getWidth() - textSideBounds).height;
		} else {
			return font.getBounds(string).height;
		}
	}
	
	public void setHide(Boolean hide) {
		if (hide) {
			getColor().set(getColor().r, getColor().g, getColor().b, 0.0f);
			shadowColor.set(shadowColor.r, shadowColor.g, shadowColor.b, 0.0f);
		} else {
			getColor().set(getColor().r, getColor().g, getColor().b, 1.0f);
			shadowColor.set(shadowColor.r, shadowColor.g, shadowColor.b, 1.0f);
		}
	}
	
	public void act(float delta) {
		super.act(delta);
		
		if (blink) {
			stateBlinkTime += delta;
			if (stateBlinkTime > blinkRate) {
				if (getColor().a == 1.0f) {
					setHide(true);
					stateBlinkTime = blinkRate / 3f;
				} else {
					setHide(false);
					stateBlinkTime = 0;
				}
			}
		}
	}
	
	public void draw(Batch batch, float parentAlpha) {
		font.setScale(getScaleX(), getScaleY());
		shadowColor.a = getColor().a;
		font.setColor(shadowColor);
		if (wrapped) {
			font.drawWrapped(batch, string, getX() + getOffsetX() + getShadowOffsetX(), getY() + getOffsetY() + getShadowOffsetY(), getWrapWidth(), alignment);
		} else {
			font.draw(batch, string, getX() + getOffsetX() + getShadowOffsetX(), getY() + getOffsetY() + getShadowOffsetY());
		}
		if (getSelected()) {
			font.setColor(selectedColor);
		} else {
			font.setColor(getColor());
		}
		if (wrapped) {
			font.drawWrapped(batch, string, getX() + getOffsetX(), getY() + getOffsetY(), getWrapWidth(), alignment);
		} else {
			font.draw(batch, string, getX() + getOffsetX(), getY() + getOffsetY());
		}
	}
	
}
