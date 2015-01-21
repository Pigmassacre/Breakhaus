package com.pigmassacre.breakhaus.screens;

import aurelienribon.tweenengine.*;
import aurelienribon.tweenengine.equations.Expo;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input.Keys;
import com.badlogic.gdx.InputAdapter;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.math.Rectangle;
import com.badlogic.gdx.scenes.scene2d.Actor;
import com.badlogic.gdx.utils.Array;
import com.badlogic.gdx.utils.SnapshotArray;
import com.badlogic.gdx.utils.Timer;
import com.pigmassacre.breakhaus.*;
import com.pigmassacre.breakhaus.gui.*;
import com.pigmassacre.breakhaus.gui.Item.ItemCallback;
import com.pigmassacre.breakhaus.objects.*;

public class GameScreen extends AbstractScreen {

	Player leftPlayer, rightPlayer;
	Paddle leftPaddle, rightPaddle;
	
	Sunrays sunrays;
	
	float oldSpeed;
	
	public GameScreen(Breakhaus game, Sunrays givenSunrays) {
		super(game);
		
		if (givenSunrays == null) {
			sunrays = new Sunrays();
		} else {
			sunrays = givenSunrays;
		}
		sunrays.setX(Gdx.graphics.getWidth() / 2 - sunrays.getWidth() / 2);
		sunrays.setY(Gdx.graphics.getHeight() / 2 - sunrays.getHeight() / 2);
		sunrays.offsetY = Settings.getLevelYOffset();
		stage.addActor(sunrays);
		
		Settings.LEVEL_WIDTH = Assets.getTextureRegion("glass/floor").getRegionWidth() * Settings.GAME_SCALE;
		Settings.LEVEL_HEIGHT = Assets.getTextureRegion("glass/floor").getRegionHeight() * Settings.GAME_SCALE;
		Settings.LEVEL_X = (Gdx.graphics.getWidth() - Settings.LEVEL_WIDTH) / 2f;
		Settings.LEVEL_Y = (Gdx.graphics.getHeight() - Settings.LEVEL_HEIGHT) / 2f;
		Settings.LEVEL_MAX_X = Settings.LEVEL_X + Settings.LEVEL_WIDTH;
		Settings.LEVEL_MAX_Y = Settings.LEVEL_Y + Settings.LEVEL_HEIGHT;
		
		Level.setCurrentLevel("glass");
		
		leftPlayer = new Player("left");
		leftPlayer.setX(2.5f * Settings.GAME_SCALE);
		leftPlayer.setY(2.5f * Settings.GAME_SCALE);
		leftPlayer.setColor(GameOptions.getLeftColor());
		Groups.playerGroup.addActor(leftPlayer);
		
		float delay = 0.25f;
		float z;
		Block tempBlock = new Block(0, 0, new Player("temp"), new Color(Color.BLACK));
		for (int x = 0; x < 3; x++) {
			for (int y = 0; y < (int) Settings.LEVEL_HEIGHT / tempBlock.getHeight(); y++) {
				Block block = new Block(Settings.LEVEL_X + x * tempBlock.getWidth(), Settings.LEVEL_MAX_Y - tempBlock.getHeight() - (y * tempBlock.getHeight()), leftPlayer,
						leftPlayer.getColor());
				z = block.getZ();
				block.setZ(350 * Settings.GAME_SCALE);
				Tween.to(block, GameActorAccessor.Z, 2f)
					.target(z)
					.ease(TweenEquations.easeOutExpo)
					.delay(delay)
					.start(getTweenManager());
				delay += 0.025f;
			}
		}
		
		leftPaddle = new Paddle(leftPlayer);
		leftPaddle.setX(Settings.LEVEL_X + leftPaddle.getWidth() * 4);
		leftPaddle.setY((Gdx.graphics.getHeight() - leftPaddle.getHeight()) / 2);
		leftPaddle.touchRectangle = new Rectangle(0, 0, Gdx.graphics.getWidth() / 2, Gdx.graphics.getHeight());
		leftPaddle.keyLeft = Keys.W;
		leftPaddle.keyRight = Keys.S;

		z = leftPaddle.getZ();
		leftPaddle.setZ(1000);
		Tween.to(leftPaddle, GameActorAccessor.Z, 2f)
			.target(z)
			.ease(TweenEquations.easeOutExpo)
			.delay(delay + 0.025f)
			.start(getTweenManager());

		rightPlayer = new Player("right");
		rightPlayer.setX(Gdx.graphics.getWidth() - 5f * Settings.GAME_SCALE - 2.5f * Settings.GAME_SCALE);
		rightPlayer.setY(Gdx.graphics.getHeight() - 5f * Settings.GAME_SCALE - 2.5f * Settings.GAME_SCALE);
		rightPlayer.setColor(GameOptions.getRightColor());
		Groups.playerGroup.addActor(rightPlayer);
		
		delay = 0.25f;
		for (int x = 0; x < 3; x++) {
			for (int y = 0; y < (int) Settings.LEVEL_HEIGHT / tempBlock.getHeight(); y++) {
				Block block = new Block(Settings.LEVEL_MAX_X - ((x + 1) * tempBlock.getWidth()), Settings.LEVEL_MAX_Y - tempBlock.getHeight() - (y * tempBlock.getHeight()),
						rightPlayer, rightPlayer.getColor());
				z = block.getZ();
				block.setZ(350 * Settings.GAME_SCALE);
				Tween.to(block, GameActorAccessor.Z, 2f)
					.target(z)
					.ease(TweenEquations.easeOutExpo)
					.delay(delay)
					.start(getTweenManager());
				delay += 0.025f;
			}
		}
		
		rightPaddle = new Paddle(rightPlayer);
		rightPaddle.setX(Settings.LEVEL_MAX_X - rightPaddle.getWidth() * 5);
		rightPaddle.setY((Gdx.graphics.getHeight() - rightPaddle.getHeight()) / 2);

		rightPaddle.touchRectangle = new Rectangle(Gdx.graphics.getWidth() / 2, 0, Gdx.graphics.getWidth() / 2, Gdx.graphics.getHeight());
		rightPaddle.keyLeft = Keys.UP;
		rightPaddle.keyRight = Keys.DOWN;
		
		z = rightPaddle.getZ();
		rightPaddle.setZ(1000);
		Tween.to(rightPaddle, GameActorAccessor.Z, 2f)
			.target(z)
			.ease(TweenEquations.easeOutExpo)
			.delay(delay + 0.025f)
			.start(getTweenManager());

		tempBlock.destroy(false);
		
		Ball ball = Ball.ballPool.obtain();
		
		Player startingPlayer;
		float angle;
		if (MathUtils.randomBoolean()) {
			startingPlayer = leftPlayer;
			angle = MathUtils.PI;
		} else {
			startingPlayer = rightPlayer;
			angle = 0f;
		}
		
		ball.init(Settings.LEVEL_X + (Settings.LEVEL_WIDTH - ball.getWidth()) / 2, Settings.LEVEL_Y + (Settings.LEVEL_HEIGHT - ball.getHeight()) / 2, angle, startingPlayer);
		oldSpeed = ball.speed;
		ball.speed = 0f;
		z = ball.getZ();
		ball.setZ(1000);
		Tween.to(ball, GameActorAccessor.Z, 2f)
			.target(z)
			.ease(TweenEquations.easeOutExpo)
			.delay(delay + 1.25f)
			.setUserData(ball)
			.setCallback(new TweenCallback() {
				
				@Override
				public void onEvent(int type, BaseTween<?> source) {
					startGameCountdown((Ball) source.getUserData());
				}
				
			})
			.start(getTweenManager());
		
		MusicHandler.stop();
		MusicHandler.addSong("music/game/choke.ogg", "choke");
		MusicHandler.addSong("music/game/divine_intervention.ogg", "Divine Intervention");
		MusicHandler.addSong("music/game/socialmoron.ogg", "Social Moron");
		MusicHandler.addSong("music/game/stardstm.ogg", "stardust memories");
		MusicHandler.setShuffle(true);
		MusicHandler.play();
		
		stage.addActor(Level.getCurrentLevel().getBackground());
		stage.addActor(Groups.playerGroup);
		stage.addActor(Groups.residueGroup);
		stage.addActor(Groups.shadowGroup);
		stage.addActor(Groups.traceGroup);
		stage.addActor(Groups.blockGroup);
		stage.addActor(Groups.powerupGroup);
		stage.addActor(Groups.ballGroup);
		stage.addActor(Groups.paddleGroup);
		stage.addActor(Groups.particleGroup);
		stage.addActor(Level.getCurrentLevel().getForeground());
		stage.addActor(Groups.textItemGroup);
	}
	
