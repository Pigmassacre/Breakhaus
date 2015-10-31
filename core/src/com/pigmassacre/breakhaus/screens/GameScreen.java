package com.pigmassacre.breakhaus.screens;

import aurelienribon.tweenengine.*;
import aurelienribon.tweenengine.equations.Expo;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input.Keys;
import com.badlogic.gdx.InputAdapter;
import com.badlogic.gdx.graphics.Camera;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.graphics.g2d.Batch;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.math.Vector3;
import com.badlogic.gdx.scenes.scene2d.Actor;
import com.badlogic.gdx.scenes.scene2d.Group;
import com.badlogic.gdx.scenes.scene2d.Stage;
import com.badlogic.gdx.scenes.scene2d.ui.Table;
import com.badlogic.gdx.scenes.scene2d.ui.Value;
import com.badlogic.gdx.utils.Array;
import com.badlogic.gdx.utils.Scaling;
import com.badlogic.gdx.utils.Timer;
import com.badlogic.gdx.utils.viewport.ScalingViewport;
import com.pigmassacre.breakhaus.*;
import com.pigmassacre.breakhaus.gui.*;
import com.pigmassacre.breakhaus.gui.Accessors.ActorAccessor;
import com.pigmassacre.breakhaus.gui.Accessors.GameActorAccessor;
import com.pigmassacre.breakhaus.gui.Item.ItemCallback;
import com.pigmassacre.breakhaus.objects.*;

public class GameScreen extends AbstractScreen {

	private final TextItem scoreTextItem;
	private final TextItem hitCounterTextItem;

	private final Stage gameStage;
	private final OrthographicCamera camera;

	private final Player player;
	private final Paddle paddle;
	private final Player opposingPlayer;

	private static final float WAVE_LENGTH = 8f;
	private float waveCounter;

	private boolean gameActive;
	
	private final Sunrays sunrays;
	
	private float oldSpeed;

	private final TweenManager scoreTweenManager = new TweenManager();

