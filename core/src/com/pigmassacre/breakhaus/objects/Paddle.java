package com.pigmassacre.breakhaus.objects;

import com.badlogic.gdx.Application.ApplicationType;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.g2d.Batch;
import com.badlogic.gdx.graphics.g2d.TextureRegion;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.math.Rectangle;
import com.pigmassacre.breakhaus.Assets;
import com.pigmassacre.breakhaus.Settings;

public class Paddle extends GameActor {

	private static final float DEPTH = 2f;
	private static final float HEIGHT_FROM_GROUND = 2f;

	private float acceleration, retardation, velocityX;
	public float maxSpeed;
	public final float defaultMaxSpeed;

	public boolean moveLeft, moveRight;
	public Rectangle touchRectangle;
	private float touchGraceSize;
	public int keyLeft, keyRight;
	private float touchX;

	private TextureRegion leftImage, middleImage, rightImage;
	private float leftWidth, middleWidth, rightWidth;
	private float smallestWidth, largestWidth;
	
	public float actualWidth, actualHeight;

	public Paddle(Player owner) {
		super();
		this.owner = owner;
		owner.paddle = this;

		setColor(new Color(owner.getColor()));

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

		if (Gdx.app.getType() == ApplicationType.Android) {
			defaultMaxSpeed = maxSpeed = 100f * Settings.GAME_FPS * Settings.GAME_SCALE;
		} else {
			defaultMaxSpeed = maxSpeed = 10f * Settings.GAME_FPS * Settings.GAME_SCALE;
		}
		acceleration = retardation = defaultMaxSpeed;

		velocityX = 0f;

		touchGraceSize = getWidth() / 8;
		moveLeft = false;
		moveRight = false;

		shadow = Shadow.shadowPool.obtain();
		shadow.init(this, false);

		Groups.paddleGroup.addActor(this);
	}

	@Override
	public void act(float delta) {
		super.act(delta);
		moveLeft = false;
		moveRight = false;
		if (Gdx.app.getType() == ApplicationType.Android) {
			for (int i = 0; i < 10; i++) {
				if (touchRectangle.contains(Gdx.input.getX(i), Gdx.input.getY(i)) && Gdx.input.isTouched(i)) {
					touchX = Gdx.graphics.getWidth() - Gdx.input.getX(i);
					moveLeft = getX() + (getWidth() / 2) < touchX - touchGraceSize;
					moveRight = getX() + (getWidth() / 2) > touchX + touchGraceSize;
					if (moveLeft || moveRight) {
						break;
					}
				}
			}
		} else {
			moveLeft = Gdx.input.isKeyPressed(keyLeft);
			moveRight = Gdx.input.isKeyPressed(keyRight);
		}

		if (maxSpeed > 0) {
			if (moveLeft) {
				velocityX -= acceleration;
				if (velocityX < -maxSpeed)
					velocityX = -maxSpeed;
			}
			if (moveRight) {
				velocityX += acceleration;
				if (velocityX > maxSpeed)
					velocityX = maxSpeed;
			}
			if (!moveLeft && !moveRight) {
				if (velocityX > 0) {
					velocityX -= retardation;
					if (velocityX < 0)
						velocityX = 0;
				} else if (velocityX < 0) {
					velocityX += retardation;
					if (velocityX > 0)
						velocityX = 0;
				}
			}
		} else {
			if (velocityX > 0) {
				velocityX -= retardation;
				if (velocityX < 0)
					velocityX = 0;
			} else if (velocityX < 0) {
				velocityX += retardation;
				if (velocityX > 0)
					velocityX = 0;
			}
		}

		setX(getX() + velocityX * delta);

		Level.getCurrentLevel().checkCollision(this);
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
		batch.setColor(getColor());
		drawImages(batch, parentAlpha, 0, 0, 0);
		batch.setColor(temp);
		batch.end();
		batch.begin();
		super.draw(batch, parentAlpha);
	}

	public void drawImages(Batch batch, float parentAlpha, float offsetX, float offsetY, float offsetHeight) {
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
