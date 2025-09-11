shader_type spatial;
render_mode unshaded, depth_test_disabled;

void fragment() {
	float x = 1.0/(1920.0)*48.0;
	float y = 1.0/(1056.0)*48.0;
	ALPHA = 0.0;
	if(UV.x < x && UV.y < y) {
		ALBEDO = vec3(1.0, 0.0, 0.0);
		ALPHA = 0.3;
	} else if (UV.x > 1.0-x && UV.y < y){
		ALBEDO = vec3(0.0, 1.0, 0.0);
		ALPHA = 0.3;
	} else if (UV.x < x && UV.y > 1.0-y) {
		ALBEDO = vec3(0.0, 0.0, 1.0);
		ALPHA = 0.3;
	} else if (UV.x > 1.0-x && UV.y > 1.0-y) {
		ALBEDO = vec3(1.0, 0.0, 1.0);
		ALPHA = 0.3;
	}
	// check for orthogonal projection
	ALPHA = PROJECTION_MATRIX[3].w == 1.0 ? ALPHA : 0.0;
}
