package com.pigmassacre.breakhaus.objects.effects;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.math.Intersector;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.math.Rectangle;
import com.badlogic.gdx.scenes.scene2d.Actor;
import com.badlogic.gdx.utils.Array;
import com.pigmassacre.breakhaus.Settings;
import com.pigmassacre.breakhaus.objects.Block;
import com.pigmassacre.breakhaus.objects.GameActor;
import com.pigmassacre.breakhaus.objects.Groups;
import com.pigmassacre.breakhaus.objects.Particle;

public class ShockEffect extends Effect {

	private Rectangle areaOfEffect;
	private int shocksLeft;
	
	public ShockEffect(GameActor parentActor, int shocksLeft) {
		super(parentActor, 0.1f);
		System.out.println(shocksLeft);
		this.shocksLeft = shocksLeft;
		if (parentActor instanceof Block) {
			Block block = (Block) parentActor;
			block.damage(5f);
		}
		setX(parentActor.getX() + (parentActor.getWidth() - getWidth()));
		setY(parentActor.getY() + (parentActor.getHeight() - getHeight()));
		setWidth(parentActor.getWidth() * 3f);
		setHeight(parentActor.getHeight() * 3f); 
		areaOfEffect = new Rectangle(getX(), getY(), getWidth(), getHeight());
		for (int i = 0; i < 5; i++) {
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

	@Override
	public void destroy() {
		if (shocksLeft > 1) {
			Array<Block> blocks = new Array<Block>();
			for (Actor actor : Groups.blockGroup.getChildren()) {
				Block block = (Block) actor;
				if (Intersector.overlaps(areaOfEffect, block.rectangle)) {
					System.out.println("Added to blocks");
					blocks.add(block);
				}
			}
			if (blocks.size > 0) {
				new ShockEffect(blocks.get(MathUtils.random(blocks.size - 1)), --shocksLeft);
			}
		}
		super.destroy();
	}
	
}
