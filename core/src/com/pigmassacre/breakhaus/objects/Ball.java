package com.pigmassacre.breakhaus.objects;

import aurelienribon.tweenengine.Timeline;
import aurelienribon.tweenengine.Tween;
import aurelienribon.tweenengine.TweenEquations;
import com.badlogic.gdx.audio.Sound;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.g2d.Batch;
import com.badlogic.gdx.math.Circle;
import com.badlogic.gdx.math.Intersector;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.scenes.scene2d.Actor;
import com.badlogic.gdx.utils.Pool;
import com.badlogic.gdx.utils.Pool.Poolable;
import com.pigmassacre.breakhaus.Assets;
import com.pigmassacre.breakhaus.Settings;
import com.pigmassacre.breakhaus.gui.Accessors.GameActorAccessor;
import com.pigmassacre.breakhaus.objects.effects.Effect;
import com.pigmassacre.breakhaus.objects.effects.Flash;
import com.pigmassacre.breakhaus.objects.powerups.Powerup;

public class Ball extends GameActor implements Poolable {

	private static final float BASE_DAMAGE = 10;
	private static final float LEAST_ALLOWED_HORIZONTAL_ANGLE = 1f;

	public static final Pool<Ball> ballPool = new Pool<Ball>() {

		protected Ball newObject() {
			return new Ball();
		}

	};

	private final Sound hitSound;

	private boolean collided;

	public Circle circle;

	private float angle;
	public float speed;
	private float baseSpeed, maxSpeed, tickSpeed, speedStep, speedHandled;

	private float traceTime, traceRate;
	
	public Ball() {
		super();
		alive = false;
		setImage(Assets.getTextureRegion("ball"));
		hitSound = Assets.getSound("sound/ball.ogg");
	}
	
	public void init(float x, float y, float angle, Player owner) {
		alive = true;
		
		circle = new Circle();
	
		setDepth(1 * Settings.GAME_SCALE);
		setWidth(getImage().getRegionWidth() * Settings.GAME_SCALE);
		setHeight(getImage().getRegionHeight() * Settings.GAME_SCALE - getDepth());
		setX(x);
		setY(y);
		setZ(3 * Settings.GAME_SCALE);
		
		this.angle = angle;
		
		baseSpeed = speed = 2f * Settings.GAME_FPS * Settings.GAME_SCALE;
		maxSpeed = 5f * Settings.GAME_FPS * Settings.GAME_SCALE;
		speedStep = 0.5f * Settings.GAME_FPS * Settings.GAME_SCALE;
		
		this.owner = owner;
		
		traceTime = 0f;
		traceRate = 0.00053f * Settings.GAME_FPS;
		
		setColor(owner.getColor());
		
		shadow = Shadow.shadowPool.obtain();
		shadow.init(this, false);
		
		Groups.ballGroup.addActor(this);
	}
	
	@Override
	public void reset() {
		destroy();
	}
	
	@Override
	public void setX(float x) {
		circle.setX(x);
		super.setX(x - circle.radius);
	}
	
	@Override
	public void setY(float y) {
		circle.setY(y);
		super.setY(y - circle.radius);
	}
	
	@Override
	public void setWidth(float width) {
		super.setWidth(width);
		circle.setRadius(width / 2);
	}
	
	@Override
	public void setHeight(float height) {
		super.setHeight(height);
		circle.setRadius(height / 2);
	}
	
