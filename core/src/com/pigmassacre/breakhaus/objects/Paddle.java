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

	public boolean moveUp, moveDown;
	public Rectangle touchRectangle;
	private float touchGraceSize;
	public int keyLeft, keyRight;

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
		moveUp = false;
		moveDown = false;

		shadow = Shadow.shadowPool.obtain();
		shadow.init(this, false);

		Groups.paddleGroup.addActor(this);
	}

	@Override
	public void setHeight(float height) {
		actualWidth = height;
		if (height < smallestWidth) {
			height = smallestWidth;
		} else if (height > largestWidth) {
			height = largestWidth;
		}
		middleWidth = height - leftWidth - bottomWidth + getDepth();
		float oldHeight = getHeight();
		super.setHeight(height);
		setY(getY() + ((oldHeight - getHeight()) / 2));
	}
	
	public void addHeight(float height) {
		setHeight(actualWidth + height);
	}

	@Override
	public void act(float delta) {
		super.act(delta);
		moveUp = false;
		moveDown = false;
		if (Gdx.app.getType() == ApplicationType.Android) {
			for (int i = 0; i < 10; i++) {
				if (touchRectangle.contains(Gdx.input.getX(i), Gdx.input.getY(i)) && Gdx.input.isTouched(i)) {
					touchY = Gdx.graphics.getHeight() - Gdx.input.getY(i);
					moveUp = getY() + (getHeight() / 2) < touchY - touchGraceSize;
					moveDown = getY() + (getHeight() / 2) > touchY + touchGraceSize;
					if (moveUp || moveDown)
						break;
				}
			}
		} else {
			moveUp = Gdx.input.isKeyPressed(keyLeft);
			moveDown = Gdx.input.isKeyPressed(keyRight);
		}

		if (maxSpeed > 0) {
			if (moveDown) {
				velocityX -= acceleration;
				if (velocityX < -maxSpeed)
					velocityX = -maxSpeed;
			}
			if (moveUp) {
				velocityX += acceleration;
				if (velocityX > maxSpeed)
					velocityX = maxSpeed;
			}
			if (!moveUp && !moveDown) {
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

		setY(getY() + velocityX * delta);

		Level.getCurrentLevel().checkCollision(this);
	}

	@Override
	public void onHitWall(WallSide side) {
		switch (side) {
		case UP:
			setY(Settings.LEVEL_MAX_Y - getHeight());
			break;
		case DOWN:
			setY(Settings.LEVEL_Y);
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
