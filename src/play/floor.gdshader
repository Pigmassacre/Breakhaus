shader_type canvas_item;
// The board's floor, under the blocks: a pane of glass on the penthouse (the
// original game's pink glass, its light streaks sliding by), tiles, planks,
// marble or a glowing grid further down. Worked out per art pixel (px board
// units square), so it is as crisp as the sprites. On top of the pattern:
// rings where things hit (they bend it), a pool of light under every ball,
// the line the wall mustn't cross (redder and quicker the closer it is),
// and frost or fire when those are on.

uniform vec2 size = vec2(576.0, 864.0);
uniform float px = 4.0;
uniform vec4 base : source_color = vec4(0.69, 0.13, 0.56, 1.0);
uniform vec4 light : source_color = vec4(0.94, 0.48, 0.85, 1.0);
// Floors.Pattern: 0 glass, 1 tiles, 2 planks, 3 marble, 4 grid.
uniform int pattern = 0;
uniform float clock = 0.0;
uniform float danger = 0.0;
uniform float frost = 0.0;
uniform float fire = 0.0;
uniform float death_y = 624.0;
// x, y, seconds since, strength.
uniform vec4 ripples[8];
uniform int ripple_count = 0;
uniform vec2 lights[8];
uniform int light_count = 0;
// A floor cleared: cracks run out from the middle (0 to 0.5), then the pieces drop away into the dark (to 1).
uniform float shatter = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * noise(p);
		p *= 2.03;
		a *= 0.5;
	}
	return v;
}

// The nearest two points of a jittered grid: their distances, and the nearest one's cell.
vec3 voronoi(vec2 p, float cell_size) {
	vec2 g = floor(p / cell_size);
	float d1 = 1e9;
	float d2 = 1e9;
	float id = 0.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 c = g + vec2(float(x), float(y));
			vec2 point = (c + 0.15 + 0.7 * vec2(hash(c), hash(c + 17.0))) * cell_size;
			float d = length(p - point);
			if (d < d1) {
				d2 = d1;
				d1 = d;
				id = hash(c + 3.0);
			} else if (d < d2) {
				d2 = d;
			}
		}
	}
	return vec3(d1, d2, id);
}

// Steps a 0-1 light into a few flat bands, the way pixel art shades.
float bands(float v, float steps) {
	return floor(v * steps + 0.5) / steps;
}

vec3 glass(vec2 q, vec2 cell) {
	vec3 col = base.rgb;
	// The streaks: sloped bands of light, a broad one and a thin one, in pairs, drifting down.
	float s = q.y - q.x * 0.42 + clock * 14.0;
	float m = mod(s, 460.0);
	float streak = 0.0;
	streak += step(m, 30.0);
	streak += step(44.0, m) * step(m, 54.0);
	float m2 = mod(s + 230.0, 460.0);
	streak += 0.6 * step(m2, 14.0);
	col = mix(col, light.rgb, clamp(streak, 0.0, 1.0) * 0.45);
	// Specks in the glass that catch the light now and then.
	float twinkle = step(0.9993, hash(cell + floor(clock * 1.5)));
	col = mix(col, vec3(1.0), twinkle * 0.6);
	return col;
}

vec3 tiles(vec2 q, vec2 cell) {
	vec2 tile = floor(q / 48.0);
	float checker = mod(tile.x + tile.y, 2.0);
	vec3 col = mix(base.rgb, base.rgb * 0.78, checker);
	// Some tiles light up in turn (a dance floor; elsewhere hardly to be seen).
	float lit = step(0.8, hash(tile + floor(clock * 2.0)));
	col = mix(col, light.rgb, lit * 0.28);
	vec2 inside = mod(q, 48.0);
	float grout = step(inside.x, px) + step(inside.y, px);
	col = mix(col, base.rgb * 0.55, clamp(grout, 0.0, 1.0));
	// A glaze: a soft highlight in the top left of each.
	float shine = step(inside.x, 12.0) * step(inside.y, 12.0) * step(px, inside.x) * step(px, inside.y);
	col = mix(col, light.rgb, shine * 0.15);
	return col;
}

vec3 planks(vec2 q, vec2 cell) {
	float row = floor(q.y / 32.0);
	float offset = hash(vec2(row, 3.0)) * 400.0;
	float x = q.x + offset;
	float board_n = floor(x / 180.0);
	float shade = hash(vec2(board_n, row)) * 0.18;
	float grain = bands(fbm(vec2(x * 0.02, q.y * 0.25 + board_n * 7.0)), 3.0);
	vec3 col = base.rgb * (0.9 - shade + grain * 0.25);
	float seam = step(mod(q.y, 32.0), px) + step(mod(x, 180.0), px);
	col = mix(col, base.rgb * 0.45, clamp(seam, 0.0, 1.0));
	// A long sheen of polish down the middle.
	float polish = 1.0 - smoothstep(0.0, 120.0, abs(q.x - size.x * 0.5 + (q.y - size.y * 0.5) * 0.3));
	col = mix(col, light.rgb, bands(polish, 3.0) * 0.12);
	return col;
}

