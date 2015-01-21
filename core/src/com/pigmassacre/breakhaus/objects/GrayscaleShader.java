package com.pigmassacre.breakhaus.objects;

import com.badlogic.gdx.Files.FileType;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.files.FileHandle;
import com.badlogic.gdx.graphics.glutils.ShaderProgram;

public class GrayscaleShader {
    static FileHandle vertexShader = Gdx.files.getFileHandle("shaders/grayscale.vert", FileType.Internal);

    static FileHandle fragmentShader = Gdx.files.getFileHandle("shaders/grayscale.frag", FileType.Internal);

    public static ShaderProgram grayscaleShader;
    
    public static void loadShader() {
    	ShaderProgram.pedantic = false;
    	grayscaleShader = new ShaderProgram(vertexShader, fragmentShader);
    	if (!grayscaleShader.isCompiled()) {
    		System.out.println(grayscaleShader.getLog());
    	}
    }
}