	private Array<TextItem> countdownTextItems;
	
	protected void startGameCountdown(Ball ball) {
		countdownTextItems = new Array<TextItem>();
		int countdown = 3;
		float angle = - MathUtils.PI / 2f;
		float angleOffset = 16 * Settings.GAME_SCALE;
		Timeline timeline = Timeline.createSequence();
		for (int i = countdown; i > 0; i--) {
			TextItem countdownTextItem = new TextItem(String.valueOf(i));
			countdownTextItem.setColor(1f, 1f, 1f, 1f);
			float x = Gdx.graphics.getWidth() / 2 - countdownTextItem.getWidth() / 2 + MathUtils.cos(angle) * angleOffset;
			float y = Gdx.graphics.getHeight() / 2 - countdownTextItem.getHeight() / 2 + MathUtils.sin(angle) * angleOffset + countdownTextItem.getHeight();
			countdownTextItem.setX(x + MathUtils.cos(angle) * (Gdx.graphics.getWidth() - countdownTextItem.getX()));
			countdownTextItem.setY(y + MathUtils.sin(angle) * (Gdx.graphics.getHeight() - countdownTextItem.getY()));
			timeline.push(Tween.to(countdownTextItem, ActorAccessor.POSITION_XY, 0.4f)
						.target(x, y)
						.ease(Expo.OUT));
			angle += MathUtils.PI2 / 3f;
			countdownTextItems.add(countdownTextItem);
			stage.addActor(countdownTextItem);
		}
		
		timeline.pushPause(0.1f);
		
		timeline.beginParallel();
		
		for (TextItem countdownTextItem : countdownTextItems) {
			timeline.push(Tween.to(countdownTextItem, ActorAccessor.POSITION_XY, 0.5f)
						.target(countdownTextItem.getX(), countdownTextItem.getY())
						.ease(Expo.OUT)
						.setUserData(countdownTextItem)
						.setCallback(new TweenCallback() {
					
							@Override
							public void onEvent(int type, BaseTween<?> source) {
								((TextItem) source.getUserData()).remove();
							}
							
						}));
		}
		
		TextItem goTextItem = new TextItem("GO");
		goTextItem.setColor(1f, 1f, 1f, 0f);
		goTextItem.setScale(0.1f * Settings.GAME_SCALE);
		goTextItem.setX(Gdx.graphics.getWidth() / 2 - goTextItem.getWidth() / 2);
		goTextItem.setY(Gdx.graphics.getHeight() / 2 - goTextItem.getHeight() / 2 + goTextItem.getHeight());
		goTextItem.setActCallback(new ItemCallback() {
			
			@Override
			public void execute(Item data) {
				data.setX(Gdx.graphics.getWidth() / 2 - data.getWidth() / 2);
				data.setY(Gdx.graphics.getHeight() / 2 - data.getHeight() / 2 + data.getHeight());
			}
			
		});
		stage.addActor(goTextItem);
		
		timeline.beginSequence();
		
		timeline.beginParallel();
		timeline.push(Tween.to(goTextItem, ActorAccessor.SCALE_XY, 0.2f)
							.target(5f * Settings.GAME_SCALE, 5f * Settings.GAME_SCALE)
							.ease(Expo.OUT));
		timeline.push(Tween.to(goTextItem, ActorAccessor.ALPHA, 0.2f)
				.target(1f)
				.ease(Expo.OUT));
		timeline.end();
		
		timeline.pushPause(0.25f);
		
		timeline.beginParallel();
		timeline.push(Tween.to(goTextItem, ActorAccessor.SCALE_XY, 0.2f)
				.target(0.25f, 0.25f)
				.ease(Expo.IN));
		timeline.push(Tween.to(goTextItem, ActorAccessor.ALPHA, 0.2f)
				.target(0f)
				.ease(Expo.IN)
				.setUserData(goTextItem)
				.setCallback(new TweenCallback() {
			
					@Override
					public void onEvent(int type, BaseTween<?> source) {
						((TextItem) source.getUserData()).remove();
					}
					
				}));
		timeline.end();
		
		timeline.end();
		
		timeline.pushPause(0.25f);
		
		timeline.end();
		timeline.setUserData(ball);
		timeline.setCallback(new TweenCallback() {
			
			@Override
			public void onEvent(int type, BaseTween<?> source) {
				((Ball) source.getUserData()).speed = oldSpeed;
			}
			
		});
		timeline.start(getTweenManager());
	}

