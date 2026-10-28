shader_type canvas_item;
// The rays turning slowly behind everything (the original game's Sunrays,
// which spun a big image; this works each art pixel out on its own, so the
// edges stay crisp stair steps however far round they have turned). Two
// tones of the floor's theme, darker away from the middle, a few motes of
// dust drifting through, and red seeping in with the danger.

uniform vec2 size = vec2(720.0, 1280.0);
uniform float px = 4.0;
uniform vec2 center = vec2(360.0, 500.0);
uniform vec4 ray_a : source_color = vec4(0.16, 0.06, 0.2, 1.0);
uniform vec4 ray_b : source_color = vec4(0.24, 0.09, 0.29, 1.0);
uniform float rays = 12.0;
uniform float turn = 0.0;
uniform float clock = 0.0;
uniform float danger = 0.0;
// Brightens it all for a moment (a floor cleared).
uniform float bloom = 0.0;
// How far the dust has drifted up, in art pixels (the backdrop runs it on, faster as you fall
// between floors); the nearer layers move further.
uniform float rise = 0.0;
// Fever: a rainbow running smoothly round behind the rays.
uniform float fever = 0.0;

vec3 hue(float h) {
	return clamp(abs(mod(h * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
}

float hash(vec2 p) {
	// Dave Hoskins' hash without sine: sin() of big numbers loses its precision on a GPU, and the
	// sine hash goes flat away from the top-left corner.
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void fragment() {
	vec2 cell = floor(UV * size / px);
	vec2 p = (cell + 0.5) * px - center;
	float angle = atan(p.y, p.x) + turn;
	float dist = length(p);
	// Rays that widen as they go: alternate slices of the circle.
	float slice = fract(angle / TAU * rays);
	float on = step(0.5, slice);
	vec3 col = mix(ray_a.rgb, ray_b.rgb, on);
	// Fever: the hue runs smoothly round the circle and turns with time; the rays only shade it.
	vec3 rainbow = hue(fract(angle / TAU + clock * 0.15)) * (0.3 + 0.08 * on);
	col = mix(col, rainbow, fever);
	// Darker the further out, in flat steps.
	float fall = floor(clamp(dist / (max(size.x, size.y) * 0.75), 0.0, 1.0) * 4.0) / 4.0;
	col *= 1.0 - fall * 0.45;
	// Dust in three layers, far to near: the nearer, the bigger its pixels, the faster it drifts up
	// and the brighter it is; each its own scatter, blinking.
	for (int layer = 0; layer < 3; layer++) {
		float l = float(layer);
		float big = layer == 2 ? 2.0 : 1.0;
		float speed = l == 0.0 ? 0.35 : (l == 1.0 ? 1.0 : 2.4);
		// Its grid slides up smoothly (not a whole pixel at a time): the motes keep their art-pixel
		// size but move like everything else does.
		float lift = mod(rise * speed * px, 4096.0 * px * big);
		vec2 dust_cell = floor((UV * size + vec2(0.0, lift)) / (px * big));
		vec2 drift = dust_cell + vec2(l * 1013.0, 0.0);
		float density = l == 0.0 ? 0.9985 : (l == 1.0 ? 0.9992 : 0.9988);
		float mote = step(density, hash(drift));
		float twinkle = 0.5 + 0.5 * sin(clock * (2.0 + l) + dust_cell.x * 1.7 + l);
		col += mote * ray_b.rgb * (0.35 + l * 0.4) * twinkle;
	}
	float pulse = 0.5 + 0.5 * sin(clock * 6.0);
	col = mix(col, vec3(0.35, 0.03, 0.06) * (0.7 + 0.3 * on), danger * (0.35 + 0.25 * pulse));
	col += ray_b.rgb * bloom * 1.5;
	COLOR = vec4(col, 1.0);
}
