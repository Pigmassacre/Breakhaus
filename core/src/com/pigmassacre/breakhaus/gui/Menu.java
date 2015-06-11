package com.pigmassacre.breakhaus.gui;

import com.badlogic.gdx.scenes.scene2d.Actor;

import java.util.ArrayList;
import java.util.List;

public class Menu extends Actor {

	public final List<Item> items;

	protected final List<Menu> otherMenus;
	
	protected Item previouslySelectedItem;
	
	protected int position = 0;
	
	public Menu() {
		items = new ArrayList<Item>();
		otherMenus = new ArrayList<Menu>();
		setX(0);
		setY(0);
	}
	
	public float getWidth() {
		cleanup();
		float minX = Integer.MAX_VALUE;
		float maxX = 0;
		for (Item item : items) {
			if (item.getX() < minX)
				minX = item.getX();
			if (item.getX() + item.getWidth() > maxX)
				maxX = item.getX() + item.getWidth();
		}
		return maxX - minX;
	}
	
	public float getHeight() {
		cleanup();
		float minY = Integer.MAX_VALUE;
		float maxY = 0;
		for (Item item : items) {
			if (item.getY() < minY)
				minY = item.getY();
			if (item.getY() + item.getHeight() > maxY)
				maxY = item.getY() + item.getHeight();
		}
		return maxY - minY;
	}
	
	public List<Item> getItems() {
		return items;
	}
	
	public void add(Item item) {
		items.add(item);
		positionItem(item);
	}

	public void positionItem(Item item) {
		
	}
	
	public void remove(Item item) {
		items.remove(item);
	}
	
	public void cleanup() {
		for (Item item : items)
			positionItem(item);
	}
	
	public void registerOtherMenus(List<Menu> otherMenus) {
		if (!this.otherMenus.contains(otherMenus)) {
			for (Menu menu : otherMenus) {
				if (menu != this)
					this.otherMenus.add(menu);
			}
		}
	}
	
	public void act(float delta) {
		List<Item> selectedItems = new ArrayList<Item>();
		
		for (Item item : items) {
			if (item.getSelected()) {
				selectedItems.add(item);
				
				if (item != previouslySelectedItem) {
					previouslySelectedItem = item;
				}
			}
		}
		
		if (selectedItems.size() == 0) {
			previouslySelectedItem = null;
		}
	}
	
}
