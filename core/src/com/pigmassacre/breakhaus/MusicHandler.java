package com.pigmassacre.breakhaus;

import com.badlogic.gdx.audio.Music;
import com.badlogic.gdx.audio.Music.OnCompletionListener;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.utils.ObjectMap;

import java.util.LinkedList;
import java.util.List;

public class MusicHandler {

	private static Music currentMusic;
	private static List<Music> musicList = new LinkedList<Music>();
	private static ObjectMap<Music, String> musicMap = new ObjectMap<Music, String>();
	private static int currentPosition = 0;
	private static boolean shuffle = false;

	public static void addSong(String name, String actualName) {
		Music music = Assets.getMusic(name);
		musicList.add(music);
		musicMap.put(music, actualName);
	}
	
	public static void setSong(String name) {
		if (currentMusic != null) {
			currentMusic.stop();
		}
		currentMusic = Assets.getMusic(name);
	}
	
	public static boolean play() {
		if (currentMusic != null) {
			currentMusic.play();
			currentMusic.setOnCompletionListener(new OnCompletionListener() {
				
				@Override
				public void onCompletion(Music music) {
					next();
				}
				
			});
			return true;
		} else if (!musicList.isEmpty()) {
			if (getShuffle()) {
				currentMusic = musicList.get(MathUtils.random(0, musicList.size() - 1));
			} else {
				
			}
			play();
		}
		return false;
	}
	
	public static boolean pause() {
		if (currentMusic != null) {
			currentMusic.pause();
			return true;
		}
		return false;
	}
	
	public static boolean stop() {
		if (currentMusic != null) {
			currentMusic.stop();
			currentMusic = null;
			return true;
		}
		return false;
	}
	
	public static void next() {
		if (currentMusic != null) {
			currentMusic.stop();
		}
		if (getShuffle()) {
			System.out.println("currPos: " + currentPosition);
			System.out.println("musicList size (-1): " + (musicList.size() - 1));
			int newInt = getRandomWithExclusion(0, musicList.size() - 1, currentPosition);
			System.out.println("newPos: " + newInt);
			currentPosition = newInt;
		} else {
			if (++currentPosition > musicList.size() - 1) {
				currentPosition = 0;
			}
		}
		currentMusic = musicList.get(currentPosition);
		play();
	}
	
	public static void prev() {
		if (currentMusic != null) {
			currentMusic.stop();
		}
		if (--currentPosition < 0) {
			currentPosition = musicList.size() - 1;
		}
		currentMusic = musicList.get(currentPosition);
		play();
	}
	
	public static void setShuffle(boolean shuffle) {
		MusicHandler.shuffle = shuffle;
	}
	
	public static boolean getShuffle() {
		return shuffle;
	}
	
	public static boolean isLooping() {
		if (currentMusic != null) {
			return currentMusic.isLooping();
		}
		return false;
	}
	
	public static void setLooping(boolean looping) {
		if (currentMusic != null) {
			currentMusic.setLooping(looping);
		}
	}
	
	public static boolean isPlaying() {
		if (currentMusic != null) {
			return currentMusic.isPlaying();
		}
		return false;
	}
	
	public static float getVolume() {
		if (currentMusic != null) {
			return currentMusic.getVolume();
		}
		return 0f;
	}
	
	public static void setVolume(float volume) {
		if (currentMusic != null) {
			currentMusic.setVolume(volume);
		}
	}
	
	public static String getNameOfCurrentSong() {
		return musicMap.get(currentMusic);
	}
	
	private static int getRandomWithExclusion(int start, int end, int... exclude) {
	    int random = start + MathUtils.random(end - start + 1 - exclude.length - 1);
	    for (int ex : exclude) {
	        if (random < ex) {
	            break;
	        }
	        random++;
	    }
	    return random;
	}
	
}
