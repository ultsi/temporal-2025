shader_type spatial;
render_mode cull_disabled;

uniform vec3 FLOWER_ALBEDO : source_color;
uniform sampler2D FLUX : source_color, filter_nearest;
uniform vec3 FLUX_POS;
uniform vec3 PLAYER_POS;
uniform float T_TIME;

void vertex() {
	vec3 pos = MODEL_MATRIX[3].xyz;
	vec2 flux_pos = FLUX_POS.xy;
	float f_dist = distance(flux_pos, pos.xy);
	float time = f_dist < 5.0 ? TIME : T_TIME;
	VERTEX.x = VERTEX.x - sin(time) * 0.02;
	VERTEX.z = VERTEX.z - cos(time) * 0.02;

}

void fragment() {
	ALBEDO = FLOWER_ALBEDO;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
