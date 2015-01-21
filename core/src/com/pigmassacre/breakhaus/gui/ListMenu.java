package com.pigmassacre.breakhaus.gui;

public class ListMenu extends Menu {

	public void positionItem(Item item) {
		item.setX(getX() - (item.getWidth() / 2));
		item.setY(getY() + item.getHeight() - (item.getHeight() * 2 * items.indexOf(item)));
	}
	
}
