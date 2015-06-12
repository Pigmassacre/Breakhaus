package com.pigmassacre.breakhaus.screens;

import aurelienribon.tweenengine.Tween;
import aurelienribon.tweenengine.TweenEquations;
import aurelienribon.tweenengine.equations.Expo;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input.Keys;
import com.badlogic.gdx.InputAdapter;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.utils.Timer;
import com.pigmassacre.breakhaus.Breakhaus;
import com.pigmassacre.breakhaus.MusicHandler;
import com.pigmassacre.breakhaus.gui.Accessors.ActorAccessor;
import com.pigmassacre.breakhaus.gui.*;
import com.pigmassacre.breakhaus.gui.Item.ItemCallback;

public class GameOverScreen extends AbstractScreen {

	private final AbstractScreen pausedScreen;
	private final Backdrop backdrop;

	public GameOverScreen(Breakhaus game, AbstractScreen pausedScreen) {
		super(game);
		Gdx.input.setCursorCatched(false);
		this.pausedScreen = pausedScreen;

		TextItem gameOverTextItem = new TextItem("Game Over");
		gameOverTextItem.setColor(Color.WHITE);
		gameOverTextItem.setX((Gdx.graphics.getWidth() - gameOverTextItem.getWidth()) / 2f);
		gameOverTextItem.setY(Gdx.graphics.getHeight() - Gdx.graphics.getHeight() / 6f);
		stage.addActor(gameOverTextItem);

		TextItem scoreTextItem = new TextItem("Score: 10000");
		scoreTextItem.setColor(Color.WHITE);
		scoreTextItem.setX((Gdx.graphics.getWidth() - scoreTextItem.getWidth()) / 2f);
		scoreTextItem.setY(gameOverTextItem.getY() - scoreTextItem.getHeight() * 1.5f);
		stage.addActor(scoreTextItem);

		backdrop = new Backdrop();
		backdrop.setWidth(Gdx.graphics.getWidth());
		backdrop.setHeight(TextItem.getHeight("Quit") * 4f);
		backdrop.setX(0);
		backdrop.setY(Gdx.graphics.getHeight() / 2f - backdrop.getHeight() / 2f);
		Tween.from(backdrop,  ActorAccessor.SIZE_H, 0.5f)
				.target(0f)
				.ease(Expo.OUT)
				.start(getTweenManager());
		backdrop.setActCallback(new ItemCallback() {

			@Override
			public void execute(Item data) {
				data.setY(Gdx.graphics.getHeight() / 2f - data.getHeight() / 2f);
			}

		});
		stage.addActor(backdrop);
		
		Menu menu = new ListMenu();
		menu.setX(Gdx.graphics.getWidth() / 2);
		menu.setY(Gdx.graphics.getHeight() / 2);
		traversal.menus.add(menu);

		TextItem textItem = new TextItem("Quit");
		textItem.setCallback(new ItemCallback() {

			@Override
			public void execute(Item data) {
				quit();
			}
			
		});
		menu.add(textItem);
		Tween.from(textItem, ActorAccessor.POSITION_X, 0.75f)
				.target(-textItem.getWidth())
				.ease(TweenEquations.easeOutExpo)
				.start(getTweenManager());
		stage.addActor(textItem);
		
		menu.setY((Gdx.graphics.getHeight() - textItem.getHeight()) / 2);
		menu.cleanup();
		
		stage.addActor(menu);
	}
	
	@Override
	protected void registerInputProcessors() {
		getInputMultiplexer().addProcessor(new InputAdapter() {
			
			@Override
			public boolean keyDown(int keycode) {
				switch(keycode) {
				case Keys.ESCAPE:
				case Keys.BACK:
					game.setScreen(pausedScreen);
					break;
				}
				return false;
			}
			
		});
	}
	
	private void back() {
		game.setScreen(pausedScreen);
	}

	private void quit() {
		pausedScreen.dispose();
		game.setScreen(new MainMenuScreen(game));
	}
	
	@Override
	public void render(float delta) {
		pausedScreen.draw(0);
		super.render(delta);
	}
	
	@Override
	public void renderClearScreen(float delta) {
		// So we don't clear the screen each frame, we let the pausdScreens .draw() method do that.
	}
	
	private float oldVolume;
	
	@Override
	public void show() {
		super.show();
		oldVolume = MusicHandler.getVolume();
		MusicHandler.setVolume(0.25f);
		Timer.instance().stop();
	}
	
	@Override
	public void hide() {
		super.hide();
		MusicHandler.setVolume(oldVolume);
		Timer.instance().start();
		dispose();
	}
	
}
