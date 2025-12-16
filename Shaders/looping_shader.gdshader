shader_type canvas_item;

uniform vec2 direction;
uniform float speed;
varying vec4 modulate; // Grabs colors after modulate/self-modulate
uniform float custom_time;

void vertex() // Applies to every single vertex
{
	modulate = COLOR;
}

void fragment() // Applies to every single pixel
{
	vec2 move = direction * custom_time * speed;
	COLOR = texture(TEXTURE, UV+move) * modulate;
}
