package com.pigmassacre.breakhaus.objects;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.g2d.Batch;
import com.badlogic.gdx.scenes.scene2d.Group;
import com.badlogic.gdx.utils.Pool;
import com.badlogic.gdx.utils.Pool.Poolable;
import com.pigmassacre.breakhaus.Settings;

public class Shadow extends GameActor implements Poolable {

	public static final Pool<Shadow> shadowPool = new Pool<Shadow>() {

		protected Shadow newObject() {
			return new Shadow();
		}

	};
	
	private boolean linger;
	
	public Shadow() {
		alive = false;
		setZ(0);
	}
	
	public void init(GameActor parentActor, boolean linger) {
		this.parentActor = parentActor;
		setImage(parentActor.getImage());
		
		setColor(0f, 0f, 0f, 0.5f);
		setZ(parentActor.getZ());
		setDepth(0);
		
		this.linger = linger;
		
		alive = true;
		
		Groups.shadowGroup.addActor(this);
	}

	@Override
	public void reset() {
		if (linger) {
			Residue residue = Residue.residuePool.obtain();
			residue.init(this);
		}
		alive = false;
		remove();
		clear();
	}
	
	@Override
	public float getX() {
		return parentActor.getX();
	}
	
	@Override
	public float getY() {
		return parentActor.getY();
	}

	@Override
	public float getWidth() {
		return parentActor.getWidth();
	}

	@Override
	public float getHeight() {
		return parentActor.getHeight();
	}

	@Override
	public void draw(Batch batch, float parentAlpha) {
		Color temp = batch.getColor();
		batch.setColor(getColor());
		if (parentActor instanceof Paddle) {
			Paddle paddle = (Paddle) parentActor;
			paddle.drawImages(batch, 0, -paddle.getZ(), -paddle.getDepth());
		} else {
			batch.draw(parentActor.getImage(), getX(), getY() + Settings.getLevelYOffset(), getWidth(), getHeight());
		}
		batch.setColor(temp);
	}

}
