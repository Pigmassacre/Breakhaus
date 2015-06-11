package com.pigmassacre.breakhaus.objects;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.g2d.Batch;
import com.badlogic.gdx.graphics.g2d.TextureRegion;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.math.Rectangle;
import com.pigmassacre.breakhaus.Assets;
import com.pigmassacre.breakhaus.Settings;

public class Paddle extends GameActor {

	private static final float DEPTH = 2f;
	private static final float HEIGHT_FROM_GROUND = 2f;

	private float targetX;
	private float speed;

	private final TextureRegion leftImage, middleImage, rightImage;
	private final float leftWidth, middleWidth, rightWidth;

	private final float smallestWidth, largestWidth;
	private float actualWidth, actualHeight;
	private int hitCount = 0;

	public Paddle(Player owner) {
		super();

		this.owner = owner;

		leftImage = Assets.getTextureRegion("paddle_left");
		middleImage = Assets.getTextureRegion("paddle_middle");
		rightImage = Assets.getTextureRegion("paddle_right");
		smallestWidth = 12f * Settings.GAME_SCALE;
		largestWidth = smallestWidth * 4f;

		setDepth(DEPTH * Settings.GAME_SCALE);
		setZ(HEIGHT_FROM_GROUND * Settings.GAME_SCALE);
		setHeight((middleImage.getRegionHeight() - DEPTH) * Settings.GAME_SCALE);
		leftWidth = leftImage.getRegionWidth() * Settings.GAME_SCALE;
		rightWidth = rightImage.getRegionWidth() * Settings.GAME_SCALE;
		middleWidth = (26 * Settings.GAME_SCALE) - (leftWidth + rightWidth);
		setWidth(leftWidth + middleWidth + rightWidth);
		actualWidth = getWidth();
		actualHeight = getHeight();

		rectangle = new Rectangle(getX(), getY(), getWidth(), getHeight());

		speed = 20f;

		shadow = Shadow.shadowPool.obtain();
		shadow.init(this, false);

		Groups.paddleGroup.addActor(this);
	}

	public void setTargetX(float targetX) {
		this.targetX = targetX;
	}

	public float getSpeed() {
		return speed;
	}

	public void setSpeed(float speed) {
		this.speed = speed;
	}

	public int getHitCount() {
		return hitCount;
	}

	public void resetHitCount() {
		hitCount = 0;
	}

	@Override
	public void act(float delta) {
		super.act(delta);
		setX(MathUtils.lerp(getX(), targetX, delta * speed));
		Level.getCurrentLevel().checkCollision(this);
	}

	public void hitByBall(Ball ball) {
		hitCount++;
	}

	@Override
	public void onHitWall(WallSide side) {
		switch (side) {
		case RIGHT:
			setX(Settings.LEVEL_MAX_X - getWidth());
			break;
		case LEFT:
			setX(Settings.LEVEL_X);
			break;
		default:
			break;
		}
	}

	@Override
	public void draw(Batch batch, float parentAlpha) {
		Color temp = new Color(batch.getColor());
		Color color = getColor();
		color.a *= parentAlpha;
		batch.setColor(color);
		drawImages(batch, 0, 0, 0);
		batch.setColor(temp);
		batch.end();
		batch.begin();
		super.draw(batch, parentAlpha);
	}

	public void drawImages(Batch batch, float offsetX, float offsetY, float offsetHeight) {
		batch.draw(leftImage,
				getX() + offsetX,
				getY() + Settings.getLevelYOffset() + getZ() + offsetY + offsetHeight,
				leftWidth,
				getHeight() + getDepth());
		batch.draw(middleImage,
				getX() + leftWidth + offsetX,
				getY() + Settings.getLevelYOffset() + getZ() + offsetY + offsetHeight,
				middleWidth,
				getHeight() + getDepth());
		batch.draw(rightImage,
				getX() + leftWidth + middleWidth + offsetX,
				getY() + Settings.getLevelYOffset() + getZ() + offsetY + offsetHeight,
				rightWidth,
				getHeight() + getDepth());
	}
}
