shader_type canvas_item;
// The curtain between screens: the screen fills with squares from the
// top left corner to the bottom right, each one growing from its middle,
// and empties the same way.

uniform vec2 size = vec2(720.0, 1280.0);
uniform float cell = 48.0;
// 0 open, 1 closed.
uniform float progress = 0.0;
uniform vec4 color : source_color = vec4(0.08, 0.04, 0.09, 1.0);

void fragment() {
	vec2 pos = UV * size;
	vec2 c = floor(pos / cell);
	vec2 cells = ceil(size / cell);
	// Where along the sweep this square is, 0 to 1.
	float order = (c.x / cells.x + c.y / cells.y) * 0.5;
	float grow = clamp(progress * 1.6 - order * 0.6, 0.0, 1.0);
	vec2 inside = abs(pos - (c + 0.5) * cell) / (cell * 0.5);
	float covered = step(max(inside.x, inside.y), grow);
	COLOR = vec4(color.rgb, covered * color.a);
}
