package com.pigmassacre.breakhaus;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.utils.Array;
import com.pigmassacre.breakhaus.objects.powerups.Powerup;

public class GameOptions {

	private static Color leftColor, rightColor;
	public static Array<Class<? extends Powerup>> enabledPowerups;
	
	public static boolean readyToStart() {
		return GameOptions.getLeftColor() != null && GameOptions.getRightColor() != null;
	}

	public static Color getLeftColor() {
//		if (leftColor == null) {
//			return new Color(Color.WHITE);
//		}
		return leftColor;
	}

	public static void setLeftColor(Color leftColor) {
		GameOptions.leftColor = leftColor;
	}

	public static Color getRightColor() {
//		if (rightColor == null) {
//			return new Color(Color.WHITE);
//		}
		return rightColor;
	}

	public static void setRightColor(Color rightColor) {
		GameOptions.rightColor = rightColor;
	}
	
}
