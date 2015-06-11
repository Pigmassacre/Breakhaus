package com.pigmassacre.breakhaus.gui;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.g2d.Batch;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.GlyphLayout;
import com.badlogic.gdx.math.Rectangle;
import com.badlogic.gdx.utils.Align;
import com.pigmassacre.breakhaus.Assets;
import com.pigmassacre.breakhaus.Settings;

public class TextItem extends Item {

	private static final float BLINK_RATE = 0.75f;

	private static GlyphLayout layout;
	private static BitmapFont font;
	private CharSequence text;

	private Color shadowColor;

	public boolean blink = false;
	private float stateBlinkTime;

	private boolean wrapped;

	private float textSideBounds;

	private int alignment;

	public TextItem() {
		this("");
	}

	public TextItem(CharSequence text) {
		super();

		if (layout == null) {
			layout = new GlyphLayout();
		}

		if (font == null) {
			font = Assets.getStandardFont();
		}
		setScale(Settings.GAME_SCALE);
		shadowColor = new Color(0.196f, 0.196f, 0.196f, 1.0f);

		this.text = text;

		shadowOffsetX = 0f;
		shadowOffsetY = -1f * Settings.GAME_SCALE;

		textSideBounds = 25f * Settings.GAME_SCALE;
		wrapped = false;
		alignment = Align.left;

		stateBlinkTime = 0f;

		float selectionWidthIncrease = 1.0f;
		float selectionHeightIncrease = 1.5f;
		rectangle = new Rectangle(getX() + (getWidth() - getWidth() * selectionWidthIncrease),
				getY() + (getHeight() - getHeight() * selectionHeightIncrease),
				getWidth() * selectionWidthIncrease,
				getHeight() * selectionHeightIncrease);
	}

	public void setText(CharSequence text) {
		this.text = text;
	}

	public void setAlignment(int alignment) {
		this.alignment = alignment;
	}

	public int getAlignment() {
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
		font.getData().setScale(getScaleX(), getScaleY());
		layout.setText(font, text, font.getColor(), Gdx.graphics.getWidth() - textSideBounds, Align.left, wrapped);
		return layout.width;
	}

	public float getHeight() {
		font.getData().setScale(getScaleX(), getScaleY());
		layout.setText(font, text, font.getColor(), Gdx.graphics.getWidth() - textSideBounds, Align.left, wrapped);
		return layout.height;
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
		font.getData().setScale(scaleX, scaleY);
		layout.setText(font, string, font.getColor(), Gdx.graphics.getWidth() - textSideBounds, Align.left, wrapped);
		return layout.width;
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
		font.getData().setScale(scaleX, scaleY);
		layout.setText(font, string, font.getColor(), Gdx.graphics.getWidth() - textSideBounds, Align.left, wrapped);
		return layout.height;
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
			if (stateBlinkTime > BLINK_RATE) {
				if (getColor().a == 1.0f) {
					setHide(true);
					stateBlinkTime = BLINK_RATE / 3f;
				} else {
					setHide(false);
					stateBlinkTime = 0;
				}
			}
		}
	}

	public void draw(Batch batch, float parentAlpha) {
		font.getData().setScale(getScaleX(), getScaleY());
		shadowColor.a = getColor().a;
		font.setColor(shadowColor);
		if (wrapped) {
			font.draw(batch, text, getX() + getOffsetX() + getShadowOffsetX(), getY() + getOffsetY() + getShadowOffsetY(), getWrapWidth(), alignment, true);
		} else {
			font.draw(batch, text, getX() + getOffsetX() + getShadowOffsetX(), getY() + getOffsetY() + getShadowOffsetY());
		}
		if (getSelected()) {
			font.setColor(selectedColor);
		} else {
			font.setColor(getColor());
		}
		if (wrapped) {
			font.draw(batch, text, getX() + getOffsetX(), getY() + getOffsetY(), getWrapWidth(), alignment, true);
		} else {
			font.draw(batch, text, getX() + getOffsetX(), getY() + getOffsetY());
		}
	}

}
