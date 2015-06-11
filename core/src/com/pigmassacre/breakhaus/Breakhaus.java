package com.pigmassacre.breakhaus;

import com.badlogic.gdx.Game;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.FPSLogger;
import com.badlogic.gdx.graphics.Pixmap;
import com.badlogic.gdx.graphics.g2d.Batch;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.g2d.TextureRegion;
import com.badlogic.gdx.graphics.glutils.FrameBuffer;
import com.pigmassacre.breakhaus.screens.AbstractScreen;
import com.pigmassacre.breakhaus.screens.IntroLoadingScreen;

public class Breakhaus extends Game {

	public static final String LOG = "mBreak";

	private static final float FBO_SCALER = 1f;
	private static final boolean FBO_ENABLED = true;
	private FrameBuffer fbo = null;
	protected TextureRegion fboRegion = null;

	public SpriteBatch spriteBatch;

	private FPSLogger fpsLogger;

	public Breakhaus() {
	}

	@Override
	public void create() {
		Gdx.app.log(Breakhaus.LOG, "Creating game on " + Gdx.app.getType());
		spriteBatch = new SpriteBatch();
		fpsLogger = new FPSLogger();
	}

	@Override
	public void resize(int width, int height) {
		Gdx.app.log(Breakhaus.LOG, "Resizing game to: " + width + " x " + height);
		super.resize(width, height);

		Gdx.input.setCatchBackKey(true);
		if (getScreen() == null) {
			setScreen(new IntroLoadingScreen(this));
		}
	}

	@Override
	public void render() {
		if (getScreen() != null) {
			AbstractScreen screen = (AbstractScreen) getScreen();
			renderToTexture(screen.stage.getBatch());
			if (fboRegion != null) {
				AbstractScreen.lastTextureRegion = new TextureRegion(fboRegion);
			}
		}

		if (Settings.getDebugMode()) {
			fpsLogger.log();
		}
	}

	private void renderToTexture(Batch spriteBatch) {
		int width = Gdx.graphics.getWidth();
		int height = Gdx.graphics.getHeight();

		if (FBO_ENABLED) {
			if(fbo == null) {
				fbo = new FrameBuffer(Pixmap.Format.RGB565, (int)(width * FBO_SCALER), (int)(height * FBO_SCALER), false);
				fboRegion = new TextureRegion(fbo.getColorBufferTexture());
				fboRegion.flip(false, true);
			}
			fbo.begin();
		}

		super.render();

		if (fbo != null) {
			fbo.end();

			spriteBatch.begin();
			spriteBatch.draw(fboRegion, 0, 0, width, height);
			spriteBatch.end();
		}
	}

	@Override
	public void pause() {
		super.pause();
		Gdx.app.log(LOG, "Pausing game");
	}

	@Override
	public void resume() {
		super.resume();
		Gdx.app.log(LOG, "Resuming game");
	}

	@Override
	public void dispose() {
		super.dispose();
		Gdx.app.log(LOG, "Disposing game");
	}

}