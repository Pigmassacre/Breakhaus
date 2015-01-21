package com.pigmassacre.breakhaus.objects.effects;

import com.pigmassacre.breakhaus.Settings;
import com.pigmassacre.breakhaus.objects.GameActor;
import com.pigmassacre.breakhaus.objects.Player;

public class ReducerEffect extends Effect {

	private Player effectOwner;
//	private float heightChange;
	
	public ReducerEffect(GameActor parentActor, float duration) {
		super(parentActor, duration);
		effectOwner = owner;
//		float oldHeight = effectOwner.paddle.getHeight();
		effectOwner.paddle.addHeight(-6 * Settings.GAME_SCALE);
//		heightChange = oldHeight - effectOwner.paddle.getHeight();
	}
	
	@Override
	public void destroy() {
		effectOwner.paddle.addHeight(6 * Settings.GAME_SCALE);
		super.destroy();
	}

}
