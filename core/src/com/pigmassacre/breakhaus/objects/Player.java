package com.pigmassacre.breakhaus.objects;

import com.badlogic.gdx.scenes.scene2d.Actor;

public class Player extends Actor {

	private String name;

	public Paddle paddle;
	
	public Player(String name) {
		super();
		this.name = name;
	}
	
	@Override
	public String toString() {
		return "Player: " + name;
	}

}
