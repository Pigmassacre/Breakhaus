package com.pigmassacre.breakhaus.objects;

import com.badlogic.gdx.graphics.g2d.Batch;
import com.badlogic.gdx.graphics.g2d.TextureRegion;
import com.badlogic.gdx.math.Rectangle;
import com.badlogic.gdx.scenes.scene2d.Actor;
import com.badlogic.gdx.scenes.scene2d.Group;
import com.pigmassacre.breakhaus.Settings;

public class GameActor extends Actor {

	public Player owner;
	protected GameActor parentActor;

	public TextureRegion image;

	private float z;
	private float depth;
	
	public Rectangle rectangle;
	protected Shadow shadow;

	protected float stateTime;

	public final Group effectGroup;
	
	public boolean alive;
	private DestroyCallback destroyCallback;
	private Object destroyCallbackData;

	public GameActor() {
		rectangle = new Rectangle();
		stateTime = 0f;
		effectGroup = new Group();
		alive = true;
		setZ(2 * Settings.GAME_SCALE);
	}

	@Override
	public void setX(float x) {
		super.setX(x);
		rectangle.x = x;
	}

	@Override
	public void setY(float y) {
		super.setY(y);
		rectangle.y = y;
	}
	
	public float getZ() {
		return z;
	}
	
	public void setZ(float z) {
		this.z = z;
	}

	@Override
	public void setWidth(float width) {
		super.setWidth(width);
		rectangle.width = width;
	}

	@Override
	public void setHeight(float height) {
		super.setHeight(height);
		rectangle.height = height;
	}
	
	public float getDepth() {
		return depth;
	}
	
	public void setDepth(float depth) {
		this.depth = depth;
	}
	
	public TextureRegion getImage() {
		return image;
	}
	
	public void setImage(TextureRegion image) {
		this.image = image;
	}
	
	public void setDestroyCallback(DestroyCallback destroyCallback, Object destroyCallbackData) {
		this.destroyCallback = destroyCallback;
		this.destroyCallbackData = destroyCallbackData;
	}
	
	private void executeDestroyCallback() {
		if (destroyCallback != null) {
			destroyCallback.execute(this, destroyCallbackData);
		}
	}
	
	public void destroy() {
		if (shadow != null) {
			Shadow.shadowPool.free(shadow);
		}
		effectGroup.clear();
		alive = false;
		remove();
		clear();
		executeDestroyCallback();
	}

	public void onHitObject(GameActor object) {
		if (object instanceof Ball) {
			onHitBall((Ball) object);
			for (Actor effect : effectGroup.getChildren()) {
				((GameActor) effect).onHitObject(object);
			}
		} else if (object instanceof Paddle) {
			onHitPaddle((Paddle) object);
			for (Actor effect : effectGroup.getChildren()) {
				((GameActor) effect).onHitObject(object);
			}
		} else if (object instanceof Block) {
			onHitBlock((Block) object);
			for (Actor effect : effectGroup.getChildren()) {
				((GameActor) effect).onHitObject(object);
			}
		}
	}

	public void onHitBall(Ball ball) {
//		System.out.println(toString() + ": hit ball: " + ball);
	}

	public void onHitPaddle(Paddle paddle) {
//		System.out.println(toString() + ": hit paddle: " + paddle);
	}

	public void onHitBlock(Block block) {
//		System.out.println(toString() + ": hit block: " + block);
	}

	public enum WallSide {
		LEFT, RIGHT, UP, DOWN
	}

	public void onHitWall(WallSide side) {

	}
	
	@Override
	public void act(float delta) {
		move(delta);
		effectGroup.act(delta);
	}
	
	public void move(float delta) {
		
	}
	
	@Override
	public void draw(Batch batch, float parentAlpha) {
		effectGroup.draw(batch, parentAlpha);
	}

	public interface DestroyCallback {

		void execute(GameActor actor, Object data);

	}

}