	@Override
	public void renderClearScreen(float delta) {
		float leftPlayerBlockCount = 0, rightPlayerBlockCount = 0;
		SnapshotArray<Actor> array = Groups.blockGroup.getChildren();
		Object[] items = array.begin();
		for (int i = 0, n = array.size; i < n; i++) {
			Object item = items[i];
			Block block = (Block) item;
			if (block.owner == leftPlayer) {
				leftPlayerBlockCount++;
			} else {
				rightPlayerBlockCount++;
			}
		}
		array.end();
		
		float strength = 0;
		Player winningPlayer = null;
		if (leftPlayerBlockCount > rightPlayerBlockCount) {
			strength = (leftPlayerBlockCount - rightPlayerBlockCount) / (leftPlayerBlockCount + rightPlayerBlockCount);
			winningPlayer = leftPlayer;
		} else if (leftPlayerBlockCount < rightPlayerBlockCount) {
			strength = (rightPlayerBlockCount - leftPlayerBlockCount) / (leftPlayerBlockCount + rightPlayerBlockCount);
			winningPlayer = rightPlayer;
		} else {
			backgroundColor.lerp(leftPlayer.getColor().cpy().mul(0.5f).add(rightPlayer.getColor().cpy().mul(0.5f)), 0.05f);
		}
		
		if (winningPlayer != null) {
			backgroundColor.lerp(winningPlayer.getColor().cpy().mul(strength, strength, strength, 1f).add(winningPlayer.getColor().cpy().mul(0.25f)), 0.05f);
		}
		
		super.renderClearScreen(delta);
	}
	
