shader_type canvas_item;
render_mode unshaded;

// 1.0 just after using the tool, 0.0 when ready again. 
uniform float cooldown_remaining : hint_range(0.0, 1.0) = 0.0;
uniform vec4 cover_color : source_color = vec4(0.02, 0.06, 0.10, 0.78);

void fragment() {
	vec4 icon = texture(TEXTURE, UV);
	// The supplied distraction and mine sprites have opaque black backgrounds.
	// Treat those background pixels as transparent in the HUD.
	if (all(lessThan(icon.rgb, vec3(0.01)))) {
		discard;
	}
	float remaining = clamp(cooldown_remaining, 0.0, 1.0);

	if (remaining > 0.0001) {
		// Desaturate the icon while it cannot be used.
		float gray = dot(icon.rgb, vec3(0.299, 0.587, 0.114));
		icon.rgb = mix(icon.rgb, vec3(gray), 0.95);

		// A dark fill recedes from top to bottom as the timer runs out.
		float boundary = 1.0 - remaining;
		float covered = step(boundary, UV.y);
		icon.rgb = mix(icon.rgb, cover_color.rgb, covered * cover_color.a);

		// Small pale line marks the current cooldown progress.
		float progress_line = 1.0 - step(1.0 / 32.0, abs(UV.y - boundary));
		icon.rgb = mix(icon.rgb, vec3(0.75, 0.94, 1.0), progress_line * 0.65);
	}

	COLOR = icon;
}
