shader_type canvas_item;

uniform vec2 direction;
varying vec4 modulate; // Grabs colors after modulate/self-modulate
uniform float offset;

void vertex() // Applies to every single vertex
{
	modulate = COLOR;
}

void fragment() // Applies to every single pixel
{
	vec2 move = direction * offset;
	COLOR = texture(TEXTURE, UV+move) * modulate;
}
