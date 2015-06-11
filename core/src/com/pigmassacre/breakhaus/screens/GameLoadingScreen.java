package com.pigmassacre.breakhaus.screens;

import aurelienribon.tweenengine.*;
import com.badlogic.gdx.Gdx;
import com.pigmassacre.breakhaus.Assets;
import com.pigmassacre.breakhaus.Breakhaus;
import com.pigmassacre.breakhaus.Settings;
import com.pigmassacre.breakhaus.gui.Accessors.ActorAccessor;
import com.pigmassacre.breakhaus.gui.Logo;
import com.pigmassacre.breakhaus.gui.Sunrays;
import com.pigmassacre.breakhaus.gui.TextItem;

public class GameLoadingScreen extends AbstractScreen {

	private final Logo logo;
	private final Sunrays sunrays;
	
	private final TextItem loadingTextItem;
	
	public GameLoadingScreen(Breakhaus game, Logo givenLogo, Sunrays givenSunrays) {
		super(game);
		
		Gdx.input.setCursorCatched(!Settings.getDebugMode());
		
		if (givenSunrays == null) {
			sunrays = new Sunrays();
		} else {
			sunrays = givenSunrays;
		}
		stage.addActor(sunrays);
		
		if (givenLogo == null) {
			logo = new Logo();
			logo.setX((Gdx.graphics.getWidth() - logo.getWidth()) / 2);
			logo.setY(Gdx.graphics.getHeight() / 2 - logo.getHeight() / 2 + Settings.getLevelYOffset() + logo.getHeight() / 6);
		} else {
			logo = givenLogo;
		}
		sunrays.attachTo(logo, 0, -logo.getHeight() / 6);
		stage.addActor(logo);
		
		loadingTextItem = new TextItem("Now Loading");
		loadingTextItem.setColor(1f, 1f, 1f, 1f);
		loadingTextItem.setX((Gdx.graphics.getWidth() - loadingTextItem.getWidth()) / 2);
		loadingTextItem.setY(logo.getY() - loadingTextItem.getHeight());
		stage.addActor(loadingTextItem);
		
		Assets.loadGameAssets();
	}
	
	private boolean finishedLoading = false, finishedTweening = false;
	
	@Override
	public void render(float delta) {
		super.render(delta);
		
		if (Assets.getAssetManager().update() && !finishedLoading) {
			sunrays.removeTarget();
			Timeline.createSequence()
				.push(Tween.to(logo, ActorAccessor.POSITION_Y, 0.5f).target(Gdx.graphics.getHeight() + logo.getHeight()).ease(TweenEquations.easeInExpo))
				.setCallback(new TweenCallback() {
					
					@Override
					public void onEvent(int type, BaseTween<?> source) {
						finishedTweening = true;
					}
					
				})
				.start(getTweenManager());
			loadingTextItem.remove();
			finishedLoading = true;
		}
		
		if (!finishedLoading) {
			loadingTextItem.setText("Now Loading " + (int) (Assets.getAssetManager().getProgress() * 100) + "%");
			loadingTextItem.setX((Gdx.graphics.getWidth() - loadingTextItem.getWidth()) / 2);
		}
	}

	@Override
	public void postRender(float delta) {
		if (finishedTweening) {
			game.setScreen(new GameScreen(game, sunrays));
			dispose();
		}
	}
	
}
