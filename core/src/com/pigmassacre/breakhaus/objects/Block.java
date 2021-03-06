package com.pigmassacre.breakhaus.objects;

import com.badlogic.gdx.audio.Sound;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.g2d.Batch;
import com.pigmassacre.breakhaus.Assets;
import com.pigmassacre.breakhaus.Settings;

public class Block extends GameActor {	

	public static final float STANDARD_Z = 2f * Settings.GAME_SCALE;

	private float health;
	private final float maxHealth;
	private final Color originalColor;
	
	private final Sound onDestroySound;
	
	public Block(float x, float y, Player owner, Color color, DestroyCallback callback, Object callbackData) {
		super();
		
		setImage(Assets.getTextureRegion("block"));
		onDestroySound = Assets.getSound("sound/blockDestroyed.wav");
		
		setDepth(2 * Settings.GAME_SCALE);
		setZ(STANDARD_Z);
		
		setX(x);
		setY(y);
		setWidth(getImage().getRegionWidth() * Settings.GAME_SCALE);
		setHeight(getImage().getRegionHeight() * Settings.GAME_SCALE - getDepth());
		
		rectangle.set(getX(), getY(), getWidth(), getHeight());
				
		this.owner = owner;
		
		maxHealth = 10;
		health = maxHealth;
		
		setColor(color);
		originalColor = color;
		
		shadow = Shadow.shadowPool.obtain();
		shadow.init(this, false);

		setDestroyCallback(callback, callbackData);
	}
	
	@Override
	public void setX(float x) {
		super.setX(x);
		rectangle.setX(getX());
	}
	
	@Override
	public void setY(float y) {
		super.setY(y);
		rectangle.setY(getY());
	}
	
	public void damage(float damage) {
		health -= damage;
		getColor().r = originalColor.r * (health / maxHealth);
		getColor().g = originalColor.g * (health / maxHealth);
		getColor().b = originalColor.b * (health / maxHealth);
	}

	@Override
	public void act(float delta) {
		super.act(delta);
		
		if (health <= 0) {
			destroy();
		}
	}
	
	@Override
	public void destroy() {
		super.destroy();
		onDestroySound.play();
	}
	
	public void destroy(boolean playSound) {
		if (playSound) {
			destroy();
		} else {
			super.destroy();
		}
	}

	@Override
	public void draw(Batch batch, float parentAlpha) {
		Color temp = new Color(batch.getColor());
		batch.setColor(getColor());
		batch.draw(getImage(), getX(), getY() + Settings.getLevelYOffset() + getZ(), getWidth(), getHeight() + getDepth());
		batch.setColor(temp);
		super.draw(batch, parentAlpha);
	}
	
}
