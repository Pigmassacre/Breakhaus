package com.pigmassacre.breakhaus.gui;

import com.badlogic.gdx.Input.Keys;
import com.badlogic.gdx.InputProcessor;
import com.badlogic.gdx.graphics.Camera;
import com.badlogic.gdx.math.Vector3;

import java.util.ArrayList;
import java.util.List;

public class Traversal implements InputProcessor {
	
	public final List<Menu> menus = new ArrayList<Menu>();
	private final Camera camera;
	
	public Traversal(Camera camera) {
		this.camera = camera;
	}
	
	@Override
	public boolean keyDown(int keycode) {
		switch(keycode) {
		case Keys.LEFT:
			traverseSideways(true);
			break;
		case Keys.RIGHT:
			traverseSideways(false);
			break;
		case Keys.UP:
			traverseUpAndDown(true);
			break;
		case Keys.DOWN:
			traverseUpAndDown(false);
			break;
		case Keys.ENTER:
			for (Menu menu : menus) {
				for (Item item : menu.items) {
					if (item.getSelected()) {
						item.executeCallback();
					}
				}
			}
			break;
		}
		return false;
	}

	@Override
	public boolean keyUp(int keycode) {
		return false;
	}

	@Override
	public boolean keyTyped(char character) {
		return false;
	}

	@Override
	public boolean touchDown(int screenX, int screenY, int pointer, int button) {
		selectItems(screenX, screenY);
		Vector3 coords = new Vector3(screenX, screenY, 0);
		camera.unproject(coords);
		for (Menu menu : menus) {
			for (Item item : menu.items) {
				if (item.isPointerOverItem(coords.x, coords.y) && item.getSelected()) {
					item.executeCallback();
				}
			}
		}
		return false;
	}

	@Override
	public boolean touchUp(int screenX, int screenY, int pointer, int button) {
		return false;
	}

	@Override
	public boolean touchDragged(int screenX, int screenY, int pointer) {
		selectItems(screenX, screenY);
		return false;
	}

	@Override
	public boolean mouseMoved(int screenX, int screenY) {
		selectItems(screenX, screenY);
		return false;
	}

	private void selectItems(int screenX, int screenY) {
		Vector3 coords = new Vector3(screenX, screenY, 0);
		camera.unproject(coords);
		
		boolean unselectAll = false;
		Item selectedItem = null;
		
		for (Menu menu : menus) {
			for (Item item : menu.items) {
				if (item.isPointerOverItem(coords.x, coords.y)) {
					item.setSelected(true);
					selectedItem = item;
					unselectAll = true;
				}
			}
		}
		if (unselectAll) {
			for (Menu menu : menus) {
				for (Item item : menu.items) {
					if (item != selectedItem)
						item.setSelected(false);
				}
			}
		}
	}
	
	@Override
	public boolean scrolled(int amount) {
		return false;
	}	

	public void traverseSideways(boolean left) {
		Item selectedItem = getSelectedItem();
		if (selectedItem == null)
			return;
		List<Item> possibleItems = fillListOfPossibleItems();
		List<Item> temp;
		
		temp = new ArrayList<Item>();
		if (left) {
			for (Item item : possibleItems) {
				if (item.getX() + (item.getWidth() / 2) < (selectedItem.getX() + (selectedItem.getWidth() / 2))) {
					temp.add(item);
				}
			}
		} else {
			for (Item item : possibleItems) {
				if (item.getX() + (item.getWidth() / 2) > (selectedItem.getX() + (selectedItem.getWidth() / 2))) {
					temp.add(item);
				}
			}
		}
		possibleItems = temp;

		if (!possibleItems.isEmpty()) {
			float difference;
			
			float leastDifferenceY = Float.MAX_VALUE;
			for (Item item : possibleItems) {
				difference = Math.abs(item.getY() - (item.getHeight() / 2) - (selectedItem.getY() - (selectedItem.getHeight() / 2)));
				if (difference < leastDifferenceY)
					leastDifferenceY = difference;
			}
			
			temp = new ArrayList<Item>();
			for (Item item : possibleItems) {
				if (Math.abs(item.getY() - (item.getHeight() / 2) - (selectedItem.getY() - (selectedItem.getHeight() / 2))) == leastDifferenceY)
					temp.add(item);
			}
			possibleItems = temp;
			
			float leastDifferenceX = Float.MAX_VALUE;
			for (Item item : possibleItems) {
				difference = Math.abs(item.getX() + (item.getWidth() / 2) - (selectedItem.getX() + (selectedItem.getWidth() / 2)));
				if (difference < leastDifferenceX)
					leastDifferenceX = difference;
			}
			
			temp = new ArrayList<Item>();
			for (Item item : possibleItems) {
				if (Math.abs(item.getX() + (item.getWidth() / 2) - (selectedItem.getX() + (selectedItem.getWidth() / 2))) == leastDifferenceX)
					temp.add(item);
			}
			possibleItems = temp;
			
			selectedItem.setSelected(false);
			possibleItems.get(0).setSelected(true);
		}
	}
	
	public void traverseUpAndDown(boolean up) {
		Item selectedItem = getSelectedItem();
		if (selectedItem == null)
			return;
		List<Item> possibleItems = fillListOfPossibleItems();
		List<Item> temp;
		
		temp = new ArrayList<Item>();
		if (up) {
			for (Item item : possibleItems) {
				if (item.getY() - (item.getHeight() / 2) > (selectedItem.getY() - (selectedItem.getHeight() / 2))) {
					temp.add(item);
				}
			}
		} else {
			for (Item item : possibleItems) {
				if (item.getY() - (item.getHeight() / 2) < (selectedItem.getY() - (selectedItem.getHeight() / 2))) {
					temp.add(item);
				}
			}
		}
		possibleItems = temp;
		
		if (!possibleItems.isEmpty()) {
			float difference;
			
			float leastDifferenceX = Float.MAX_VALUE;
			for (Item item : possibleItems) {
				difference = Math.abs(item.getX() + (item.getWidth() / 2) - (selectedItem.getX() + (selectedItem.getWidth() / 2)));
				if (difference < leastDifferenceX)
					leastDifferenceX = difference;
			}
			
			temp = new ArrayList<Item>();
			for (Item item : possibleItems) {
				if (Math.abs(item.getX() + (item.getWidth() / 2) - (selectedItem.getX() + (selectedItem.getWidth() / 2))) == leastDifferenceX)
					temp.add(item);
			}
			possibleItems = temp;
			
			float leastDifferenceY = Float.MAX_VALUE;
			for (Item item : possibleItems) {
				difference = Math.abs(item.getY() - (item.getHeight() / 2) - (selectedItem.getY() - (selectedItem.getHeight() / 2)));
				if (difference < leastDifferenceY)
					leastDifferenceY = difference;
			}
			
			temp = new ArrayList<Item>();
			for (Item item : possibleItems) {
				if (Math.abs(item.getY() - (item.getHeight() / 2) - (selectedItem.getY() - (selectedItem.getHeight() / 2))) == leastDifferenceY)
					temp.add(item);
			}
			possibleItems = temp;
			
			selectedItem.setSelected(false);
			possibleItems.get(0).setSelected(true);
		}
	}
	
	public Item getSelectedItem() {
		for (Menu menu : menus) {
			for (Item item : menu.items) {
				if (item.getSelected())
					return item;
			}
		}
		return null;
	}
	
	public List<Item> fillListOfPossibleItems() {
		List<Item> possibleItems = new ArrayList<Item>();
		for (Menu menu : menus) {
			possibleItems.addAll(menu.items);
		}
		return possibleItems;
	}

}
