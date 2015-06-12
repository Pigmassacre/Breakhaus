package com.pigmassacre.breakhaus.objects;

import com.badlogic.gdx.scenes.scene2d.Actor;

public class Player extends Actor {

	private final String name;

	private Paddle paddle;

	private int score;
	
	public Player(String name) {
		super();
		this.name = name;
		score = 0;
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

	public int getScore() {
		return score;
	}

	public void setScore(int score) {
		this.score = score;
	}

	public void addScore(int score) {
		this.score += score;
	}

	@Override
	public String toString() {
		return "Player: " + name;
	}

}
