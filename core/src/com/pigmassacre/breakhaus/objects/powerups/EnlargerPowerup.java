package com.pigmassacre.breakhaus.objects.powerups;

import com.pigmassacre.breakhaus.Assets;
import com.pigmassacre.breakhaus.Settings;
import com.pigmassacre.breakhaus.objects.GameActor;
import com.pigmassacre.breakhaus.objects.effects.EnlargerEffect;

public class EnlargerPowerup extends Powerup {

	private float duration = 5f;
	
	public EnlargerPowerup(float x, float y) {
		super(x, y);

		setImage(Assets.getTextureRegion("enlarger"));
		
		setDepth(1 * Settings.GAME_SCALE);
		setWidth(getImage().getRegionWidth() * Settings.GAME_SCALE);
		setHeight(getImage().getRegionHeight() * Settings.GAME_SCALE - getDepth());
	}

	@Override
	protected void onHit(GameActor actor) {
		new EnlargerEffect(actor, duration);
	}
	
}
