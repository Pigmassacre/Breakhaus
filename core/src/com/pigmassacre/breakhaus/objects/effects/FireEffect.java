package com.pigmassacre.breakhaus.objects.effects;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.math.MathUtils;
import com.pigmassacre.breakhaus.Settings;
import com.pigmassacre.breakhaus.objects.Block;
import com.pigmassacre.breakhaus.objects.GameActor;
import com.pigmassacre.breakhaus.objects.Particle;

public class FireEffect extends Effect {

	public static final float DAMAGE_PER_SECOND = 2f;
	
	public static final float PARTICLE_SPAWN_RATE = 0.1f;
	public static final int PARTICLE_LEAST_SPAWN_AMOUNT = 3;
	public static final int PARTICLE_MAXIMUM_SPAWN_AMOUNT = 6;
	
	private float particleSpawnTime = 0f;
	
	public FireEffect(FireEffect fireEffect) {
		super(fireEffect);
	}
	
	public FireEffect(GameActor parent, float duration) {
		super(parent, duration);
//		parent.owner.addPowerup(new PowerupCommand() {
//			
//			@Override
//			public Powerup execute(float x, float y) {
//				return new FirePowerup(x, y);
//			}
//			
//		}, this);
	}

	@Override
	public void onHitBlock(Block block) {
		if (block.owner != owner) {
			new FireEffect(block, duration - stateTime);
		}
	}
	
	@Override
	public void act(float delta) {
		super.act(delta);
		if (parentActor instanceof Block) {
			((Block) parentActor).damage(DAMAGE_PER_SECOND * delta);
		}
	}
	
	@Override
	protected void actParticles(float delta) {
		particleSpawnTime += delta;
		if (particleSpawnTime >= PARTICLE_SPAWN_RATE) {
			particleSpawnTime = 0f;
			
			for (int i = 0; i < MathUtils.random(PARTICLE_LEAST_SPAWN_AMOUNT, PARTICLE_MAXIMUM_SPAWN_AMOUNT); i++) {
				float width = MathUtils.random(1.25f * Settings.GAME_SCALE, 2f * Settings.GAME_SCALE);
				float angle = MathUtils.random(0, 2 * MathUtils.PI);
				float speed = MathUtils.random(0.75f * Settings.GAME_FPS * Settings.GAME_SCALE, 0.9f * Settings.GAME_FPS * Settings.GAME_SCALE);
				float retardation = speed / 12f;
				Color tempColor;
				if (MathUtils.random() > 0.1) {
					tempColor = new Color(MathUtils.random(0.75f, 1f), MathUtils.random(0f, 1f), 0f, 1f);
				} else {
					float temp = MathUtils.random(0, 1f);
					tempColor = new Color(temp, temp, temp, 1f);
				}
				Particle particle = Particle.particlePool.obtain();
				particle.init(getX() + getWidth() / 2, getY() + getHeight() / 2 - getDepth() + getZ(), width, width, angle, speed, retardation, 0.05f * Settings.GAME_FPS, tempColor);
			}
		}
	}
	
}
