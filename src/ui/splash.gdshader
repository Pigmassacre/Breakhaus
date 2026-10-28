shader_type canvas_item;
// Puts a picture together from tiles: each one pops up from nothing in its
// own place, at its own moment, overshoots a little and settles, flashing
// white as it lands. (The original game flew the pieces of its splash in.)

uniform float progress = 0.0;
uniform float tiles = 10.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float back_out(float t) {
	float c = 2.2;
	return 1.0 + (c + 1.0) * pow(t - 1.0, 3.0) + c * pow(t - 1.0, 2.0);
}

void fragment() {
	vec2 tile = floor(UV * tiles);
	float start = hash(tile) * 0.55;
	float t = clamp((progress - start) / 0.4, 0.0, 1.0);
	float s = t <= 0.0 ? 0.0 : back_out(t);
	vec2 center = (tile + 0.5) / tiles;
	vec2 uv = center + (UV - center) / max(s, 0.0001);
	vec2 inside = (uv - tile / tiles) * tiles;
	vec4 c = texture(TEXTURE, uv);
	float within = step(0.0, inside.x) * step(inside.x, 1.0) * step(0.0, inside.y) * step(inside.y, 1.0);
	c.a *= within * step(0.001, s);
	c.rgb = mix(c.rgb, vec3(1.0), (1.0 - t) * step(0.001, t));
	COLOR = c;
}
