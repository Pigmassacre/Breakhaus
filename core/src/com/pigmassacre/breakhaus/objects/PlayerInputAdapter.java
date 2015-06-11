package com.pigmassacre.breakhaus.objects;

import com.badlogic.gdx.InputAdapter;
import com.badlogic.gdx.graphics.Camera;
import com.badlogic.gdx.math.Vector3;

public class PlayerInputAdapter extends InputAdapter {

	/* The controlled player. */
	private final Player player;

	/* Camera to translate between screen and world space. */
	private final Camera camera;

	public PlayerInputAdapter(Player player, Camera camera) {
		this.player = player;
		this.camera = camera;
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
		player.getPaddle().setTargetX(coords.x - (player.getPaddle().getWidth() / 2));
		return true;
	}

}
