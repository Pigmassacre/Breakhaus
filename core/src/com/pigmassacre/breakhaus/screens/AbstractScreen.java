package com.pigmassacre.breakhaus.screens;

import aurelienribon.tweenengine.Tween;
import aurelienribon.tweenengine.TweenManager;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.InputMultiplexer;
import com.badlogic.gdx.Screen;
import com.badlogic.gdx.graphics.Camera;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.g2d.Batch;
import com.badlogic.gdx.graphics.g2d.TextureRegion;
import com.badlogic.gdx.scenes.scene2d.Actor;
import com.badlogic.gdx.scenes.scene2d.Stage;
import com.badlogic.gdx.utils.viewport.ScreenViewport;
import com.pigmassacre.breakhaus.Breakhaus;
import com.pigmassacre.breakhaus.gui.ActorAccessor;
import com.pigmassacre.breakhaus.gui.GameActorAccessor;
import com.pigmassacre.breakhaus.gui.Traversal;
import com.pigmassacre.breakhaus.objects.GameActor;

import static com.pigmassacre.breakhaus.Breakhaus.LOG;

public class AbstractScreen implements Screen {

	protected final Breakhaus game;
	
	public Stage stage;
	private TweenManager tweenManager;
	
	private InputMultiplexer inputMultiplexer;
	protected Traversal traversal;
	
	public float timeScale = 1f;
	
	public static TextureRegion lastTextureRegion;
	
	protected String getName() {
		return getClass().getSimpleName();
	}
	
	public AbstractScreen(Breakhaus game) {
		this.game = game;
		this.stage = new Stage(new ScreenViewport(), game.spriteBatch);
		registerTweenAccessor();
		this.traversal = new Traversal(stage.getCamera());
		getInputMultiplexer().addProcessor(traversal);
		getInputMultiplexer().addProcessor(stage);
		registerInputProcessors();
	}
	
	protected void registerInputProcessors() {
		
	}
	
	protected void registerTweenAccessor() {
		Tween.registerAccessor(GameActor.class, new GameActorAccessor());
		Tween.registerAccessor(Actor.class, new ActorAccessor());
	}
	
	public TweenManager getTweenManager() {
		if (tweenManager == null) {
			tweenManager = new TweenManager();
		}
		return tweenManager;
	}
	
	@Override
	public void render(float delta) {
		delta *= timeScale;
		act(delta);
		draw(delta);
	}
	
	public void act(float delta) {
		getTweenManager().update(delta);
		stage.act(delta);
	}
	
	public void draw(float delta) {
		renderClearScreen(delta);
		
		Camera camera = stage.getCamera();
		camera.update();

		Batch batch = stage.getBatch();
		if (batch != null) {
			batch.setProjectionMatrix(camera.combined);
			batch.begin();
			stage.getRoot().draw(batch, 1);
			batch.end();
		}

		postRender(delta);
	}
	
	protected Color backgroundColor = new Color(0.25f, 0.5f, 0.25f, 1f);
	
	public void renderClearScreen(float delta) {
		Gdx.gl.glClearColor(backgroundColor.r, backgroundColor.g, backgroundColor.b, backgroundColor.a);
        Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT);
	}
	
	public void postRender(float delta) {
		
	}

	@Override
	public void resize(int width, int height) {
		stage.getViewport().update(width, height, true);
	}

	public InputMultiplexer getInputMultiplexer() {
		if (inputMultiplexer == null) {
			inputMultiplexer = new InputMultiplexer();
		}
		return inputMultiplexer;
	}
	
	@Override
	public void show() {
		Gdx.app.log(LOG, "Showing screen: " + getName());
		Gdx.input.setInputProcessor(getInputMultiplexer());
	}

	@Override
	public void hide() {
		Gdx.app.log(LOG, "Hiding screen: " + getName());
	}

	@Override
	public void pause() {
		Gdx.app.log(LOG, "Pausing screen: " + getName());
	}

	@Override
	public void resume() {
		Gdx.app.log(LOG, "Resuming screen: " + getName());
	}

	@Override
	public void dispose() {
		Gdx.app.log(LOG, "Disposing screen: " + getName());
		stage.dispose();
	}

}
