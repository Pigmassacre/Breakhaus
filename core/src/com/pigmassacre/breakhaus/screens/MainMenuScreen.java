package com.pigmassacre.breakhaus.screens;

import aurelienribon.tweenengine.Tween;
import aurelienribon.tweenengine.TweenEquations;
import aurelienribon.tweenengine.equations.Expo;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input.Keys;
import com.badlogic.gdx.InputAdapter;
import com.pigmassacre.breakhaus.Breakhaus;
import com.pigmassacre.breakhaus.MusicHandler;
import com.pigmassacre.breakhaus.Settings;
import com.pigmassacre.breakhaus.gui.*;
import com.pigmassacre.breakhaus.gui.Item.ItemCallback;

public class MainMenuScreen extends AbstractScreen {
	
	Logo logo;
	Sunrays sunrays;
	
	public MainMenuScreen(Breakhaus game) {
		this(game, null, null);
		if (lastTextureRegion != null) {
			Blinder blinder = new Blinder(lastTextureRegion, stage, getTweenManager());
			stage.addActor(blinder);
		}
	}
	
	public MainMenuScreen(Breakhaus game, Logo givenLogo, Sunrays givenSunrays) {
		super(game);
		
		if (givenSunrays == null) {
			sunrays = new Sunrays();
		} else {
			sunrays = givenSunrays;
		}
		stage.addActor(sunrays);
		
		if (givenLogo == null) {
			logo = new Logo();
			logo.setX((Gdx.graphics.getWidth() - logo.getWidth()) / 2);
			logo.setY(Gdx.graphics.getHeight() + logo.getHeight());
		} else {
			logo = givenLogo;
		}
		stage.addActor(logo);
		Tween.to(logo, ActorAccessor.POSITION_XY, 0.5f).target(logo.getX(), (Gdx.graphics.getHeight() / 2) + logo.getHeight() * 0.75f)
			.ease(TweenEquations.easeOutExpo)
			.start(getTweenManager());
		
		sunrays.attachTo(logo, 0, -logo.getHeight() / 6);
		
		Menu menu = new ListMenu();
		menu.setX(Gdx.graphics.getWidth() / 2);
		menu.setY(Gdx.graphics.getHeight() / 2);
		traversal.menus.add(menu);
		
		TextItem textItem;
		textItem = new TextItem("Start");
		textItem.setSelected(true);
		textItem.setCallback(new ItemCallback() {

			@Override
			public void execute(Item data) {
				startPrepareMenu(); 
			}
			
		});
		menu.add(textItem);
		Tween.from(textItem, ActorAccessor.POSITION_X, 0.75f).target(Gdx.graphics.getWidth()).ease(Expo.OUT).start(getTweenManager());
		stage.addActor(textItem);

		textItem = new TextItem("Quit");
		textItem.setCallback(new ItemCallback() {

			@Override
			public void execute(Item data) {
				quit();
			}
			
		});
		menu.add(textItem);
		Tween.from(textItem, ActorAccessor.POSITION_X, 0.75f).target(-textItem.getWidth(), textItem.getY()).ease(TweenEquations.easeOutExpo).start(getTweenManager());
		stage.addActor(textItem);
		
		stage.addActor(menu);
		
		if (!MusicHandler.isPlaying()) {
			MusicHandler.setSong("music/title/goluigi-nonuniform.ogg");
			MusicHandler.setLooping(true);
			MusicHandler.play();
		}
	}
	
	@Override
	protected void registerInputProcessors() {
		getInputMultiplexer().addProcessor(new InputAdapter() {
			
			@Override
			public boolean keyDown(int keycode) {
				switch(keycode) {
				case Keys.BACK:
					for (Menu menu : traversal.menus) {
						if (menu.items.get(menu.items.size() - 1).getSelected()) {
							quit();
							break;
						}
					}
				case Keys.ESCAPE:
					for (Menu menu : traversal.menus) {
						for (Item item : menu.items){
							item.setSelected(false);
						}
						menu.items.get(menu.items.size() - 1).setSelected(true);
						break;
					}
					break;
				}
				return false;
			}
			
		});
	}

	public void startPrepareMenu() {
		game.setScreen(new GameLoadingScreen(game, logo, sunrays));
	}
	
	public void quit() {
		Settings.savePreferences();
		Gdx.app.exit();
	}
	
	@Override
	public void hide() {
		super.hide();
		dispose();
	}
	
}