	public GameScreen(Breakhaus game, Sunrays givenSunrays) {
		super(game);

		scoreTextItem = new TextItem();
		scoreTextItem.setColor(Color.WHITE);
		stage.addActor(scoreTextItem);

		hitCounterTextItem = new TextItem();
		hitCounterTextItem.setColor(Color.WHITE);
		stage.addActor(hitCounterTextItem);

		camera = new OrthographicCamera();
		gameStage = new Stage(new ScalingViewport(Scaling.fillX, Gdx.graphics.getWidth(), Gdx.graphics.getHeight(), camera), game.spriteBatch);
		
		if (givenSunrays == null) {
			sunrays = new Sunrays();
		} else {
			sunrays = givenSunrays;
		}
		sunrays.setX(-sunrays.getWidth() / 2);
		sunrays.setY(-sunrays.getHeight() / 2);
		sunrays.offsetY = Settings.getLevelYOffset();
		gameStage.addActor(sunrays);
		
		Settings.LEVEL_WIDTH = Assets.getTextureRegion("glass/floor").getRegionWidth() * Settings.GAME_SCALE;
		Settings.LEVEL_HEIGHT = Assets.getTextureRegion("glass/floor").getRegionHeight() * Settings.GAME_SCALE;
		Settings.LEVEL_X = -Settings.LEVEL_WIDTH / 2f;
		Settings.LEVEL_Y = -Settings.LEVEL_HEIGHT / 2f;
		Settings.LEVEL_MAX_X = Settings.LEVEL_X + Settings.LEVEL_WIDTH;
		Settings.LEVEL_MAX_Y = Settings.LEVEL_Y + Settings.LEVEL_HEIGHT;

		player = new Player("H.E.N.");
		player.setX(2.5f * Settings.GAME_SCALE);
		player.setY(2.5f * Settings.GAME_SCALE);
		player.setColor(MathUtils.random(), MathUtils.random(), MathUtils.random(), 1f);

		waveCounter = WAVE_LENGTH;
		gameActive = false;

		Level.setCurrentLevel("glass", player);
		Level.getCurrentLevel().setTweenManager(getTweenManager());

		camera.translate(-Gdx.graphics.getWidth() / 2f,
				-Gdx.graphics.getHeight() / 2f);

		opposingPlayer = new Player("Just Blocks");
		opposingPlayer.setColor(MathUtils.random(), MathUtils.random(), MathUtils.random(), 1f);

		float delay = 0.25f;
		float z;
		Block tempBlock = new Block(0, 0, new Player("temp"), new Color(Color.BLACK), null, null);
		for (int x = 0; x < (int) Settings.LEVEL_WIDTH / tempBlock.getWidth(); x++) {
			for (int y = 0; y < 4; y++) {
				Block block = createBlock(
						Settings.LEVEL_X + x * tempBlock.getWidth(),
						Settings.LEVEL_MAX_Y - tempBlock.getHeight() - (y * tempBlock.getHeight()));

				/* Add the block to the block group. */
				Groups.blockGroup.addActor(block);

				/* Tween the z value of the block, making it "rain down" from the sky. */
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
		tempBlock.destroy(false);
		
		paddle = new Paddle(player);
		paddle.setX(Settings.LEVEL_X + (Settings.LEVEL_WIDTH - paddle.getWidth()) / 2f);
		paddle.setY(Settings.LEVEL_Y + Settings.LEVEL_HEIGHT / 8f + -paddle.getHeight() / 2);
		player.setPaddle(paddle);

		z = paddle.getZ();
		paddle.setZ(1000);
		Tween.to(paddle, GameActorAccessor.Z, 2f)
			.target(z)
			.ease(TweenEquations.easeOutExpo)
			.delay(delay + 0.025f)
				.start(getTweenManager());

		Ball ball = Ball.ballPool.obtain();

		float angle = MathUtils.PI / 2f;
		
		ball.init(Settings.LEVEL_X + (Settings.LEVEL_WIDTH - ball.getWidth()) / 2, Settings.LEVEL_Y + (Settings.LEVEL_HEIGHT - ball.getHeight()) / 2, angle, player);
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
		
		gameStage.addActor(Level.getCurrentLevel().getBackground());
		gameStage.addActor(Groups.residueGroup);
		gameStage.addActor(Groups.shadowGroup);
		gameStage.addActor(Groups.traceGroup);
		gameStage.addActor(Groups.blockGroup);
		gameStage.addActor(Groups.powerupGroup);
		gameStage.addActor(Groups.paddleGroup);
		gameStage.addActor(Groups.ballGroup);
		gameStage.addActor(Groups.particleGroup);
		gameStage.addActor(Level.getCurrentLevel().getForeground());
		gameStage.addActor(Groups.textItemGroup);
	}

	private Block createBlock(float x, float y) {
		return new Block(
				x, y,
				opposingPlayer,
				new Color(MathUtils.random(), MathUtils.random(), MathUtils.random(), 1f),
				new GameActor.DestroyCallback() {
					@Override
					public void execute(GameActor actor, Object data) {
						addScore(25, actor);
					}
				}, null);
	}

	private void addScore(final int score, GameActor startActor) {
		/* Create the TextItem to display the gained score. */
		Vector3 pos = gameStage.getCamera().project(new Vector3(startActor.getX(), startActor.getY(), 0));
		final TextItem scoreItem = new TextItem(String.valueOf(score));
		scoreItem.setX(pos.x + (startActor.getWidth() - scoreItem.getWidth()) / 2f);
		scoreItem.setY(pos.y + (startActor.getHeight() - scoreItem.getHeight()) / 2f + scoreItem.getHeight() * 2f);
		//scoreItem.setX((Gdx.graphics.getWidth() - scoreItem.getWidth()) / 2f);
		//scoreItem.setY((Gdx.graphics.getHeight() - scoreItem.getHeight()) / 2f);
		scoreItem.setColor(Color.WHITE);
		scoreItem.getColor().a = 0f;
		stage.addActor(scoreItem);

		/* Create a timeline that animates the movement from the destroyed block to the score item. */
		Timeline.createSequence()
				.beginParallel()
				.push(Tween.to(scoreItem, ActorAccessor.ALPHA, 0.25f)
						.target(0.8f)
						.ease(TweenEquations.easeOutExpo))
				.push(Tween.to(scoreItem, ActorAccessor.POSITION_XY, 1f)
						.target(scoreTextItem.getX() + (scoreTextItem.getWidth() - scoreItem.getWidth()) / 2f,
								scoreTextItem.getY() + (scoreTextItem.getHeight() - scoreItem.getHeight()) / 2f)
						.ease(TweenEquations.easeInOutQuart))
				.push(Timeline.createSequence()
						.pushPause(0.5f)
						.push(Tween.to(scoreItem, ActorAccessor.ALPHA, 0.25f)
								.target(0f)
								.ease(TweenEquations.easeInOutExpo))
						.setCallback(new TweenCallback() {
							@Override
							public void onEvent(int i, BaseTween<?> baseTween) {
								player.addScore(score);
							}
						})
						.setCallbackTriggers(TweenCallback.COMPLETE))
				.end()
				.setCallback(new TweenCallback() {
					@Override
					public void onEvent(int i, BaseTween<?> baseTween) {
						scoreItem.clear();
						scoreItem.remove();
					}
				})
				.setCallbackTriggers(TweenCallback.COMPLETE)
				.start(scoreTweenManager);
	}

	private void startGameCountdown(Ball ball) {
		Array<TextItem> countdownTextItems = new Array<TextItem>();
		int countdown = 3;
		float angle = - MathUtils.PI / 2f;
		float angleOffset = 16 * Settings.GAME_SCALE;
		Timeline timeline = Timeline.createSequence();
		for (int i = countdown; i > 0; i--) {
			TextItem countdownTextItem = new TextItem(String.valueOf(i));
			countdownTextItem.setColor(1f, 1f, 1f, 1f);
			float x = -countdownTextItem.getWidth() / 2 + MathUtils.cos(angle) * angleOffset;
			float y = -countdownTextItem.getHeight() / 2 + MathUtils.sin(angle) * angleOffset + countdownTextItem.getHeight();
			countdownTextItem.setX(x + MathUtils.cos(angle) * (Gdx.graphics.getWidth() - countdownTextItem.getX()));
			countdownTextItem.setY(y + MathUtils.sin(angle) * (Gdx.graphics.getHeight() - countdownTextItem.getY()));
			timeline.push(Tween.to(countdownTextItem, ActorAccessor.POSITION_XY, 0.4f)
						.target(x, y)
						.ease(Expo.OUT));
			angle += MathUtils.PI2 / 3f;
			countdownTextItems.add(countdownTextItem);
			gameStage.addActor(countdownTextItem);
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
		goTextItem.setX(-goTextItem.getWidth() / 2);
		goTextItem.setY(-goTextItem.getHeight() / 2 + goTextItem.getHeight());
		goTextItem.setActCallback(new ItemCallback() {
			
			@Override
			public void execute(Item data) {
				data.setX(-data.getWidth() / 2);
				data.setY(-data.getHeight() / 2 + data.getHeight());
			}
			
		});
		gameStage.addActor(goTextItem);
		
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
				gameActive = true;
				((Ball) source.getUserData()).speed = oldSpeed;
			}
			
		});
		timeline.start(getTweenManager());
	}

