shader_type spatial;

uniform sampler2D TILE_ATLAS : source_color, filter_nearest;

varying vec2 start_uv;
varying vec2 scale;
varying float alpha;

void vertex() {
	start_uv = INSTANCE_CUSTOM.xy;
	scale = 1.0/INSTANCE_CUSTOM.zw;
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec2 looped = mod(UV*scale, 1.0);
	vec2 uv = start_uv+looped/16.0*1.0;
	vec4 tile = texture(TILE_ATLAS, uv);
	ALBEDO = tile.rgb;
	ALPHA = tile.a;
	alpha = ALPHA;
	//ALBEDO = start_uv.x > 0.000625 ? vec3(1.0) : vec3(0.0);
}

// maybe toon lighting here
void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
	//DIFFUSE_LIGHT += clamp(dot(NORMAL, LIGHT), 0.0, 1.0) * ATTENUATION * LIGHT_COLOR;

	if (!LIGHT_IS_DIRECTIONAL && alpha > 0.01) {
		vec3 light_normal = LIGHT;
		if (light_normal.z < 0.0) {
			DIFFUSE_LIGHT += (ATTENUATION+1.0) * LIGHT_COLOR;
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
