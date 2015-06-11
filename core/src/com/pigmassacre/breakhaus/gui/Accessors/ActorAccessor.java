package com.pigmassacre.breakhaus.gui.Accessors;

import aurelienribon.tweenengine.TweenAccessor;
import com.badlogic.gdx.scenes.scene2d.Actor;

public class ActorAccessor implements TweenAccessor<Actor> {
	
	public static final int POSITION_X = 1;
    public static final int POSITION_Y = 2;
    public static final int POSITION_XY = 3;
    public static final int SIZE_W = 4;
    public static final int SIZE_H = 5;
    public static final int SIZE_WH = 6;
    public static final int SCALE_X = 7;
    public static final int SCALE_Y = 8;
    public static final int SCALE_XY = 9;
    public static final int ALPHA = 10;
	
	@Override
	public int getValues(Actor target, int tweenType, float[] returnValues) {
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
	        case SIZE_W:
	        	returnValues[0] = target.getWidth();
	        	return 1;
	        case SIZE_H:
	        	returnValues[0] = target.getHeight();
	        	return 1;
	        case SIZE_WH:
	        	returnValues[0] = target.getWidth();
	        	returnValues[1] = target.getHeight();
	        	return 2;
	        case SCALE_X:
	        	returnValues[0] = target.getScaleX();
	        	return 1;
	        case SCALE_Y:
	        	returnValues[0] = target.getScaleY();
	        	return 1;
	        case SCALE_XY:
	        	returnValues[0] = target.getScaleX();
	        	returnValues[1] = target.getScaleY();
	        	return 2;
	        case ALPHA:
	        	returnValues[0] = target.getColor().a;
	        	return 1;
        default: 
        	assert false; 
        	return -1;
		}
	}

	@Override
	public void setValues(Actor target, int tweenType, float[] newValues) {
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
	        case SIZE_W:
	        	target.setWidth(newValues[0]);
	        	break;
	        case SIZE_H:
	        	target.setHeight(newValues[0]);
	        	break;
	        case SIZE_WH:
	        	target.setWidth(newValues[0]);
	        	target.setHeight(newValues[1]);
	        	break;
	        case SCALE_X:
	        	target.setScaleX(newValues[0]);
	        	break;
	        case SCALE_Y:
	        	target.setScaleY(newValues[0]);
	        	break;
	        case SCALE_XY:
	        	target.setScaleX(newValues[0]);
	        	target.setScaleY(newValues[1]);
	        	break;
	        case ALPHA:
	        	target.getColor().a = newValues[0];
	        	break;
	        default: 
	        	assert false; 
	        	break;
		}
	}
	
}