	@Override
	public void move(float delta) {
		speedHandled = 0f;
		while (speedHandled < speed) {
			if (speed - speedHandled >= speedStep) {
				tickSpeed = speedStep;
			} else {
				tickSpeed = speed - speedHandled;
			}
			
			collided = false;
			
			checkCollisionBlocks();
			checkCollisionBalls();
			checkCollisionPaddles();
			checkCollisionPowerups();
			
			if (angle > MathUtils.PI - LEAST_ALLOWED_HORIZONTAL_ANGLE && angle < MathUtils.PI) {
				angle = MathUtils.PI - LEAST_ALLOWED_HORIZONTAL_ANGLE;
			} else if (angle < MathUtils.PI + LEAST_ALLOWED_HORIZONTAL_ANGLE && angle > MathUtils.PI) {
				angle = MathUtils.PI + LEAST_ALLOWED_HORIZONTAL_ANGLE;
			} else if (angle > 0 - LEAST_ALLOWED_HORIZONTAL_ANGLE && angle < 0) {
				angle = 0 - LEAST_ALLOWED_HORIZONTAL_ANGLE;
			} else if (angle < 0 + LEAST_ALLOWED_HORIZONTAL_ANGLE && angle > 0) {
				angle = 0 + LEAST_ALLOWED_HORIZONTAL_ANGLE;
			} else if (angle == MathUtils.PI) {
				angle = MathUtils.PI - LEAST_ALLOWED_HORIZONTAL_ANGLE;
			} else if (angle == 0) {
				angle = 0 + LEAST_ALLOWED_HORIZONTAL_ANGLE;
			}
			
			if (angle > 2 * MathUtils.PI) {
				angle -= 2 * MathUtils.PI;
			} else if (angle < 0) {
				angle += 2 * MathUtils.PI;
			}
			
			if (speed > maxSpeed) {
				speed = maxSpeed;
			}

			setX(circle.x + (MathUtils.cos(angle) * tickSpeed * delta));
			setY(circle.y + (MathUtils.sin(angle) * tickSpeed * delta));
			
			Level.getCurrentLevel().checkCollision(this);

			if (collided) {
				hitSound.play();
				new Flash(this, 0.33f);
			}
			
			speedHandled += tickSpeed;
		}
		
		traceTime += delta;
		if (traceTime > traceRate && speed > 0f) {
			new Trace(this);
			traceTime = 0f;
		}
	}

	private void hitTopSideOfPaddle(Paddle paddle) {
		float paddleDivider = 2f;
		float xAnglePos = 0f;
		if (circle.x < paddle.getX() + (paddle.getWidth() / paddleDivider)) {
			xAnglePos = circle.x - (paddle.getX() + (paddle.getWidth() / paddleDivider));
		} else if (circle.x > paddle.getX() + (paddle.getWidth() - (paddle.getWidth() / paddleDivider))) {
			xAnglePos = circle.x - (paddle.getX() + (paddle.getWidth() - (paddle.getWidth() / paddleDivider)));
		}
		angle = MathUtils.atan2(circle.y - (paddle.getY() + paddle.getHeight() / 2), xAnglePos);
		setY(paddle.rectangle.getY() + paddle.getHeight() + circle.radius + 1);
	}

	private void hitBottomSideOfPaddle(Paddle paddle) {
		angle = MathUtils.atan2(circle.y - (paddle.getY() + paddle.getHeight() / 2), circle.x - (paddle.getX() + paddle.getWidth() / 2));
		setY(paddle.getY() - circle.radius - 1);
	}

	private void hitLeftSideOfPaddle(Paddle paddle) {
		angle = MathUtils.atan2(circle.y - (paddle.getY() + paddle.getHeight() / 2), circle.x - (paddle.getX() + paddle.getWidth() / 2));
		setX(paddle.rectangle.getX() - circle.radius - 1);
	}
	
	private void hitRightSideOfPaddle(Paddle paddle) {
		angle = MathUtils.atan2(circle.y - (paddle.getY() + paddle.getHeight() / 2), circle.x - (paddle.getX() + paddle.getWidth() / 2));
		setX(paddle.getX() + paddle.getWidth() + circle.radius + 1);
	}
	
	private void checkCollisionPaddles() {
		Paddle paddle;
		float rX, rY, rRadius, bX, bY, bWidth, bHeight;
		
		for (Actor actor : Groups.paddleGroup.getChildren().items) {
			if (actor instanceof Paddle) {
				paddle = (Paddle) actor;
				if (Intersector.overlaps(this.circle, paddle.rectangle)) {
					new Flash(paddle, 0.33f, true);
					onHitObject(paddle);
					collided = true;
					speed += maxSpeed / 10;
					rX = this.circle.x;
					rY = this.circle.y;
					rRadius = this.circle.radius * 2;
					
					bX = paddle.rectangle.getX();
					bY = paddle.rectangle.getY();
					bWidth = paddle.rectangle.getWidth();
					bHeight = paddle.rectangle.getHeight();
					
					if (rY - rRadius <= bY + bHeight && rY + rRadius > bY + bHeight) {
						hitTopSideOfPaddle(paddle);
						if (bX - (rX - rRadius) > (rY + rRadius) - (bY + bHeight)) {
							hitLeftSideOfPaddle(paddle);
						} else if (rX + rRadius - (bX + bWidth) > (rY + rRadius) - (bY + bHeight)) {
							hitRightSideOfPaddle(paddle);
						}
					} else if (rY + rRadius >= bY && (rY - rRadius) < bY) {
						hitBottomSideOfPaddle(paddle);
						if (bX - (rX - rRadius) > bY - (rY - rRadius)) {
							hitLeftSideOfPaddle(paddle);
						} else if (rX + rRadius - (bX + bWidth) > bY - (rY - rRadius)) {
							hitRightSideOfPaddle(paddle);
						}
					} else if (rX + rRadius >= bX && (rX - rRadius) < bX) {
						hitLeftSideOfPaddle(paddle);
					} else if (rX - rRadius <= bX + bWidth && rX + rRadius > bX + bWidth) {
						hitRightSideOfPaddle(paddle);
					}
				}
			}
		}
	}
	
