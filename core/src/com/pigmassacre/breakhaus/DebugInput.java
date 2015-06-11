package com.pigmassacre.breakhaus;

import aurelienribon.tweenengine.*;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input.Buttons;
import com.badlogic.gdx.Input.Keys;
import com.badlogic.gdx.InputAdapter;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.math.Rectangle;
import com.badlogic.gdx.math.Vector3;
import com.badlogic.gdx.scenes.scene2d.Actor;
import com.badlogic.gdx.scenes.scene2d.Stage;
import com.badlogic.gdx.utils.SnapshotArray;
import com.pigmassacre.breakhaus.gui.Accessors.ActorAccessor;
import com.pigmassacre.breakhaus.gui.Item;
import com.pigmassacre.breakhaus.gui.Item.ItemCallback;
import com.pigmassacre.breakhaus.gui.TextItem;
import com.pigmassacre.breakhaus.objects.Ball;
import com.pigmassacre.breakhaus.objects.Groups;
import com.pigmassacre.breakhaus.objects.Player;
import com.pigmassacre.breakhaus.objects.powerups.Powerup;
import com.pigmassacre.breakhaus.screens.AbstractScreen;

public class DebugInput extends InputAdapter {

	private final AbstractScreen screen;
	private final Stage stage;
	
	private final Rectangle rectangle;
	private final Player player;
	
	public DebugInput(AbstractScreen screen, Stage stage, Player player) {
		this.screen = screen;
		this.stage = stage;
		this.player = player;
		rectangle = new Rectangle(Settings.LEVEL_X, Settings.LEVEL_Y, Settings.LEVEL_WIDTH, Settings.LEVEL_HEIGHT);
		if (Settings.getDebugMode()) {
			showFPSCounter();
		}
	}
	
	@Override
	public boolean touchDown(int screenX, int screenY, int pointer, int button) {
		if (Settings.getDebugMode()) {
			Vector3 coords = new Vector3(screenX, screenY, 0);
			stage.getCamera().unproject(coords);
			if (stage != null && (pointer == 0 || button == Buttons.LEFT) && rectangle.contains(coords.x, coords.y)) {
				Ball ball = Ball.ballPool.obtain();
				ball.init(coords.x, coords.y, (float) (MathUtils.random() * 2 * Math.PI), player);
			}
		}
		return false;
	}
	
	@Override
	public boolean keyDown(int keycode) {
		switch(keycode) {
		case Keys.F3:
			Settings.setDebugMode(!Settings.getDebugMode());
			
			if (Settings.getDebugMode()) {
				createDebugMessage("Debug Mode ON");
				Gdx.input.setCursorCatched(false);
				showFPSCounter();
			} else {
				createDebugMessage("Debug Mode OFF");
				Gdx.input.setCursorCatched(true);
				hideFPSCounter();
			}
			
			break;
		case Keys.R:
			if (Settings.getDebugMode()) {
				SnapshotArray<Actor> array = Groups.ballGroup.getChildren();
				Actor[] items = array.begin();
				for (int i = 0, n = array.size; i < n; i++) {
					((Ball) items[i]).reset();
				}
				array.end();
			}
			break;
		case Keys.O:
			if (Settings.getDebugMode()) {
				SnapshotArray<Actor> array = Groups.powerupGroup.getChildren();
				Object[] items = array.begin();
				for (int i = 0, n = array.size; i < n; i++) {
					Powerup powerup = (Powerup) items[i];
					powerup.destroy();
				}
				array.end();
			}
			break;
		case Keys.M:
			if (Settings.getDebugMode()) {
				if (Gdx.input.isKeyPressed(Keys.SHIFT_LEFT)) {
					screen.timeScale += 1f;
				} else {
					screen.timeScale += 0.1f;
				}
				createDebugMessage("Set timescale to " + screen.timeScale);
			}
			break;
		case Keys.N:
			if (Settings.getDebugMode()) {
				if (Gdx.input.isKeyPressed(Keys.SHIFT_LEFT)) {
					screen.timeScale -= 1f;
				} else {
					screen.timeScale -= 0.1f;
				}
				createDebugMessage("Set timescale to " + screen.timeScale);
			}
			break;
		case Keys.B:
			if (Settings.getDebugMode()) {
				screen.timeScale = 1f;
				createDebugMessage("Reset timescale to " + screen.timeScale);
			}
			break;
		case Keys.Z:
			if (Settings.getDebugMode()) {
				MusicHandler.prev();
				createDebugMessage("Now Playing: " + MusicHandler.getNameOfCurrentSong());
			}
			break;
		case Keys.X:
			if (Settings.getDebugMode()) {
				MusicHandler.next();
				createDebugMessage("Now Playing: " + MusicHandler.getNameOfCurrentSong());
			}
			break;
		}
		return true;
	}
	
	private static TextItem debugTextItem;
	private static Timeline debugTextSequence;
	
	private void createDebugMessage(CharSequence string) {
		if (debugTextItem != null) {
			debugTextItem.remove();
		}
		if (debugTextSequence != null) {
			debugTextSequence.free();
		}
		
		debugTextItem = new TextItem(string);
		debugTextItem.setScale(debugTextItem.getScaleX() * 0.75f, debugTextItem.getScaleY() * 0.75f);
		debugTextItem.setColor(1f, 1f, 1f, 0.75f);
		debugTextItem.setX((stage.getWidth() - debugTextItem.getWidth()) / 2);
		debugTextItem.setY(stage.getHeight() + debugTextItem.getHeight());
		stage.addActor(debugTextItem);

		debugTextSequence = Timeline.createSequence()
			.push(Tween.to(debugTextItem, ActorAccessor.POSITION_Y, 2f)
					.target(stage.getHeight() - 2f * debugTextItem.getScaleY())
					.ease(TweenEquations.easeOutExpo))
			.pushPause(0.25f)
			.push(Tween.to(debugTextItem, ActorAccessor.POSITION_Y, 2f)
					.target(stage.getHeight() + debugTextItem.getHeight())
					.ease(TweenEquations.easeInExpo))
					.setCallback(new TweenCallback() {
						
						@Override
						public void onEvent(int type, BaseTween<?> source) {
							debugTextItem.remove();
						}
						
					})
			.start(screen.getTweenManager());
	}
	
	private static TextItem fpsCounterTextItem;
	
	private void showFPSCounter() {
		if (fpsCounterTextItem == null) {
			fpsCounterTextItem = new TextItem(Integer.toString(Gdx.graphics.getFramesPerSecond()));
			fpsCounterTextItem.setColor(1f, 1f, 1f, 0.75f);
			fpsCounterTextItem.setX(4 * Settings.GAME_SCALE);
			fpsCounterTextItem.setY(stage.getHeight() - 2 * Settings.GAME_SCALE);
			fpsCounterTextItem.setActCallback(new ItemCallback() {
				
				@Override
				public void execute(Item data) {
					fpsCounterTextItem.setText(Integer.toString(Gdx.graphics.getFramesPerSecond()));
				}
				
			});
		}
		
		if (!stage.getActors().contains(fpsCounterTextItem, true)) {
			stage.addActor(fpsCounterTextItem);
		}
	}
	
	private void hideFPSCounter() {
		fpsCounterTextItem.remove();
	}
	
}
