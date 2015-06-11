package com.pigmassacre.breakhaus.objects;

import com.badlogic.gdx.scenes.scene2d.Actor;

public class Player extends Actor {

	private final String name;

	private Paddle paddle;
	
	public Player(String name) {
		super();
		this.name = name;
	}

	@Override
	public String getName() {
		return name;
	}

	public Paddle getPaddle() {
		return paddle;
	}

	public void setPaddle(Paddle paddle) {
		this.paddle = paddle;
		paddle.setColor(getColor());
	}

	@Override
	public String toString() {
		return "Player: " + name;
	}

}
