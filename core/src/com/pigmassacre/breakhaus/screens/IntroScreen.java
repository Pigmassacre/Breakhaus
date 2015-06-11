package com.pigmassacre.breakhaus.screens;

import aurelienribon.tweenengine.Tween;
import aurelienribon.tweenengine.TweenEquations;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input.Keys;
import com.badlogic.gdx.InputAdapter;
import com.pigmassacre.breakhaus.Breakhaus;
import com.pigmassacre.breakhaus.MusicHandler;
import com.pigmassacre.breakhaus.Settings;
import com.pigmassacre.breakhaus.gui.*;
import com.pigmassacre.breakhaus.gui.Accessors.ActorAccessor;

public class IntroScreen extends AbstractScreen {

	private final Logo logo;
	private final Sunrays sunrays;
	private TextItem[] introMessage;
	private float stateTime;
	
	private final TextItem versionMessage;
	
	private float introTime;
	private float endTime;
	
	private final Blinder blinder;
	
	public IntroScreen(Breakhaus game) {
		super(game);

		blinder = new Blinder();
		blinder.setup(getTweenManager());
		
		sunrays = new Sunrays();
		stage.addActor(sunrays);
		
		logo = new Logo();
		logo.setX((Gdx.graphics.getWidth() - logo.getWidth()) / 2);
		logo.setY((Gdx.graphics.getHeight() / 2));
		stage.addActor(logo);
		Tween.from(logo, ActorAccessor.POSITION_Y, 1.0f).target(Gdx.graphics.getHeight() + logo.getHeight())
			.ease(TweenEquations.easeOutBack)
			.start(getTweenManager());
		
		sunrays.attachTo(logo, 0, -logo.getHeight() / 6);
		
		createIntroMessage();
		
		versionMessage = new TextItem("alpha 1");
		versionMessage.setX(Gdx.graphics.getWidth() - versionMessage.getWidth() - versionMessage.getHeight());
		versionMessage.setY(versionMessage.getHeight() + versionMessage.getHeight());
		versionMessage.setColor(1.0f, 1.0f, 1.0f, 1.0f);
		stage.addActor(versionMessage);
		Tween.from(versionMessage, ActorAccessor.POSITION_XY, 1.0f).target(Gdx.graphics.getWidth(), -versionMessage.getHeight())
			.ease(TweenEquations.easeOutBack)
			.start(getTweenManager());
		
		stage.addActor(blinder);

		MusicHandler.setSong("music/title/goluigi-nonuniform.ogg");
		MusicHandler.setLooping(true);
		MusicHandler.play();
		
		introTime = 0;
		endTime = 1.0f;
	}
	
	private void createIntroMessage() {
		CharSequence string;
		int blinkBegin;
		int blinkEnd;
		switch(Gdx.app.getType()) {
		   case Android:
			   string = "TOUCH to start";
			   blinkBegin = 0;
			   blinkEnd = 4;
			   break;
		   case Desktop:
			   string = "Press ENTER to start";
			   blinkBegin = 6;
			   blinkEnd = 11;
			   break;
		   default:
			   string = "PRESS START";
			   blinkBegin = 0;
			   blinkEnd = 11;
			   break;
		}
		
		introMessage = new TextItem[string.length()];
		
		for (int i = 0; i < string.length(); i++) {
			introMessage[i] = new TextItem(string.subSequence(i, i + 1));
			introMessage[i].setMaxOffsetY(10 * Settings.GAME_SCALE);
			introMessage[i].setColor(1.0f, 1.0f, 1.0f, 1.0f);
			stage.addActor(introMessage[i]);
		}
		
		int sum = 0;
		for (TextItem anIntroMessage : introMessage) {
			sum += anIntroMessage.getWidth();
		}
		
		float offset = 0;
		for (int i = 0; i < string.length(); i++) {
			introMessage[i].setX(((Gdx.graphics.getWidth() - sum) / 2) + offset);
			introMessage[i].setY(logo.getY() - introMessage[i].getHeight());
			offset += introMessage[i].getWidth();
			
			if (blinkBegin <= i && i <= blinkEnd) {
				introMessage[i].blink = true;
			}
			
			Tween.from(introMessage[i], ActorAccessor.POSITION_Y, 1.0f).target(-introMessage[i].getHeight())
				.ease(TweenEquations.easeOutBounce)
				.start(getTweenManager());
		}
		
		stateTime = 0f;
	}

	@Override
	public void render(float delta) {
		stateTime += Gdx.graphics.getDeltaTime() * 1000;
		
		for (int i = 0; i < introMessage.length; i++) {
			float differentiator = i * 64;
			float sinScale = 0.0075f;

			float sin = 0.3f * Settings.GAME_SCALE;
			sin *= Math.tan((stateTime + differentiator) * (sinScale / 4.0));
			sin *= Math.sin((stateTime + differentiator) * (sinScale / 16.0));
			sin *= Math.sin((stateTime + differentiator) * (sinScale / 8.0));
			sin *= Math.sin((stateTime + differentiator) * sinScale);

			introMessage[i].setOffsetY(sin * 2.0f * 3f);
		}
		
		versionMessage.setX(Gdx.graphics.getWidth() - versionMessage.getWidth() - versionMessage.getHeight());
		versionMessage.setY(versionMessage.getHeight() + versionMessage.getHeight());
		
		if (introTime < endTime)
			introTime += delta;
		if (introTime >= endTime)
			super.render(delta);
	}
	
	private void startMainMenu() {
		game.setScreen(new MainMenuScreen(game, logo, sunrays));
		dispose();
	}
	
	private class IntroInputProcessor extends InputAdapter {

		@Override
		public boolean keyDown(int keycode) {
			switch(keycode) {
			case Keys.ENTER:
			case Keys.ESCAPE:
				startMainMenu();
				break;
			}
			return true;
		}

		@Override
		public boolean touchDown(int screenX, int screenY, int pointer, int button) {
			startMainMenu();
			return true;
		}

	}
	
	@Override
	protected void registerInputProcessors() {
		getInputMultiplexer().addProcessor(new IntroInputProcessor());
	}
	
}
