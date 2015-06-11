package com.pigmassacre.breakhaus.gui;

import com.pigmassacre.breakhaus.Settings;

public class GridMenu extends Menu {

	private final float offset;
	
	private final int maxColumnCount;
	
	private int currentRowSize;
	private float currentRowPosition;
	
	public GridMenu(int maxColumnCount) {
		super();
		
		this.maxColumnCount = maxColumnCount;
		
		offset = 2 * Settings.GAME_SCALE;
		
		currentRowSize = 0;
		currentRowPosition = getY();
	}
	
	public void positionItem(Item item) {
		currentRowSize += 1;
		populateGrid(item);
	}
	
	private void populateGrid(Item item) {
		if (currentRowSize > maxColumnCount) {
			currentRowSize = 1;
			currentRowPosition -= item.getHeight() + offset;
		}
		
		if (currentRowSize > 1) {
			item.setX(getX() + (currentRowSize - 1) * item.getWidth() + (currentRowSize - 1) * offset);
		} else {
			item.setX(getX());
		}
		item.setY(currentRowPosition);
	}
	
	public void cleanup() {
		currentRowSize = 0;
		currentRowPosition = getY();
		
		super.cleanup();
	}
	
}
