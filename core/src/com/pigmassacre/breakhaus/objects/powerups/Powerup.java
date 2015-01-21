package com.pigmassacre.breakhaus.objects.powerups;

import com.badlogic.gdx.graphics.g2d.Batch;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.scenes.scene2d.Actor;
import com.badlogic.gdx.utils.Array;
import com.badlogic.gdx.utils.TimeUtils;
import com.pigmassacre.breakhaus.Settings;
import com.pigmassacre.breakhaus.objects.Ball;
import com.pigmassacre.breakhaus.objects.GameActor;
import com.pigmassacre.breakhaus.objects.Groups;
import com.pigmassacre.breakhaus.objects.Shadow;
import com.pigmassacre.breakhaus.objects.effects.Flash;

public class Powerup extends GameActor {
	
	private static Array<Class<? extends Powerup>> availablePowerups;
	
	public static Array<Class<? extends Powerup>> getAvailablePowerups() {
		if (availablePowerups == null) {
			availablePowerups = new Array<Class<? extends Powerup>>();
			availablePowerups.add(ElectricityPowerup.class);
//			availablePowerups.add(FirePowerup.class);
//			availablePowerups.add(FrostPowerup.class);
//			availablePowerups.add(MultiballPowerup.class);
//			availablePowerups.add(SpeedPowerup.class);
		}
		return availablePowerups;
	}

	private float startTime;
	private float maxZ, minZ;
	
	public Powerup(float x, float y) {
		super();
		setDepth(1 * Settings.GAME_SCALE);
		setZ(4 * Settings.GAME_SCALE);
		setX(x);
		setY(y);
		maxZ = 2 * Settings.GAME_SCALE;
		minZ = 1;

		startTime = TimeUtils.millis() * 0.00001f;
		
		Groups.powerupGroup.addActor(this);
		
		shadow = Shadow.shadowPool.obtain();
		shadow.init(this, false);

		new Flash(this, 0.33f, true);
	}

	public void hit(GameActor actor) {
		onHit(actor);
		destroy();
	}
	
	protected void onHit(GameActor actor) {
		
	}

	public interface EffectCommand {

		public void execute(GameActor actor);
		
	}
	
	protected void applyEffect(GameActor touchingActor, EffectCommand command) {
		if (touchingActor instanceof Ball) {
			Ball ball = (Ball) touchingActor;
			command.execute(ball);
		}
	}
	
	protected void applyEffectToAllBalls(GameActor touchingActor, EffectCommand command) {
		for (Actor ballActor : Groups.ballGroup.getChildren()) {
			if (ballActor instanceof Ball) {
				Ball ball = (Ball) ballActor;
				command.execute(ball);
			}
		}
	}
	
	@Override
	public void act(float delta) {
		super.act(delta);
		stateTime += delta;
		float newZ = ((MathUtils.sinDeg(startTime + stateTime * 250f) + 1) / 2) * maxZ + minZ;
		if (newZ < minZ) newZ = minZ;
		setZ(newZ);
	}
	
	@Override
	public void draw(Batch batch, float parentAlpha) {
		batch.draw(getImage(), getX(), getY() + Settings.getLevelYOffset() + getZ(), getWidth(), getHeight() + getDepth());
		super.draw(batch, parentAlpha);
	}
	
}
