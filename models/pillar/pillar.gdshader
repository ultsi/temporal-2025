shader_type spatial;

uniform bool Z_IGNORE_LIGHTING = true;

/*void vertex() {
	// Called for every vertex the material is visible on.
	VERTEX = vec3(ceil(VERTEX.x*8.0)/8.0, ceil(VERTEX.y*8.0)/8.0, ceil(VERTEX.z*8.0)/8.0);
}

float round_to(float a, float prec)
{
	float ten = pow(10, prec);
	return round(a * ten) / ten;
}

void fragment() {
	LIGHT_VERTEX = VERTEX;
}*/

/*void light() {
	float shadow = round_to(ATTENUATION, 1.0);
	float angle = round_to(dot(LIGHT, NORMAL), 1.0);
	DIFFUSE_LIGHT += ALBEDO * shadow * LIGHT_COLOR * max(angle, 0.0);
}*/

void fragment() {
	ALBEDO = vec3(1.0);
}


void light() {
	if (!LIGHT_IS_DIRECTIONAL) {
		vec3 light_normal = LIGHT;
		if (light_normal.z < 0.0) {
			light_normal.z = -light_normal.z;
		}
		DIFFUSE_LIGHT += clamp(dot(light_normal, NORMAL), 0.0, 1.0) * ATTENUATION * LIGHT_COLOR;
	}
}