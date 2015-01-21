package com.pigmassacre.breakhaus.objects;

import com.badlogic.gdx.Application.ApplicationType;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.g2d.Batch;
import com.badlogic.gdx.graphics.g2d.TextureRegion;
import com.badlogic.gdx.math.Rectangle;
import com.pigmassacre.breakhaus.Assets;
import com.pigmassacre.breakhaus.Settings;

public class Paddle extends GameActor {

	private float acceleration, retardation, velocityX;
	public float maxSpeed;
	public final float defaultMaxSpeed;

	public boolean moveLeft, moveRight;
	public Rectangle touchRectangle;
	private float touchGraceSize;
	public int keyLeft, keyRight;
	private float touchX;

	private TextureRegion leftImage, middleImage, rightImage;
	private float leftWidth, middleWidth, bottomWidth;
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

		setDepth(2 * Settings.GAME_SCALE);
		setZ(2 * Settings.GAME_SCALE);
		setHeight((middleImage.getRegionHeight() - getDepth()) * Settings.GAME_SCALE);
		leftWidth = leftImage.getRegionWidth() * Settings.GAME_SCALE;
		bottomWidth = rightImage.getRegionWidth() * Settings.GAME_SCALE;
		middleWidth = 26 * Settings.GAME_SCALE - leftWidth - bottomWidth;
		setWidth(leftWidth + middleWidth + bottomWidth);
		actualHeight = getWidth();
		actualWidth = getHeight();

		rectangle = new Rectangle(getX(), getY(), getWidth(), getHeight());

		defaultMaxSpeed = maxSpeed = 10f * Settings.GAME_FPS * Settings.GAME_SCALE;
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
			if (moveRight) {
				velocityX -= acceleration;
				if (velocityX < -maxSpeed)
					velocityX = -maxSpeed;
			}
			if (moveLeft) {
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
			setY(Settings.LEVEL_MAX_X - getWidth());
			break;
		case LEFT:
			setY(Settings.LEVEL_X);
			break;
		default:
			break;
		}
	}
	
	private Color temp;

	@Override
	public void draw(Batch batch, float parentAlpha) {
		temp = new Color(batch.getColor());
		batch.setColor(getColor());
		drawImages(batch, parentAlpha, 0, 0, 0);
		batch.setColor(temp);
		batch.end();
		batch.begin();
		super.draw(batch, parentAlpha);
	}
	
	public void drawImages(Batch batch, float parentAlpha, float offsetX, float offsetY, float offsetHeight) {
		batch.draw(leftImage, getX() + offsetX, getY() + Settings.getLevelYOffset() + getZ() + bottomWidth + middleWidth + offsetY + offsetHeight, getWidth(), leftWidth);
		batch.draw(middleImage, getX() + offsetX, getY() + Settings.getLevelYOffset() + getZ() + bottomWidth + offsetY, getWidth(), middleWidth + offsetHeight);
		batch.draw(rightImage, getX() + offsetX, getY() + Settings.getLevelYOffset() + getZ() + offsetY, getWidth(), bottomWidth);
	}
	
}