	public void checkCollisionBalls() {
		Ball ball;
		float deltaX, deltaY;
		float rX, rY, rRadius, bX, bY, bRadius;
		
		for (Actor actor : Groups.ballGroup.getChildren().items) {
			if (actor instanceof Ball) {
				ball = (Ball) actor;
				if (Intersector.overlaps(ball.circle, this.circle) && ball != this) {
					onHitObject(ball);
					collided = true;
					rX = this.circle.x;
					rY = this.circle.y;
					rRadius = this.circle.radius;
					
					bX = ball.circle.x;
					bY = ball.circle.y;
					bRadius = ball.circle.radius;
					
					// TODO: This is retarded. These if else clauses never equal true.
					if (rY <= bY && rY > bY) {
						if (bX - rX > rY - bY) {
							setX(bX - rRadius - 1);
						} else if (rX - bX > rY - bY) {
							setX(bX + bRadius + 1);
						} else {
							setY(bY + bRadius + 1);
						}
					} else if (rY >= bY && rY < bY) {
						if (bX - rX > bY - rY) {
							setX(bX - rRadius - 1);
						} else if (rX - bX > bY - rY) {
							setX(bX + bRadius + 1);
						} else {
							setY(bY - rRadius - 1);
						}
					} else if (rX >= bX && rX < bX) {
						setX(bX - rRadius - 1);
					} else if (rX <= bX && rX > bX ) {
						setX(bX + bRadius + 1);
					}

					deltaX = rX - bX;
					deltaY = rY - bY;
					angle = MathUtils.atan2(deltaY, deltaX);

					deltaX = bX - rX;
					deltaY = bY - rY;
					ball.angle = MathUtils.atan2(deltaY, deltaX);
				}
			}
		}
	}
	
	public void checkCollisionBlocks() {
		Block block;
		float rX = this.circle.x, rY = this.circle.y, rRadius = this.circle.radius, bX = 0, bY = 0, bWidth = 0, bHeight = 0;
		
		for (Actor actor : Groups.blockGroup.getChildren().items) {
			if (actor instanceof Block) {
				block = (Block) actor;
				if (Intersector.overlaps(this.circle, block.rectangle)) {
					new Flash(block, 0.2f, true);
//					block.offsetZ = -1f * Settings.GAME_SCALE;
					block.damage(BASE_DAMAGE);
					onHitObject(block);
					collided = true;
					bX = block.rectangle.getX();
					bY = block.rectangle.getY();
					bWidth = block.rectangle.getWidth();
					bHeight = block.rectangle.getHeight();
				}
			}
		}
		if (collided) {
//			speed = baseSpeed;
			if (rY - rRadius <= bY + bHeight && rY + rRadius > bY + bHeight) {
				if (bX - (rX - rRadius) > (rY + rRadius) - (bY + bHeight)) {
					setX(bX - rRadius - 1);
					angle = MathUtils.PI - angle;
				} else if (rX + rRadius - (bX + bWidth) > (rY + rRadius) - (bY + bHeight)) {
					setX(bX + bWidth + rRadius + 1);
					angle = MathUtils.PI - angle;
				} else {
					setY(bY + bHeight + rRadius + 1);
					angle = -angle;
				}
			} else if (rY + rRadius >= bY && (rY - rRadius) < bY) {
				if (bX - (rX - rRadius) > bY - (rY - rRadius)) {
					setX(bX - rRadius - 1);
					angle = MathUtils.PI - angle;
				} else if (rX + rRadius - (bX + bWidth) > bY - (rY - rRadius)) {
					setX(bX + bWidth + rRadius + 1);
					angle = MathUtils.PI - angle;
				} else {
					setY(bY - rRadius - 1);
					angle = -angle;
				}
			} else if (rX + rRadius >= bX && (rX - rRadius) < bX) {
				setX(bX - rRadius - 1);
				angle = MathUtils.PI - angle;
			} else if (rX - rRadius <= bX + bWidth && rX + rRadius > bX + bWidth) {
				setX(bX + bWidth + rRadius + 1);
				angle = MathUtils.PI - angle;
			}
		}
		
	}
	
