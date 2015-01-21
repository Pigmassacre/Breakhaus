package com.pigmassacre.breakhaus.objects.effects;

import com.badlogic.gdx.graphics.g2d.Batch;
import com.badlogic.gdx.utils.Timer;
import com.badlogic.gdx.utils.Timer.Task;
import com.pigmassacre.breakhaus.Settings;
import com.pigmassacre.breakhaus.objects.GameActor;

public class Effect extends GameActor {

	protected float duration;

	public Effect(Effect effect) {
		this(effect.parentActor, effect.duration);
	}

	public Effect(GameActor parentActor, float duration) {
		this.parentActor = parentActor;
		this.owner = this.parentActor.owner;
		this.duration = duration;

		this.parentActor.effectGroup.addActor(this);
		Timer.instance().scheduleTask(new Task() {
			
			@Override
			public void run() {
				destroy();
			}
			
		}, duration);
	}

	@Override
	public void act(float delta) {
		setWidth(parentActor.getWidth());
		setHeight(parentActor.getHeight());
		setX(parentActor.getX() + ((parentActor.getWidth() - getWidth()) / 2));
		setY(parentActor.getY() + ((parentActor.getHeight() - getHeight()) / 2));
		setZ(parentActor.getZ());
		setDepth(parentActor.getDepth());
		
		if (parentActor.owner == owner) {
			actParticles(delta);
		}
	}
	
	protected void actParticles(float delta) {
		
	}

	@Override
	public void draw(Batch batch, float parentAlpha) {
		if (getImage() != null) {
			batch.draw(getImage(), getX(), getY() + Settings.getLevelYOffset() + getZ(), getWidth(), getHeight() + getDepth());
		}
	}

}
