package com.pigmassacre.breakhaus.objects.powerups;

import com.pigmassacre.breakhaus.Assets;
import com.pigmassacre.breakhaus.Settings;
import com.pigmassacre.breakhaus.objects.GameActor;
import com.pigmassacre.breakhaus.objects.effects.SpeedEffect;

public class SpeedPowerup extends Powerup {

	private float duration = 5f;
	
	public SpeedPowerup(float x, float y) {
		super(x, y);

		setImage(Assets.getTextureRegion("doublespeed"));
		
		setDepth(1 * Settings.GAME_SCALE);
		setWidth(getImage().getRegionWidth() * Settings.GAME_SCALE);
		setHeight(getImage().getRegionHeight() * Settings.GAME_SCALE - getDepth());
	}

	@Override
	protected void onHit(GameActor actor) {
		applyEffectToAllBalls(actor, new Powerup.EffectCommand() {

			@Override
			public void execute(GameActor actor) {
				new SpeedEffect(actor, duration);				
			}
			
		});
	}
	
}
