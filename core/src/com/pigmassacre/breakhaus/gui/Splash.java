package com.pigmassacre.breakhaus.gui;

import aurelienribon.tweenengine.*;
import aurelienribon.tweenengine.equations.Expo;
import com.badlogic.gdx.graphics.g2d.Batch;
import com.badlogic.gdx.graphics.g2d.TextureRegion;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.scenes.scene2d.ui.Widget;
import com.badlogic.gdx.utils.Array;
import com.pigmassacre.breakhaus.Assets;
import com.pigmassacre.breakhaus.Settings;

public class Splash extends Widget {

	private static final int ROWS = 5, COLS = 5;
	
	private TextureRegion image;
	private TextureRegion[][] imageMatrix;
	private Array<SplashPart> splashParts;
	
	public Splash() {
		image = Assets.getTextureRegion("splash-125");
		imageMatrix = image.split(image.getRegionWidth() / COLS, image.getRegionHeight() / ROWS);
	}
	
	public void setup(TweenManager tweenManager) {
		splashParts = new Array<SplashPart>();
		float delay = 0f;
		boolean randomize = MathUtils.randomBoolean();
		Timeline timeline = Timeline.createParallel();
		for (int row = 0; row < ROWS; row++) {
			for (int col = 0; col < COLS; col++) {
				SplashPart splashPart = new SplashPart(imageMatrix[COLS - 1 - col][row]);
				splashPart.setX(getX() + imageMatrix[row][col].getRegionWidth() * row * Settings.GAME_SCALE);
				splashPart.setY(getY() + imageMatrix[row][col].getRegionHeight() * col * Settings.GAME_SCALE);
				splashPart.setWidth(imageMatrix[row][col].getRegionWidth() * Settings.GAME_SCALE);
				splashPart.setHeight(imageMatrix[row][col].getRegionHeight() * Settings.GAME_SCALE);
				splashPart.setScaleX(0);
				splashPart.setScaleY(0);
				
				if (randomize) {
					delay = MathUtils.random() * 0.33f;
				}
				
				timeline.beginSequence();
				timeline.push(Tween.to(splashPart, ActorAccessor.SCALE_XY, 1f)
							.target(1f, 1f)
							.ease(Expo.IN)
							.delay(delay))
					.pushPause(2f)
					.push(Tween.to(splashPart, ActorAccessor.SCALE_XY, 1f)
							.target(0f, 0f)
							.ease(Expo.OUT)
							.delay(delay));
				timeline.end();
				delay += 0.025f;
				splashParts.add(splashPart);
			}
		}
		timeline.setCallback(new TweenCallback() {
				
				@Override
				public void onEvent(int type, BaseTween<?> source) {
					executeCallback();
				}
				
			})
			.start(tweenManager);
	}
	
	public interface SplashCallback {
		
		public void execute(Splash splash);
		
	}
	
	private SplashCallback callback;
	
	public void setCallback(SplashCallback callback) {
		this.callback = callback;
	}
	
	private void executeCallback() {
		if (callback != null) {
			callback.execute(this);
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
	public void draw(Batch batch, float parentAlpha) {
		for (SplashPart splashPart : splashParts) {
			splashPart.draw(batch, parentAlpha);
		}
	}
	
	private class SplashPart extends Widget {
		
		private TextureRegion image;
		
		public SplashPart(TextureRegion image) {
			this.image = image;
		}
		
		@Override
		public void draw(Batch batch, float parentAlpha) {
			batch.draw(image, getX(), getY(), getWidth() / 2, getHeight() / 2, getWidth(), getHeight(), getScaleX(), getScaleY(), 0);
		}
		
	}
		
}