vec3 marble(vec2 q, vec2 cell) {
	float n = fbm(q * 0.006);
	float vein = abs(sin(q.x * 0.012 + q.y * 0.006 + n * 9.0));
	vec3 col = mix(base.rgb, light.rgb, bands(n, 4.0) * 0.4);
	col = mix(col, base.rgb * 0.6, step(vein, 0.06));
	col = mix(col, base.rgb * 0.75, step(0.06, vein) * step(vein, 0.12) * 0.5);
	vec2 inside = mod(q, 144.0);
	float seam = step(inside.x, px * 0.5) + step(inside.y, px * 0.5);
	col = mix(col, base.rgb * 0.7, clamp(seam, 0.0, 1.0));
	return col;
}

vec3 grid(vec2 q, vec2 cell) {
	vec3 col = base.rgb * 0.75;
	vec2 inside = mod(q, vec2(48.0, 48.0));
	float line = clamp(step(inside.x, px) + step(inside.y, px), 0.0, 1.0);
	// A scan line of light rolling down the grid.
	float scan = 1.0 - smoothstep(0.0, 90.0, abs(mod(clock * 160.0, size.y + 300.0) - 150.0 - q.y));
	col = mix(col, light.rgb, line * (0.35 + 0.5 * bands(scan, 3.0)));
	col += light.rgb * bands(scan, 3.0) * 0.08;
	return col;
}

void fragment() {
	vec2 pos = UV * size;
	vec2 cell = floor(pos / px);
	vec2 p = (cell + 0.5) * px;

	// Ripples push the pattern out of their way and light up as rings.
	vec2 warp = vec2(0.0);
	float ring = 0.0;
	for (int i = 0; i < 8; i++) {
		if (i >= ripple_count) {
			break;
		}
		vec4 r = ripples[i];
		vec2 d = p - r.xy;
		float dist = length(d);
		float radius = r.z * 480.0;
		float band = 1.0 - smoothstep(0.0, 20.0, abs(dist - radius));
		float fade = max(1.0 - r.z / 1.6, 0.0) * r.w;
		warp += d / (dist + 0.001) * band * fade * 12.0;
		ring += band * fade;
	}
	vec2 q = floor((p + warp) / px) * px;

	vec3 col;
	if (pattern == 1) {
		col = tiles(q, cell);
	} else if (pattern == 2) {
		col = planks(q, cell);
	} else if (pattern == 3) {
		col = marble(q, cell);
	} else if (pattern == 4) {
		col = grid(q, cell);
	} else {
		col = glass(q, cell);
	}

	// Darker towards the bottom and the sides, as if lit from the top.
	col *= 1.0 - UV.y * 0.18;
	col *= 1.0 - pow(abs(UV.x - 0.5) * 2.0, 4.0) * 0.14;

	// Pools of light under the balls.
	float glow = 0.0;
	for (int i = 0; i < 8; i++) {
		if (i >= light_count) {
			break;
		}
		glow += 1.0 - smoothstep(0.0, 84.0, length(p - lights[i]));
	}
	col += light.rgb * bands(clamp(glow, 0.0, 1.0), 3.0) * 0.22;
	col = mix(col, light.rgb * 1.2 + 0.1, clamp(ring, 0.0, 1.0) * 0.4);

	// The line, and the red that comes up to it as the wall closes in.
	float pulse = 0.5 + 0.5 * sin(clock * (4.0 + danger * 10.0));
	float above = p.y < death_y ? 1.0 - smoothstep(0.0, 260.0, death_y - p.y) : 0.0;
	col = mix(col, vec3(0.9, 0.08, 0.12), bands(above, 4.0) * danger * (0.25 + 0.3 * pulse));
	float on_line = step(abs(p.y - death_y), px * 0.6) * step(mod(cell.x, 4.0), 1.5);
	col = mix(col, vec3(1.0, 0.25, 0.3), on_line * (0.35 + 0.45 * danger + 0.2 * pulse * danger));

	// Frost creeping in from the edges; a warm flicker with fire.
	if (frost > 0.0) {
		float edge = min(min(p.x, size.x - p.x), min(p.y, size.y - p.y));
		float rime = (1.0 - smoothstep(0.0, 160.0, edge)) + fbm(p * 0.03) * 0.6;
		col = mix(col, vec3(0.75, 0.92, 1.0), clamp(bands(rime, 3.0) * 0.55, 0.0, 0.7) * frost);
		col = mix(col, col * vec3(0.8, 0.95, 1.15), frost * 0.5);
	}
	if (fire > 0.0) {
		float heat = bands(fbm(vec2(p.x * 0.02, p.y * 0.02 + clock * 2.0)), 3.0) * UV.y;
		col += vec3(0.35, 0.12, 0.0) * heat * fire;
	}

	if (shatter > 0.0) {
		vec3 v = voronoi(p, 72.0);
		float reach = length(p - size * 0.5) / length(size * 0.5);
		float cracked = step(reach, shatter * 2.2);
		float crack = step(v.y - v.x, px * 0.9) * cracked;
		col = mix(col, vec3(1.0), crack * 0.85);
		// Each piece goes at its own moment, the middle first.
		float drop = clamp((shatter - 0.5) * 2.0 * 1.6 - v.z * 0.4 - reach * 0.3, 0.0, 1.0);
		col *= 1.0 - bands(drop, 4.0);
	}

	COLOR = vec4(col, 1.0);
}
