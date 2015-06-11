package com.pigmassacre.breakhaus.objects;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.g2d.Batch;
import com.badlogic.gdx.utils.Pool;
import com.badlogic.gdx.utils.Pool.Poolable;
import com.pigmassacre.breakhaus.Settings;

public class Residue extends GameActor implements Poolable {

	private static final float FADEOUT_TIME = 1f;

	public static final Pool<Residue> residuePool = new Pool<Residue>(250) {

		protected Residue newObject() {
			return new Residue();
		}

	};

	private float lingerTime;
	
	public Residue() {
		alive = false;
	}
	
	public void init(GameActor parentActor) {
		if (parentActor.getImage() != null) {
			setImage(parentActor.getImage());
			setX(parentActor.getX());
			setY(parentActor.getY());
			setZ(parentActor.getZ());
			setWidth(parentActor.getWidth());
			setHeight(parentActor.getHeight());
			setDepth(parentActor.getDepth());
			setColor(parentActor.getColor());
			lingerTime = 1f;
			Groups.residueGroup.addActor(this);
		} else {
			residuePool.free(this);
		}
	}
	
	@Override
	public void reset() {
		alive = false;
		setImage(null);
		remove();
		clear();
	}
	
	@Override
	public void act(float delta) {
		lingerTime -= delta;
		if (lingerTime <= 0) {
			getColor().a -= FADEOUT_TIME * delta;
			if (getColor().a < 0) {
				getColor().clamp();
				residuePool.free(this);
				return;
			}
			getColor().clamp();
		}
	}

	@Override
	public void draw(Batch batch, float parentAlpha) {
		Color temp = batch.getColor();
		batch.setColor(getColor());
		batch.draw(getImage(), getX(), getY() + Settings.getLevelYOffset(), getWidth(), getHeight() + getDepth());
		batch.setColor(temp);
	}
	
}
