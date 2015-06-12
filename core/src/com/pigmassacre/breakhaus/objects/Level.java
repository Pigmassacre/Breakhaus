package com.pigmassacre.breakhaus.objects;

import aurelienribon.tweenengine.TweenManager;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.g2d.Batch;
import com.badlogic.gdx.graphics.g2d.TextureRegion;
import com.badlogic.gdx.scenes.scene2d.Actor;
import com.pigmassacre.breakhaus.Assets;
import com.pigmassacre.breakhaus.Settings;

public class Level extends Actor {

	private static Level currentLevel;

	private final Player player;

	private final Background background;
	private final Foreground foreground;
	
	private final TextureRegion backgroundImage, horizontalWallTop;
	private final TextureRegion verticalWallLeft, verticalWallRight, horizontalWallBottom;
	private final TextureRegion topLeftCorner, bottomLeftCorner, topRightCorner, bottomRightCorner;

	private float deathLineY;
	private final TextureRegion deathLine;

	private static final float DEATH_LINE_HEIGHT = 1f * Settings.GAME_SCALE;

	private TweenManager tweenManager;

	public static Level getCurrentLevel() {
		return currentLevel;
	}

	public static void setCurrentLevel(String id, Player player) {
		currentLevel = new Level(id, player);
	}
	
	private Level(String id, Player player) {
		this.player = player;

		backgroundImage = Assets.getTextureRegion(id + "/floor");
		
		verticalWallLeft = Assets.getTextureRegion(id + "/wall_vertical_left");
		verticalWallRight = Assets.getTextureRegion(id + "/wall_vertical_right");
		horizontalWallTop = Assets.getTextureRegion(id + "/wall_horizontal_top");
		horizontalWallBottom = Assets.getTextureRegion(id + "/wall_horizontal_bottom");
		topLeftCorner = Assets.getTextureRegion(id + "/corner_top_left");
		bottomLeftCorner = Assets.getTextureRegion(id + "/corner_bottom_left");
		topRightCorner = Assets.getTextureRegion(id + "/corner_top_right");
		bottomRightCorner = Assets.getTextureRegion(id + "/corner_bottom_right");
		
		setX(Settings.LEVEL_X);
		setY(Settings.LEVEL_Y);
		setWidth(Settings.LEVEL_WIDTH);
		setHeight(Settings.LEVEL_HEIGHT);

		deathLine = Assets.getTextureRegion("particle");
		deathLineY = Settings.LEVEL_Y + Settings.LEVEL_HEIGHT / 3f;

		background = new Background();
		foreground = new Foreground();
	}

	public Player getPlayer() {
		return player;
	}

	public float getDeathLineY() {
		return deathLineY;
	}

	public Background getBackground() {
		return background;
	}
	
	public Foreground getForeground() {
		return foreground;
	}

	public TweenManager getTweenManager() {
		return tweenManager;
	}

	public void setTweenManager(TweenManager tweenManager) {
		this.tweenManager = tweenManager;
	}

	private class Background extends Actor {
		
		@Override
		public void draw(Batch batch, float parentAlpha) {
			batch.draw(horizontalWallTop,
					Level.getCurrentLevel().getX(),
					Level.getCurrentLevel().getY() + Level.getCurrentLevel().getHeight() + Settings.getLevelYOffset(),
					Level.getCurrentLevel().getWidth(),
					horizontalWallTop.getRegionHeight() * Settings.GAME_SCALE);
			batch.draw(backgroundImage,
					Level.getCurrentLevel().getX(),
					Level.getCurrentLevel().getY() + Settings.getLevelYOffset(),
					Level.getCurrentLevel().getWidth(),
					Level.getCurrentLevel().getHeight());
			Color temp = batch.getColor().cpy();
			Color color = batch.getColor();
			color.a = 0.25f;
			batch.setColor(color);
			batch.draw(deathLine,
					Level.getCurrentLevel().getX(),
					Level.getCurrentLevel().getDeathLineY() - DEATH_LINE_HEIGHT / 2f,
					Level.getCurrentLevel().getWidth(),
					DEATH_LINE_HEIGHT);
			batch.setColor(temp);
		}
		
	}
	
	private class Foreground extends Actor {
		
