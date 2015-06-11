package com.pigmassacre.breakhaus.gui;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.g2d.Batch;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;

public class Backdrop extends Item {
	
	private final ShapeRenderer shapeRenderer;
	
	public Backdrop() {
		shapeRenderer = new ShapeRenderer();
		setColor(0f, 0f, 0f, 0.5f);
	}
	
	@Override
	public void act(float delta) {
		executeActCallback();
	}
	
	public void draw(Batch batch, float parentAlpha) {
		batch.end();
		Gdx.gl.glEnable(GL20.GL_BLEND);
		shapeRenderer.begin(ShapeRenderer.ShapeType.Filled);
		shapeRenderer.setColor(getColor());
		shapeRenderer.rect(getX(), getY(), getWidth(), getHeight());
		shapeRenderer.end();
		Gdx.gl.glDisable(GL20.GL_BLEND);
		batch.begin();
	}
	
}
