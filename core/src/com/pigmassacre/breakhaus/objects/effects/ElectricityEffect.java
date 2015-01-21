package com.pigmassacre.breakhaus.objects.effects;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.math.MathUtils;
import com.pigmassacre.breakhaus.Settings;
import com.pigmassacre.breakhaus.objects.Block;
import com.pigmassacre.breakhaus.objects.GameActor;
import com.pigmassacre.breakhaus.objects.Particle;

public class ElectricityEffect extends Effect {

	public static final float PARTICLE_SPAWN_RATE = 0.55f;
	public static final int PARTICLE_LEAST_SPAWN_AMOUNT = 5;
	public static final int PARTICLE_MAXIMUM_SPAWN_AMOUNT = 5;
	
	private float particleSpawnTime = 0f;
	
	public ElectricityEffect(GameActor parent, float duration) {
		super(parent, duration);
	}
	
	@Override
	public void onHitBlock(Block block) {
		super.onHitBlock(block);
		if (block.owner != parentActor.owner) {
			new ShockEffect(block, 6);
			destroy();
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
				float speed = MathUtils.random(0.9f * Settings.GAME_FPS * Settings.GAME_SCALE, 1.4f * Settings.GAME_FPS * Settings.GAME_SCALE);
				float retardation = speed / 32f;
				Color tempColor;
				float temp = MathUtils.random(0.88f, 1f);
				tempColor = new Color(temp, temp, MathUtils.random(0.4f, 1f), 1f);
				Particle particle = Particle.particlePool.obtain();
				particle.init(getX() + getWidth() / 2, getY() + getHeight() / 2 - getDepth() + getZ(), width, width, angle, speed, retardation, 0.07f * Settings.GAME_FPS, tempColor);
			}
		}
	}

}
