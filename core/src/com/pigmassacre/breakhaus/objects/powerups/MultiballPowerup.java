package com.pigmassacre.breakhaus.objects.powerups;

import com.pigmassacre.breakhaus.Assets;
import com.pigmassacre.breakhaus.Settings;
import com.pigmassacre.breakhaus.objects.GameActor;

public class MultiballPowerup extends Powerup {

//	private float duration = 5f;
	
	public MultiballPowerup(float x, float y) {
		super(x, y);

		setImage(Assets.getTextureRegion("multiball"));
		
		setDepth(1 * Settings.GAME_SCALE);
		setWidth(getImage().getRegionWidth() * Settings.GAME_SCALE);
		setHeight(getImage().getRegionHeight() * Settings.GAME_SCALE - getDepth());
	}

	@Override
	protected void onHit(GameActor actor) {
//		applyEffectToAllBalls(actor, new Powerup.EffectCommand() {
//
//			@Override
//			public void execute(GameActor actor) {
//				new SpeedEffect(actor, duration);				
//			}
//			
//		});
	}
	
}