	private void checkCollisionPowerups() {
		Powerup powerup;
		for (Actor actor : Groups.powerupGroup.getChildren()) {
			if (actor instanceof Powerup) {
				powerup = (Powerup) actor;
				if (Intersector.overlaps(circle, powerup.rectangle)) {
					powerup.hit(this);
				}
			}
		}
	}
	
	@Override
	public void onHitObject(GameActor object) {
		shootParticlesOnHit(3, 5);
		super.onHitObject(object);
	}

	@Override
	public void onHitBlock(Block block) {
		for (Actor actor : Groups.blockGroup.getChildren()) {
			GameActor gameActor = ((GameActor) actor);
			float dst = Vector2.dst(block.getX(), block.getY(), gameActor.getX(), gameActor.getY());
			if (dst < 200) {
				float delay = dst / 1000;
				Timeline.createSequence()
						.push(Tween.to(gameActor, GameActorAccessor.Z, 0.15f)
								.target(Math.max(Block.STANDARD_Z, 20f - (20 * (dst / 200))))
								.ease(TweenEquations.easeOutExpo)
								.delay(delay))
						.push(Tween.to(gameActor, GameActorAccessor.Z, 0.2f)
								.target(Block.STANDARD_Z)
								.ease(TweenEquations.easeOutExpo))
						.start(Level.getCurrentLevel().getTweenManager());
			}
		}
	}

	@Override
	public void onHitPaddle(Paddle paddle) {
		owner = paddle.owner;
		setColor(paddle.owner.getColor());
		paddle.hitByBall(this);
	}
	
	@Override
	public void onHitWall(WallSide side) {
		switch (side) {
		case LEFT:
			angle = MathUtils.PI - angle;
			setX(Settings.LEVEL_X + circle.radius);
			collided = true;
			break;
		case RIGHT:
			angle = MathUtils.PI - angle;
			setX(Settings.LEVEL_MAX_X - circle.radius);
			collided = true;
			break;
		case DOWN:
			angle = -angle;
			setY(Settings.LEVEL_Y + circle.radius);
			speed = baseSpeed;
			collided = true;
			break;
		case UP:
			angle = -angle;
			setY(Settings.LEVEL_MAX_Y - circle.radius);
			collided = true;
			break;
		}
		shootParticlesOnHit(3, 5);
		for (Actor effect : effectGroup.getChildren()) {
			((Effect) effect).onHitWall(side);
		}
	}
	
	private void shootParticlesOnHit(int lowBound, int highBound) {
		for (int i = 0; i < MathUtils.random(lowBound, highBound); i++) {
			float width = MathUtils.random(2f * Settings.GAME_SCALE, 2.5f * Settings.GAME_SCALE);
			float angle = this.angle + MathUtils.random(-MathUtils.PI / 6, MathUtils.PI / 6);
			float speed = MathUtils.random(0.75f * Settings.GAME_FPS * Settings.GAME_SCALE, 0.9f * Settings.GAME_FPS * Settings.GAME_SCALE);
			float retardation = speed / 12f;
			Color tempColor = getColor().cpy();
			Particle particle = Particle.particlePool.obtain();
			particle.init(getX() + getWidth() / 2, getY() + getHeight() / 2 - getDepth() + getZ(), width, width, angle, speed, retardation, 0.05f * Settings.GAME_FPS, tempColor);
		}
		for (int i = 0; i < MathUtils.random(lowBound + 2, highBound + 2); i++) {
			float width = MathUtils.random(1.25f * Settings.GAME_SCALE, 1.75f * Settings.GAME_SCALE);
			float angle = MathUtils.random(-MathUtils.PI / 5, MathUtils.PI / 5);
			float speed = MathUtils.random(0.85f * Settings.GAME_FPS * Settings.GAME_SCALE, 1.1f * Settings.GAME_FPS * Settings.GAME_SCALE);
			float retardation = speed / 18f;
			Color tempColor = getColor().cpy();
			Particle particle = Particle.particlePool.obtain();
			particle.init(getX() + getWidth() / 2, getY() + getHeight() / 2 - getDepth() + getZ(), width, width, angle, speed, retardation, 0.05f * Settings.GAME_FPS, tempColor);
		}
	}

	@Override
	public void draw(Batch batch, float parentAlpha) {
		Color temp = batch.getColor();
		batch.setColor(getColor());
		batch.draw(getImage(), getX(), getY() + Settings.getLevelYOffset() + getZ(), getWidth(), getHeight() + getDepth());
		batch.setColor(temp);
		super.draw(batch, parentAlpha);
	}
	
}
