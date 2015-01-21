package com.pigmassacre.breakhaus.gui;

import aurelienribon.tweenengine.TweenAccessor;
import com.pigmassacre.breakhaus.objects.GameActor;

public class GameActorAccessor implements TweenAccessor<GameActor> {

	public static final int POSITION_X = 1;
    public static final int POSITION_Y = 2;
    public static final int POSITION_XY = 3;
	public static final int Z = 4;
	
	@Override
	public int getValues(GameActor target, int tweenType, float[] returnValues) {
		switch (tweenType) {
	        case POSITION_X: 
	        	returnValues[0] = target.getX(); 
	        	return 1;
	        case POSITION_Y: 
	        	returnValues[0] = target.getY(); 
	        	return 1;
	        case POSITION_XY:
	            returnValues[0] = target.getX();
	            returnValues[1] = target.getY();
	            return 2;
	        case Z:
	        	returnValues[0] = target.getZ();
	        	return 1;
        default: 
        	assert false; 
        	return -1;
		}
	}

	@Override
	public void setValues(GameActor target, int tweenType, float[] newValues) {
		switch (tweenType) {
	        case POSITION_X: 
	        	target.setX(newValues[0]); 
	        	break;
	        case POSITION_Y: 
	        	target.setY(newValues[0]); 
	        	break;
	        case POSITION_XY:
	            target.setX(newValues[0]);
	            target.setY(newValues[1]);
	            break;
	        case Z:
	        	target.setZ(newValues[0]);
	        	break;
	        default: 
	        	assert false; 
	        	break;
		}
	}
	
}
