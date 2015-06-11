package com.pigmassacre.breakhaus.gui;

import aurelienribon.tweenengine.*;
import aurelienribon.tweenengine.equations.Expo;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.Pixmap.Format;
import com.badlogic.gdx.graphics.g2d.Batch;
import com.badlogic.gdx.graphics.g2d.TextureRegion;
import com.badlogic.gdx.graphics.glutils.FrameBuffer;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.scenes.scene2d.Stage;
import com.badlogic.gdx.scenes.scene2d.ui.Widget;
import com.badlogic.gdx.utils.Array;
import com.pigmassacre.breakhaus.Assets;
import com.pigmassacre.breakhaus.Settings;
import com.pigmassacre.breakhaus.gui.Accessors.ActorAccessor;

import java.util.ArrayList;
import java.util.List;

public class Blinder extends Widget {

	private int ROWS, COLS;
	
	private TextureRegion image;
	private Array<BlinderPart> blinderParts;
	
	public Blinder() {
		image = Assets.getTextureRegion("square");
	}
	
	public Blinder(TextureRegion image, Stage stage, TweenManager tweenManager) {
		this(image, stage, tweenManager, true, true, true, true);
	}
	
	public Blinder(TextureRegion image, Stage stage, TweenManager tweenManager, boolean left, boolean right, boolean up, boolean down) {
		int n = (int) Math.pow(4, 4);
		COLS = (int) Math.ceil(Math.sqrt(n));
		ROWS = (int) Math.ceil(n / (double) COLS);
		
		FrameBuffer fbo = new FrameBuffer(Format.RGB565, image.getTexture().getWidth(), image.getTexture().getHeight(), false);
        this.image = new TextureRegion(fbo.getColorBufferTexture());
        
        fbo.begin();
        stage.getBatch().begin();
        stage.getBatch().draw(image.getTexture(), 0, 0);
        stage.getBatch().end();
        fbo.end();
        
		TextureRegion[][] splitImages = this.image.split((int) (Gdx.graphics.getWidth() / (float)ROWS), (int) (Gdx.graphics.getHeight() / (float)COLS));
		
		List<String> choices = new ArrayList<String>();
		if (left)
			choices.add("left");
		if (right)
			choices.add("right");
		if (up)
			choices.add("up");
		if (down)
			choices.add("down");
		
		String choice = choices.get(MathUtils.random(choices.size() - 1));
		
		float delay = 0f;
		float delayDelta = 0.015f;
		switch (choice) {
		case "left":
			delay = 0f;
			break;
		case "right":
			delay = COLS * delayDelta;
			break;
		case "up":
			delay = 0f;
			break;
		case "down":
			delay = ROWS * delayDelta;
			break;
		}
		
		blinderParts = new Array<BlinderPart>();
		for (int col = 0; col < COLS; col++) {
			switch(choice) {
			case "left":
				delay = 0;
				break;
			case "right":
				delay = COLS * delayDelta;
				break;
			}
			for (int row = 0; row < ROWS; row++) {
				BlinderPart blinderPart = new BlinderPart(splitImages[col][row]);
				blinderPart.setColor(1f, 1f, 1f, 1f);
				blinderPart.setWidth(splitImages[col][row].getRegionWidth());
				blinderPart.setHeight(splitImages[col][row].getRegionHeight());
				blinderPart.setX(getX() + blinderPart.getWidth() * row);
				blinderPart.setY(getY() + Gdx.graphics.getHeight() - blinderPart.getHeight() * col - blinderPart.getHeight());
				blinderParts.add(blinderPart);
				int tweenType = ActorAccessor.SCALE_XY;
//				switch(choice) {
//				case "left":
//				case "right":
//					tweenType = ActorAccessor.SIZE_W;
//					break;
//				case "up":
//				case "down":
//					tweenType = ActorAccessor.SIZE_H;
//					break;
//				}
				Timeline.createSequence()
					.push(Tween.to(blinderPart, tweenType, 0.25f)
							.target(0f, 0f)
							.ease(Expo.OUT)
							.delay(delay))
					.setUserData(blinderPart)
					.setCallback(new TweenCallback() {
						
						@Override
						public void onEvent(int type, BaseTween<?> source) {
							BlinderPart blinderPart = (BlinderPart) source.getUserData();
							blinderPart.remove();
							
						}
						
					})
					.start(tweenManager);
				blinderParts.add(blinderPart);
				switch(choice) {
				case "left":
					delay += delayDelta;
					break;
				case "right":
					delay -= delayDelta;
					break;
				}
			}
			switch(choice) {
			case "up":
				delay += delayDelta;
				break;
			case "down":
				delay -= delayDelta;
				break;
			}
		}
	}
	
	public void setup(TweenManager tweenManager) {
		int n = (int) Math.pow(4, 4);
		COLS = (int) Math.ceil(Math.sqrt(n));
		ROWS = (int) Math.ceil(n / (double) COLS);
		
		blinderParts = new Array<BlinderPart>();
		float delay = 0f;
		for (int col = 0; col < COLS; col++) {
			for (int row = 0; row < ROWS; row++) {
				BlinderPart blinderPart = new BlinderPart(image);
				blinderPart.setColor(36/255f, 36/255f, 36/255f, 1f);
				blinderPart.setWidth(Gdx.graphics.getWidth() / (float)ROWS);
				blinderPart.setHeight(Gdx.graphics.getHeight() / (float)COLS);
				blinderPart.setX(getX() + blinderPart.getWidth() * row);
				blinderPart.setY(getY() + blinderPart.getHeight() * col);
				Timeline.createSequence()
					.push(Tween.to(blinderPart, ActorAccessor.SCALE_XY, 0.5f)
							.target(0f, 0f)
							.ease(Expo.OUT)
							.delay(delay))
					.setUserData(blinderPart)
					.setCallback(new TweenCallback() {
						
						@Override
						public void onEvent(int type, BaseTween<?> source) {
							BlinderPart blinderPart = (BlinderPart) source.getUserData();
							blinderPart.remove();
							
						}
						
					})
					.start(tweenManager);
				blinderParts.add(blinderPart);
			}
			delay += 0.035f;
		}
	}
	
	@Override
	public float getWidth() {
		return image.getRegionWidth() * Settings.GAME_SCALE;
	}
	
	@Override
	public float getHeight() {
		return image.getRegionHeight() * Settings.GAME_SCALE;
	}
	
	@Override
	public void act(float delta) {
		for (BlinderPart blinderPart : blinderParts) {
			blinderPart.act(delta);
		}
	}
	
	@Override
	public void draw(Batch batch, float parentAlpha) {
		for (BlinderPart blinderPart : blinderParts) {
			blinderPart.draw(batch, parentAlpha);
		}
	}
	
	private class BlinderPart extends Widget {
		
		private TextureRegion image;
		
		public BlinderPart(TextureRegion image) {
			this.image = image;
		}
		
		private Color temp;
		
		@Override
		public void draw(Batch batch, float parentAlpha) {
			temp = batch.getColor();
			batch.setColor(getColor());
			batch.draw(image, getX(), getY(), getWidth() / 2, getHeight() / 2, getWidth(), getHeight(), getScaleX(), getScaleY(), 0);
			batch.setColor(temp);
		}
		
	}
		
}
