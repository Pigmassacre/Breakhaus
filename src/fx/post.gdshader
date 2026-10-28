shader_type canvas_item;
// Over the whole game (under the HUD): a shock wave rippling out from a big
// hit, colour fringes on impact, a flash of colour for a pickup or a miss,
// red closing in at the edges when the wall is near, and grey (the original
// game's grayscale shader) when it is all over.

uniform sampler2D screen : hint_screen_texture, filter_nearest;
uniform float aberration = 0.0;
uniform vec2 shock_center = vec2(0.5);
uniform float shock_radius = 0.0;
uniform float shock_strength = 0.0;
uniform float gray = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0);
uniform float flash = 0.0;
uniform float vignette = 0.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 aspect = vec2(SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x, 1.0);
	vec2 d = (uv - shock_center) * aspect;
	float dist = length(d);
	float band = 1.0 - smoothstep(0.0, 0.06, abs(dist - shock_radius));
	uv -= d / (dist + 0.0001) / aspect * band * shock_strength * 0.035;
	float split = aberration + band * shock_strength * 0.006;
	vec3 c;
	c.r = texture(screen, uv + vec2(split, 0.0)).r;
	c.g = texture(screen, uv).g;
	c.b = texture(screen, uv - vec2(split, 0.0)).b;
	float l = dot(c, vec3(0.3, 0.59, 0.11));
	c = mix(c, vec3(l) * vec3(1.0, 0.95, 1.05), gray);
	c = mix(c, flash_color.rgb, flash);
	float v = length((SCREEN_UV - 0.5) * vec2(1.2, 1.0));
	c = mix(c, vec3(0.75, 0.04, 0.1), smoothstep(0.4, 0.85, v) * vignette);
	COLOR = vec4(c, 1.0);
}