		@Override
		public void draw(Batch batch, float parentAlpha) {
			batch.draw(topLeftCorner,
					Level.getCurrentLevel().getX() - topLeftCorner.getRegionWidth() * Settings.GAME_SCALE,
					Level.getCurrentLevel().getY() + Level.getCurrentLevel().getHeight() + Settings.getLevelYOffset(),
					topLeftCorner.getRegionWidth() * Settings.GAME_SCALE,
					topLeftCorner.getRegionHeight() * Settings.GAME_SCALE);
			batch.draw(topRightCorner,
					Level.getCurrentLevel().getX() + Level.getCurrentLevel().getWidth(),
					Level.getCurrentLevel().getY() + Level.getCurrentLevel().getHeight() + Settings.getLevelYOffset(),
					topLeftCorner.getRegionWidth() * Settings.GAME_SCALE,
					topLeftCorner.getRegionHeight() * Settings.GAME_SCALE);
			batch.draw(verticalWallLeft,
					Level.getCurrentLevel().getX() - verticalWallLeft.getRegionWidth() * Settings.GAME_SCALE,
					Level.getCurrentLevel().getY() + Settings.getLevelYOffset(),
					verticalWallLeft.getRegionWidth() * Settings.GAME_SCALE,
					Level.getCurrentLevel().getHeight());
			batch.draw(verticalWallRight,
					Level.getCurrentLevel().getX() + Level.getCurrentLevel().getWidth(),
					Level.getCurrentLevel().getY() + Settings.getLevelYOffset(),
					verticalWallRight.getRegionWidth() * Settings.GAME_SCALE,
					Level.getCurrentLevel().getHeight());
			batch.draw(bottomLeftCorner,
					Level.getCurrentLevel().getX() - bottomLeftCorner.getRegionWidth() * Settings.GAME_SCALE,
					Level.getCurrentLevel().getY() - 1 * Settings.GAME_SCALE + Settings.getLevelYOffset(),
					bottomLeftCorner.getRegionWidth() * Settings.GAME_SCALE,
					bottomLeftCorner.getRegionHeight() * Settings.GAME_SCALE);
			batch.draw(bottomRightCorner,
					Level.getCurrentLevel().getX() + Level.getCurrentLevel().getWidth(),
					Level.getCurrentLevel().getY() - 1 * Settings.GAME_SCALE + Settings.getLevelYOffset(),
					bottomLeftCorner.getRegionWidth() * Settings.GAME_SCALE,
					bottomLeftCorner.getRegionHeight() * Settings.GAME_SCALE);
			batch.draw(horizontalWallBottom,
					Level.getCurrentLevel().getX(),
					Level.getCurrentLevel().getY() - 1 * Settings.GAME_SCALE + Settings.getLevelYOffset(),
					Level.getCurrentLevel().getWidth(),
					horizontalWallBottom.getRegionHeight() * Settings.GAME_SCALE);
		}
		
	}
	
	public boolean checkCollision(GameActor actor) {
		if (actor instanceof Ball) {
			return checkCollisionBall((Ball) actor);
		}
		return checkCollisionGameActor(actor);
	}
	
	private boolean checkCollisionBall(Ball ball) {
		boolean hit = false;
		if (ball.circle.x - ball.circle.radius < Settings.LEVEL_X) {
			ball.onHitWall(GameActor.WallSide.LEFT);
			hit = true;
		} else if (ball.circle.x + ball.circle.radius > Settings.LEVEL_MAX_X) {
			ball.onHitWall(GameActor.WallSide.RIGHT);
			hit = true;
		}
		if (ball.circle.y - ball.circle.radius < Settings.LEVEL_Y) {
			ball.onHitWall(GameActor.WallSide.DOWN);
			hit = true;
		} else if (ball.circle.y + ball.circle.radius > Settings.LEVEL_MAX_Y) {
			ball.onHitWall(GameActor.WallSide.UP);
			hit = true;
		}
		return hit;
	}
	
	private boolean checkCollisionGameActor(GameActor actor) {
		boolean hit = false;
		if (actor.rectangle.x < Settings.LEVEL_X) {
			actor.onHitWall(GameActor.WallSide.LEFT);
			hit = true;
		} else if (actor.rectangle.x + actor.rectangle.width > Settings.LEVEL_MAX_X) {
			actor.onHitWall(GameActor.WallSide.RIGHT);
			hit = true;
		}
		if (actor.rectangle.y < Settings.LEVEL_Y) {
			actor.onHitWall(GameActor.WallSide.DOWN);
			hit = true;
		} else if (actor.rectangle.y + actor.rectangle.height > Settings.LEVEL_MAX_Y) {
			actor.onHitWall(GameActor.WallSide.UP);
			hit = true;
		}
		return hit;
	}
	
}
