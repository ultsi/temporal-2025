shader_type spatial;

global uniform float T_TIME = 0.0;
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
	float progress = mod(T_TIME, DURATION) / DURATION;
	if (START_TIME >= 0.0) {
		progress = clamp(T_TIME - START_TIME, 0.0, DURATION)/DURATION;
	} else if (START_TIME >= -1.0) {
		progress = PROGRESS*PROGRESS*PROGRESS;
	}
	//progress *= progress;

	vec2 p = UV - vec2(0.5);
	float dist_center = pow(p.x, 2.0) + pow(p.y, 2.0);

	float dist = pow(0.45-WIDTH*WIDTH, 2.0);
	float lower_bound = dist * progress;
	float upper_bound = (dist+pow(WIDTH, 2.0))*progress;
	if (dist_center > lower_bound && dist_center < upper_bound) {
		ALPHA = 1.0;
	} else {
		ALPHA = 0.0;
	}
	ALBEDO = mix(START_COLOR, END_COLOR, progress);
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
