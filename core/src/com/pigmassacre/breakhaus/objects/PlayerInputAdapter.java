package com.pigmassacre.breakhaus.objects;

import com.badlogic.gdx.Application;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.InputAdapter;
import com.badlogic.gdx.graphics.Camera;
import com.badlogic.gdx.math.Vector3;

/**
 * Created by Pigmassacre on 2015-06-11.
 */
public class PlayerInputAdapter extends InputAdapter {

	private static final float TOUCH_GRACE_WIDTH_OF_PADDLE = 8f;

	/* The controlled player. */
	private Player player;

	/* Camera to translate between screen and world space. */
	private Camera camera;

	/* The width of the grace area, the area around the middle point of the controlled paddle which will count as the middle point. */
	private float touchGraceSize;

	public PlayerInputAdapter(Player player, Camera camera) {
		this.player = player;
		this.camera = camera;
		touchGraceSize = player.paddle.getWidth() / TOUCH_GRACE_WIDTH_OF_PADDLE;
	}

	@Override
	public boolean touchDown(int screenX, int screenY, int pointer, int button) {
		return updatePaddleMovement(screenX, screenY);
	}

	@Override
	public boolean touchDragged(int screenX, int screenY, int pointer) {
		return updatePaddleMovement(screenX, screenY);
	}

	private boolean updatePaddleMovement(int screenX, int screenY) {
		Vector3 coords = camera.unproject(new Vector3(screenX, screenY, 0));
		player.paddle.setTargetX(coords.x - (player.paddle.getWidth() / 2));
		return true;
	}

}
