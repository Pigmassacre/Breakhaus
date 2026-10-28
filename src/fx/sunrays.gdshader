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

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
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
	// Darker the further out, in flat steps.
	float fall = floor(clamp(dist / (max(size.x, size.y) * 0.75), 0.0, 1.0) * 4.0) / 4.0;
	col *= 1.0 - fall * 0.45;
	// Dust: the odd pixel drifting up and blinking.
	vec2 drift = cell + vec2(0.0, floor(clock * 6.0));
	float mote = step(0.9985, hash(floor(drift / vec2(1.0, 1.0))));
	col += mote * ray_b.rgb * 0.8 * (0.5 + 0.5 * sin(clock * 3.0 + cell.x));
	float pulse = 0.5 + 0.5 * sin(clock * 6.0);
	col = mix(col, vec3(0.35, 0.03, 0.06) * (0.7 + 0.3 * on), danger * (0.35 + 0.25 * pulse));
	col += ray_b.rgb * bloom * 1.5;
	COLOR = vec4(col, 1.0);
}
