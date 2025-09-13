shader_type spatial;

uniform vec3 ALBEDO_COLOR : source_color = vec3(1.0);

#include "res://materials/shaders/lighting_test.gdshaderinc"

void vertex() {
	// Called for every vertex the material is visible on.
}

varying vec3 world_pos;

void fragment() {
	world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	ALBEDO = ALBEDO_COLOR;
}

// maybe toon lighting here
void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
	//DIFFUSE_LIGHT += clamp(dot(NORMAL, LIGHT), 0.0, 1.0) * ATTENUATION * LIGHT_COLOR;

	if (!LIGHT_IS_DIRECTIONAL) {
		DIFFUSE_LIGHT += get_diffuse_light(INV_VIEW_MATRIX, world_pos, LIGHT_POS, LIGHT_RANGE, LIGHT, NORMAL, LIGHT_COLOR, ATTENUATION);

		/*vec3 light_normal = LIGHT;
		if (light_normal.z < 0.0) {
			light_normal.z = -light_normal.z;
		}
		DIFFUSE_LIGHT += clamp(dot(light_normal, NORMAL), 0.0, 1.0) * ATTENUATION * LIGHT_COLOR;
		*/
	}
}