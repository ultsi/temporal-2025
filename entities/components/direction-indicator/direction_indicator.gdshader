shader_type spatial;
render_mode unshaded;

uniform float ANGLE: hint_range(-1.0, TAU, 0.01) = 0.0;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	float dist_center = pow(UV.x-0.5, 2.0) + pow(UV.y-0.5, 2.0);
	ALPHA = dist_center > 0.16 && dist_center < 0.18 ? 0.2 : 0.0;
	ALBEDO = vec3(1.0);

	float x_pos = cos(ANGLE)*0.4 + 0.5;
	float y_pos = sin(ANGLE)*0.4 + 0.5;

	if (ANGLE >= 0.0) {
		float dist_angle = pow(UV.x-x_pos, 2.0) + pow(1.0-UV.y-y_pos, 2.0);
		if (dist_angle < 0.005) {
			ALPHA = 1.0;
			ALBEDO = vec3(1.0, 1.0, 0.0);
		}
	}
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
