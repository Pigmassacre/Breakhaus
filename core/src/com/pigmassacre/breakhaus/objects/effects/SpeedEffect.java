package com.pigmassacre.breakhaus.objects.effects;

import com.pigmassacre.breakhaus.objects.GameActor;

public class SpeedEffect extends Effect {

	public SpeedEffect(GameActor parent, float duration) {
		super(parent, duration);
	}

	@Override
	public void act(float delta) {
		super.act(delta);
		
		if (parentActor.owner == owner) {
			parentActor.move(delta);
		}
	}
	
}
