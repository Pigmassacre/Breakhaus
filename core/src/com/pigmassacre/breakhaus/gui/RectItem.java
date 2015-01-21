package com.pigmassacre.breakhaus.gui;

import com.badlogic.gdx.graphics.g2d.Batch;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.math.Rectangle;
import com.pigmassacre.breakhaus.Settings;

public class RectItem extends Item {

	float borderSizeSelected = 2 * Settings.GAME_SCALE;
	float borderSizeChosen = 2 * Settings.GAME_SCALE;
	
	Rectangle selectedRectangle, chosenRectangle, shadowRectangle;
	
	public RectItem() {
		super();
		
		rectangle = new Rectangle(getX(), getY(), getWidth(), getHeight());
		selectedRectangle = new Rectangle(getX() - (borderSizeSelected / 2), getY() - (borderSizeSelected / 2), getWidth() + borderSizeSelected, getHeight() + borderSizeSelected);
		chosenRectangle = new Rectangle(getX() - (borderSizeChosen / 2), getY() - (borderSizeChosen / 2), getWidth() + borderSizeChosen, getHeight() + borderSizeChosen);
		shadowRectangle = new Rectangle(getX() + getShadowOffsetX(), getY() + getShadowOffsetY(), getWidth(), getHeight());
	}
	
	@Override
	public float getMaxWidth() {
		return getWidth() + Math.max(borderSizeSelected, borderSizeChosen);
	}
	
	@Override
	public float getMaxHeight() {
		return getHeight() + Math.max(borderSizeSelected, borderSizeChosen);
	}
	
	public void act(float delta) {
		super.act(delta);
		
		selectedRectangle.setX(getX() - (borderSizeSelected / 2) + offsetX);
		selectedRectangle.setY(getY() - (borderSizeSelected / 2) + offsetY);
		chosenRectangle.setX(getX() - (borderSizeChosen / 2) + offsetX);
		chosenRectangle.setY(getY() - (borderSizeChosen / 2) + offsetY);
		shadowRectangle.setX(getX() + getShadowOffsetX() + offsetX);
		shadowRectangle.setY(getY() + getShadowOffsetY() + offsetY);
	}
	
	public boolean isPointerOverItem(float x, float y) {
		return x >= rectangle.getX() && x <= rectangle.getX() + rectangle.getWidth() && y >= rectangle.getY() && y <= rectangle.getY() + rectangle.getHeight();
	}
	
	public void draw(Batch batch, float parentAlpha) {
		batch.end();
		
		shapeRenderer.begin(ShapeRenderer.ShapeType.Filled);
		
		shapeRenderer.setColor(shadowColor);
		shapeRenderer.rect(shadowRectangle.getX(), shadowRectangle.getY(), shadowRectangle.getWidth(), shadowRectangle.getHeight());

		if (getChosen()) {
			shapeRenderer.setColor(chosenColor);
			shapeRenderer.rect(chosenRectangle.getX(), chosenRectangle.getY(), chosenRectangle.getWidth(), chosenRectangle.getHeight());
		}
			
		if (getSelected()) {
			shapeRenderer.setColor(selectedColor);
			shapeRenderer.rect(selectedRectangle.getX(), selectedRectangle.getY(), selectedRectangle.getWidth(), selectedRectangle.getHeight());
		}

		shapeRenderer.setColor(getColor());
		shapeRenderer.rect(rectangle.getX(), rectangle.getY(), rectangle.getWidth(), rectangle.getHeight());
		
		shapeRenderer.end();
		batch.begin();
		drawBeforeDisabled(batch, parentAlpha);
		batch.end();
		shapeRenderer.begin(ShapeRenderer.ShapeType.Filled);

		if (getDisabled()) {
			shapeRenderer.setColor(disabledColor);
			shapeRenderer.rect(rectangle.getX(), rectangle.getY(), rectangle.getWidth(), rectangle.getHeight());
		}
		
		shapeRenderer.end();
		
		batch.begin();
	}
	
	protected void drawBeforeDisabled(Batch batch, float parentAlpha) {
		
	}
	
}