	@Override
	public void renderClearScreen(float delta) {
		backgroundColor.lerp(player.getColor().cpy().mul(0.5f), 0.25f);
		super.renderClearScreen(delta);
	}

	@Override
	public void renderStage(float delta) {
		Camera camera = gameStage.getCamera();
		camera.update();

		Batch batch = gameStage.getBatch();
		if (batch != null) {
			batch.setProjectionMatrix(camera.combined);
			batch.begin();
			gameStage.getRoot().draw(batch, 1);
			batch.end();
		}
		super.renderStage(delta);
	}

	@Override
	public void act(float delta) {
		gameStage.act(delta);

		if (gameActive) {
			waveCounter -= delta;
		}

		hitCounterTextItem.setText(String.valueOf((int) (waveCounter + 0.5f)));
		hitCounterTextItem.setX(4 * Settings.GAME_SCALE);
		hitCounterTextItem.setY(Gdx.graphics.getHeight() - 4 * Settings.GAME_SCALE);

		scoreTextItem.setText(String.valueOf(player.getScore()));
		scoreTextItem.setX(Gdx.graphics.getWidth() - scoreTextItem.getWidth() - 4 * Settings.GAME_SCALE);
		scoreTextItem.setY(Gdx.graphics.getHeight() - 4 * Settings.GAME_SCALE);

		if (waveCounter <= 0) {
			waveCounter = WAVE_LENGTH;

			/* Finish any potential remaining tweens. */
			getTweenManager().update(1000f);

			/* Move all current blocks down one row. */
			for (Actor actor : Groups.blockGroup.getChildren()) {
				Tween.to(actor, GameActorAccessor.POSITION_Y, 0.5f)
						.target(actor.getY() - actor.getHeight())
						.ease(TweenEquations.easeOutExpo)
						.delay(MathUtils.random(0.1f))
						.start(getTweenManager());
			}

			/* Create a new row of blocks. */
			Block tempBlock = new Block(0, 0, new Player("temp"), new Color(Color.BLACK), null, null);
			for (int x = 0; x < (int) Settings.LEVEL_WIDTH / tempBlock.getWidth(); x++) {
				Block block = createBlock(
						Settings.LEVEL_X + x * tempBlock.getWidth(),
						Settings.LEVEL_MAX_Y - tempBlock.getHeight());

				/* Add the new block to the start of the group, so it renders correctly. */
				Groups.blockGroup.addActorBefore(Groups.blockGroup.getChildren().first(), block);

				float z = block.getZ();
				block.setZ(350 * Settings.GAME_SCALE);
				Tween.to(block, GameActorAccessor.Z, MathUtils.random(0.5f, 0.75f))
						.target(z)
						.ease(TweenEquations.easeOutExpo)
						.start(getTweenManager());
			}
			tempBlock.destroy(false);
		}

		for (Actor actor : Groups.blockGroup.getChildren()) {
			if (actor.getY() < Level.getCurrentLevel().getDeathLineY()) {
				game.setScreen(new GameOverScreen(game, this, player));
			}
		}

		scoreTweenManager.update(delta);
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
		getInputMultiplexer().addProcessor(new PlayerInputAdapter(player, camera));
		getInputMultiplexer().addProcessor(new DebugInput(this, stage, player));
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
	public void resize(int width, int height) {
		gameStage.getViewport().update(width, height, false);
		super.resize(width, height);
	}

	@Override
	public void dispose() {
		super.dispose();
		gameStage.dispose();
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
