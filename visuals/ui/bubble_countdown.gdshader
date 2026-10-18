shader_type canvas_item;
render_mode unshaded;

// 1 when a new 15-second bubble starts, 0 immediately before it expires.
uniform float oxygen_remaining : hint_range(0.0, 1.0) = 1.0;
uniform vec4 depleted_tint : source_color = vec4(0.06, 0.16, 0.23, 0.88);

void fragment() {
	vec4 bubble = texture(TEXTURE, UV);
	float remaining = clamp(oxygen_remaining, 0.0, 1.0);
	// The bright, oxygen-filled part of the bubble shrinks toward the bottom.
	float depleted = step(remaining, 1.0 - UV.y);
	bubble.rgb = mix(bubble.rgb, depleted_tint.rgb, depleted * depleted_tint.a);
	// Thin aqua marker tracks the remaining time (same idea as tool cooldowns).
	float line = 1.0 - step(0.055, abs((1.0 - UV.y) - remaining));
	bubble.rgb = mix(bubble.rgb, vec3(0.67, 0.99, 1.0), line * 0.55);
	COLOR = bubble;
}
