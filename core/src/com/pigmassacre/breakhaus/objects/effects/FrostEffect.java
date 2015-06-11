package com.pigmassacre.breakhaus.objects.effects;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.math.MathUtils;
import com.pigmassacre.breakhaus.Settings;
import com.pigmassacre.breakhaus.objects.GameActor;
import com.pigmassacre.breakhaus.objects.Paddle;
import com.pigmassacre.breakhaus.objects.Particle;

public class FrostEffect extends Effect {

	private static final float PADDLE_FREEZE_DURATION = 2f;
	private static final float PADDLE_FREEZE_SPEED_REDUCTION = 5f;
	
	public static final float PARTICLE_SPAWN_RATE = 0.6f;
	public static final int PARTICLE_LEAST_SPAWN_AMOUNT = 2;
	public static final int PARTICLE_MAXIMUM_SPAWN_AMOUNT = 2;
	
	private float particleSpawnTime = 0f;
	
	public FrostEffect(GameActor parent, float duration) {
		super(parent, duration);
		if (parent instanceof Paddle) {
			((Paddle) parent).setSpeed(((Paddle) parent).getSpeed() - PADDLE_FREEZE_SPEED_REDUCTION);
		}
	}

	@Override
	public void onHitPaddle(Paddle paddle) {
		if (paddle.owner != owner) {
			new FrostEffect(paddle, PADDLE_FREEZE_DURATION);
		}
	}
	
	@Override
	protected void actParticles(float delta) {
		particleSpawnTime += delta;
		if (particleSpawnTime >= PARTICLE_SPAWN_RATE) {
			particleSpawnTime = 0f;
			
			for (int i = 0; i < MathUtils.random(PARTICLE_LEAST_SPAWN_AMOUNT, PARTICLE_MAXIMUM_SPAWN_AMOUNT); i++) {
				float width = MathUtils.random(2.25f * Settings.GAME_SCALE, 3f * Settings.GAME_SCALE);
				float height = width;
				float angle = MathUtils.random(0, 2 * MathUtils.PI);
				float speed = MathUtils.random(0.2f * Settings.GAME_FPS * Settings.GAME_SCALE, 0.35f * Settings.GAME_FPS * Settings.GAME_SCALE);
				float retardation = speed / 52f;
				Color tempColor = new Color(MathUtils.random(0, 0.2f), MathUtils.random(0.5f, 1f), MathUtils.random(0.85f, 1f), 1f);
				Particle particle = Particle.particlePool.obtain();
				particle.init(getX() + getWidth() / 2 - width / 2, getY() + getHeight() / 2 - height / 2 - getDepth() + getZ(), width, height, angle, speed, retardation, 0.03f * Settings.GAME_FPS, tempColor);
			}
		}
	}
	
	@Override
	public void destroy() {
		super.destroy();
		if (parentActor instanceof Paddle) {
			((Paddle) parentActor).setSpeed(((Paddle) parentActor).getSpeed() + PADDLE_FREEZE_SPEED_REDUCTION);
		}
	}
	
}
