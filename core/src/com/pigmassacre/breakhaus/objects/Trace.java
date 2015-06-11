package com.pigmassacre.breakhaus.objects;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.g2d.Batch;
import com.pigmassacre.breakhaus.Settings;

public class Trace extends GameActor {

	private static final float ALPHA_STEP = 0.06f * Settings.GAME_FPS;
	
	private static final Color SHADOW_BLEND_COLOR = new Color(0.4f, 0.4f, 0.4f, 1.0f);
	
	public Trace(GameActor parentActor) {
		this.parentActor = parentActor;
		setColor(parentActor.getColor().cpy());
		this.setImage(parentActor.getImage());
		
		setDepth(parentActor.getDepth());
		setX(parentActor.getX());
		setY(parentActor.getY());
		setZ(parentActor.getZ());
		setWidth(parentActor.getWidth());
		setHeight(parentActor.getHeight());
		
		shadow = Shadow.shadowPool.obtain();
		shadow.init(this, false);
		shadow.getColor().mul(SHADOW_BLEND_COLOR);
		
		Groups.traceGroup.addActor(this);
	}
	
	@Override
	public void act(float delta) {
		if (ALPHA_STEP > 0) {
			getColor().a -= ALPHA_STEP * delta;
			shadow.getColor().a -= ALPHA_STEP / 2 * delta;
			if (getColor().a - (ALPHA_STEP * delta) < 0) {
				destroy();
			}
			getColor().clamp();
			shadow.getColor().clamp();
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
