shader_type canvas_item;
// The curtain between screens: the screen fills with tiles, each one
// growing from its middle, in an order that changes from one curtain to
// the next (`pattern`), and the tiles are squares, diamonds or dots
// (`shape`). Opening, `flip` turns the order round, so the tiles empty
// from where they first filled and the sweep carries on through.

uniform vec2 size = vec2(720.0, 1280.0);
uniform float cell = 48.0;
// 0 open, 1 closed.
uniform float progress = 0.0;
// 0 corner to corner, 1 out from the middle, 2 rows snaking down, 3 at random,
// 4 round like a clock hand, 5 in from the sides, 6 up from the bottom in a wave.
uniform int pattern = 0;
// 0 squares, 1 diamonds, 2 dots.
uniform int shape = 0;
uniform float flip = 0.0;
uniform vec4 color : source_color = vec4(0.08, 0.04, 0.09, 1.0);

// Dave Hoskins' hash: no sine, so the same on every GPU.
float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

// Where this tile comes in its curtain's order, 0 to 1.
float order(vec2 c, vec2 cells) {
	vec2 uv = (c + 0.5) / cells;
	vec2 mid = uv - 0.5;
	mid.x *= cells.x / cells.y;
	float aspect = cells.x / cells.y;
	if (pattern == 1) {
		return length(mid) / length(vec2(aspect, 1.0) * 0.5);
	} else if (pattern == 2) {
		float x = mod(c.y, 2.0) < 1.0 ? uv.x : 1.0 - uv.x;
		return (c.y + x) / cells.y;
	} else if (pattern == 3) {
		return hash(c + 17.0);
	} else if (pattern == 4) {
		return fract(atan(mid.x, -mid.y) / 6.2831853 + 0.5);
	} else if (pattern == 5) {
		return 1.0 - abs(uv.x - 0.5) * 2.0;
	} else if (pattern == 6) {
		return clamp(1.0 - uv.y + sin(uv.x * 9.0) * 0.08, 0.0, 1.0);
	}
	return (uv.x + uv.y) * 0.5;
}

void fragment() {
	vec2 pos = UV * size;
	vec2 c = floor(pos / cell);
	vec2 cells = ceil(size / cell);
	float o = mix(order(c, cells), 1.0 - order(c, cells), flip);
	float grow = clamp(progress * 1.6 - o * 0.6, 0.0, 1.0);
	vec2 inside = abs(pos - (c + 0.5) * cell) / (cell * 0.5);
	float reach = max(inside.x, inside.y);
	if (shape == 1) {
		reach = (inside.x + inside.y) * 0.5;
	} else if (shape == 2) {
		reach = length(inside) * 0.707;
	}
	float covered = step(reach, grow);
	COLOR = vec4(color.rgb, covered * color.a);
}
