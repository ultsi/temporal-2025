shader_type spatial;
render_mode cull_disabled;

uniform vec3 GRASS_ALBEDO : source_color;
global uniform vec3 PLAYER_POS;
global uniform float T_TIME;
global uniform float T_TIME_DT;
global uniform float T_MAX_TIME;

void vertex() {
	vec4 clipSpacePos = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec3 ndc = clipSpacePos.xyz / clipSpacePos.w;
	vec2 screen_uv = ndc.xy * 0.5 + 0.5;

	float time = TIME;

	vec3 pos = MODEL_MATRIX[3].xyz;
	VERTEX = VERTEX * (0.6-UV.y);
	VERTEX.x = VERTEX.x + sin(time) * 0.05 * step( UV.y, 0.1);
	VERTEX.z = VERTEX.z + cos(time) * 0.05 * step( UV.y, 0.1);
	VERTEX.y *= 1.0 + TIME/T_MAX_TIME;

	float dist = distance(PLAYER_POS, pos);
	if (dist < 2.0) {
		float s = pos.x - PLAYER_POS.x;
		//VERTEX.x = VERTEX.x + s * (1.0-dist/2.0) * (0.6-UV.y);
	}
}

void fragment() {
	ALBEDO = GRASS_ALBEDO * (0.6-UV.y);
	ALBEDO *= COLOR.rgb;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}


/*void light() {
	if (!LIGHT_IS_DIRECTIONAL) {
		vec3 light_normal = LIGHT;
		if (light_normal.z < 0.0) {
			light_normal.z = -light_normal.z;
		}
		DIFFUSE_LIGHT += clamp(dot(light_normal, NORMAL), 0.0, 1.0) * ATTENUATION * LIGHT_COLOR;
	}
}*/
