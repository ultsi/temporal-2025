shader_type spatial;
render_mode unshaded;

global uniform float TIME_SYNCED = 0.0;
uniform float START_TIME = 0.0;
uniform float DURATION: hint_range(0.0, 2.0) = 0.4;
uniform vec3 START_COLOR: source_color;
uniform vec3 END_COLOR: source_color;
uniform float PROGRESS: hint_range(0.0, 1.0) = 0.0;
uniform float WIDTH: hint_range(0.0, 0.5) = 0.1;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	float progress = mod(TIME_SYNCED, DURATION) / DURATION;
	if (START_TIME >= 0.0) {
		progress = clamp(TIME_SYNCED - START_TIME, 0.0, DURATION)/DURATION;
	} else if (START_TIME >= -1.0) {
		progress = PROGRESS*PROGRESS*PROGRESS;
	}
	progress = pow(1.0-progress, 4.0);
	//progress *= progress;

	vec2 p = UV - vec2(0.5);
	float dist_center = pow(p.x, 2.0) + pow(p.y, 2.0);

	float dist = pow(0.45-WIDTH*WIDTH, 2.0);
	float lower_bound = dist * progress;
	float upper_bound = (dist+pow(WIDTH, 2.0))*progress;
	ALBEDO = mix(START_COLOR, END_COLOR, progress);
	if (dist_center > lower_bound && dist_center < upper_bound) {
		if (progress < 0.2) {
			ALPHA = progress*5.0;
		} else {
			//ALPHA = 1.0-progress;
		}
	} else {
		ALPHA = 0.0;
	}
	ALPHA = clamp(ALPHA, 0.0, 0.01);
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
