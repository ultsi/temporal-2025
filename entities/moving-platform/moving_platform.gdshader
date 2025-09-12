shader_type spatial;

void vertex() {
	// Called for every vertex the material is visible on.
}

varying vec3 world_pos;

void fragment() {
	world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	ALBEDO = vec3(2.0, 2.0, 0.0);
}

// maybe toon lighting here
void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
	//DIFFUSE_LIGHT += clamp(dot(NORMAL, LIGHT), 0.0, 1.0) * ATTENUATION * LIGHT_COLOR;

	if (!LIGHT_IS_DIRECTIONAL) {
		vec3 light_pos = (INV_VIEW_MATRIX * vec4(LIGHT_POS, 1.0)).xyz;
		vec3 snapped_world_pos = round(world_pos * 4.0) /4.0;
		light_pos = round(light_pos *4.0) / 4.0;
		float light_length = distance(snapped_world_pos, light_pos);
		float light_range = 1.0/LIGHT_RANGE;
		light_length = 1.0-clamp(light_length, 0.0, light_range) / light_range;
		vec3 light_normal = LIGHT;
		if (light_normal.z < 0.0 && light_length >= 0.0) {
			DIFFUSE_LIGHT += pow(light_length, 2.0) * LIGHT_COLOR;
		} else {
			DIFFUSE_LIGHT += clamp(dot(light_normal, NORMAL), 0.0, 1.0) * ATTENUATION * LIGHT_COLOR;
		}

		/*vec3 light_normal = LIGHT;
		if (light_normal.z < 0.0) {
			light_normal.z = -light_normal.z;
		}
		DIFFUSE_LIGHT += clamp(dot(light_normal, NORMAL), 0.0, 1.0) * ATTENUATION * LIGHT_COLOR;
		*/
	}
}