	@Override
	public void act(float delta) {
		super.act(delta);
		Level.getCurrentLevel().act(delta);
	}
	
	@Override
	public void show() {
		Gdx.input.setCursorCatched(!Settings.getDebugMode());
		getInputMultiplexer().clear();
		getInputMultiplexer().addProcessor(new InputAdapter() {

			@Override
			public boolean keyDown(int keycode) {
				switch (keycode) {
				case Keys.ESCAPE:
				case Keys.BACK:
					back();
					break;
				}
				return false;
			}

		});
		getInputMultiplexer().addProcessor(new DebugInput(this, stage));
		super.show();
	}

	private void back() {
		game.setScreen(new PauseScreen(game, this));
	}
	
	@Override
	public void pause() {
		super.pause();
		back();
	}

	@Override
	public void dispose() {
		super.dispose();
		Groups.playerGroup.clear();
		Groups.ballGroup.clear();
		Groups.traceGroup.clear();
		Groups.paddleGroup.clear();
		Groups.blockGroup.clear();
		Groups.shadowGroup.clear();
		Groups.residueGroup.clear();
		Groups.powerupGroup.clear();
		Groups.particleGroup.clear();
		Groups.textItemGroup.clear();
		MusicHandler.stop();
		Assets.unloadGameAssets();
		Timer.instance().clear();
		Gdx.input.setCursorCatched(false);
	}

}
