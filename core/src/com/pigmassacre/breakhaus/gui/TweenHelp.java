package com.pigmassacre.breakhaus.gui;

import aurelienribon.tweenengine.Tween;
import aurelienribon.tweenengine.TweenEquation;
import aurelienribon.tweenengine.TweenManager;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.math.MathUtils;

import java.util.ArrayList;
import java.util.List;

public class TweenHelp {
	
	private static List<String> setupChoices(boolean left, boolean right, boolean up, boolean down) {
		List<String> choices = new ArrayList<String>();
		if (left)
			choices.add("left");
		if (right)
			choices.add("right");
		if (up)
			choices.add("up");
		if (down)
			choices.add("down");
		return choices;
	}
	
	public static Tween setupSingleItemTweenFrom(Item item, TweenManager tweenManager, TweenEquation ease, float duration, boolean left, boolean right, boolean up, boolean down) {
		List<String> choices = setupChoices(left, right, up, down);
		
		String choice = choices.get(MathUtils.random(choices.size() - 1));
		if (choice == "left") {
			return Tween.from(item, ActorAccessor.POSITION_X, duration).target(-item.getMaxWidth())
				.ease(ease)
				.start(tweenManager);
		} else if (choice == "right") {
			return Tween.from(item, ActorAccessor.POSITION_X, duration).target(Gdx.graphics.getWidth() + item.getMaxWidth())
				.ease(ease)
				.start(tweenManager);
		} else if (choice == "up") {
			return Tween.from(item, ActorAccessor.POSITION_Y, duration).target(-item.getMaxHeight())
				.ease(ease)
				.start(tweenManager);
		} else {
			return Tween.from(item, ActorAccessor.POSITION_Y, duration).target(Gdx.graphics.getHeight() + item.getMaxHeight())
				.ease(ease)
				.start(tweenManager);
		}
	}
	
	public static Tween setupSingleItemTweenTo(Item item, TweenManager tweenManager, TweenEquation ease, float duration, boolean left, boolean right, boolean up, boolean down) {
		List<String> choices = setupChoices(left, right, up, down);
		
		String choice = choices.get(MathUtils.random(choices.size() - 1));
		if (choice == "left") {
			return Tween.to(item, ActorAccessor.POSITION_X, duration).target(-item.getMaxWidth())
				.ease(ease)
				.start(tweenManager);
		} else if (choice == "right") {
			return Tween.to(item, ActorAccessor.POSITION_X, duration).target(Gdx.graphics.getWidth() + item.getMaxWidth())
				.ease(ease)
				.start(tweenManager);
		} else if (choice == "up") {
			return Tween.to(item, ActorAccessor.POSITION_Y, duration).target(-item.getMaxHeight())
				.ease(ease)
				.start(tweenManager);
		} else {
			return Tween.to(item, ActorAccessor.POSITION_Y, duration).target(Gdx.graphics.getHeight() + item.getMaxHeight())
				.ease(ease)
				.start(tweenManager);
		}
	}
	
}
