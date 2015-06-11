package com.pigmassacre.breakhaus.screens;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input.Keys;
import com.badlogic.gdx.InputAdapter;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.utils.Timer;
import com.badlogic.gdx.utils.Timer.Task;
import com.pigmassacre.breakhaus.Breakhaus;
import com.pigmassacre.breakhaus.gui.Splash;
import com.pigmassacre.breakhaus.gui.Splash.SplashCallback;

public class SplashScreen extends AbstractScreen {

	public SplashScreen(Breakhaus game) {
		super(game);
		Splash splash = new Splash();
		splash.setX(Gdx.graphics.getWidth() / 2 - splash.getWidth() / 2);
		splash.setY(Gdx.graphics.getHeight() / 2 - splash.getHeight() / 2);
		splash.setup(getTweenManager());
		splash.setCallback(new SplashCallback() {

			@Override
			public void execute(Splash splash) {
				startIntroScreen();
			}

		});
		stage.addActor(splash);
		backgroundColor = new Color(36 / 255f, 36 / 255f, 36 / 255f, 1f);
	}
	
	private void setupTimer() {
		Timer.instance().clear();
		Timer.instance().scheduleTask(new Task() {
			
			@Override
			public void run() {
				game.setScreen(new IntroScreen(game));
			}
			
		}, 0.1f);
	}
	
	private void startIntroScreen() {
		setupTimer();
	}

	@Override
	public void hide() {
		super.hide();
		dispose();
	}
	
	private class IntroInputProcessor extends InputAdapter {

		@Override
		public boolean keyDown(int keycode) {
			switch(keycode) {
			case Keys.ENTER:
			case Keys.ESCAPE:
				game.setScreen(new IntroScreen(game));
				break;
			}
			return true;
		}

		@Override
		public boolean touchDown(int screenX, int screenY, int pointer, int button) {
			game.setScreen(new IntroScreen(game));
			return true;
		}

	}
	
	@Override
	protected void registerInputProcessors() {
		getInputMultiplexer().addProcessor(new IntroInputProcessor());
	}
	
}
