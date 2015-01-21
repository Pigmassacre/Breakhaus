package com.pigmassacre.breakhaus.screens;

import aurelienribon.tweenengine.Tween;
import aurelienribon.tweenengine.TweenEquations;
import aurelienribon.tweenengine.equations.Expo;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input.Keys;
import com.badlogic.gdx.InputAdapter;
import com.badlogic.gdx.graphics.g2d.BitmapFont.HAlignment;
import com.pigmassacre.breakhaus.Breakhaus;
import com.pigmassacre.breakhaus.MusicHandler;
import com.pigmassacre.breakhaus.gui.*;
import com.pigmassacre.breakhaus.gui.Item.ItemCallback;

public class ToastScreen extends AbstractScreen {
	
	private final AbstractScreen pausedScreen;
	
	Backdrop backdrop;
	TextItem messageTextItem, okTextItem;
	
	public ToastScreen(Breakhaus game, AbstractScreen pausedScreen, String message) {
		super(game);
		this.pausedScreen = pausedScreen;
		
		backdrop = new Backdrop();
		backdrop.setWidth(Gdx.graphics.getWidth());
		backdrop.setHeight(TextItem.getHeight(message, true) + TextItem.getHeight("Bounds") * 4f);
		backdrop.setX(0);
		backdrop.setY(Gdx.graphics.getHeight() / 2f - backdrop.getHeight() / 2f);
		Tween.from(backdrop,  ActorAccessor.SIZE_H, 0.5f).target(0.01f).ease(Expo.OUT).start(getTweenManager());
		backdrop.setActCallback(new ItemCallback() {
			
			@Override
			public void execute(Item data) {
				data.setY(Gdx.graphics.getHeight() / 2f - data.getHeight() / 2f);
			}
			
		});
		stage.addActor(backdrop);
		
		
		messageTextItem = new TextItem(message);
		messageTextItem.setAlignment(HAlignment.CENTER);
		messageTextItem.setWrapped(true);
		messageTextItem.setColor(0.9f, 0.25f, 0.25f, 1f);
		stage.addActor(messageTextItem);

		Menu menu = new ListMenu();
		traversal.menus.add(menu);
		
		okTextItem = new TextItem("Ok");
		okTextItem.setSelected(true);
		okTextItem.setCallback(new ItemCallback() {

			@Override
			public void execute(Item data) {
				back();
			}
			
		});
		
		Tween.from(okTextItem, ActorAccessor.POSITION_X, 0.75f).target(Gdx.graphics.getWidth()
				).ease(TweenEquations.easeOutExpo).start(getTweenManager());
		stage.addActor(okTextItem);
		menu.add(okTextItem);
		
		messageTextItem.setX((Gdx.graphics.getWidth() - messageTextItem.getWrapWidth()) / 2f);
		messageTextItem.setY((Gdx.graphics.getHeight()) / 2 + messageTextItem.getHeight() / 2f + okTextItem.getHeight());
		Tween.from(messageTextItem, ActorAccessor.POSITION_X, 0.75f).target(-messageTextItem.getWidth()).ease(TweenEquations.easeOutExpo).start(getTweenManager());
		
		menu.setX(Gdx.graphics.getWidth() / 2);
		menu.setY(messageTextItem.getY() - messageTextItem.getHeight());
		menu.setY(menu.getY() - okTextItem.getHeight() * 2f);
		
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
	}
	
	@Override
	public void hide() {
		super.hide();
		MusicHandler.setVolume(oldVolume);
		dispose();
	}
	
}
