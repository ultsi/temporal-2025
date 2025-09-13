
// maybe toon lighting here
vec3 get_diffuse_light(
    mat4 p_inv_matrix, vec3 world_pos, vec3 p_light_pos, float p_light_range, vec3 p_light_normal,
    vec3 p_normal, vec3 p_light_color, float p_attenuation) {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
	//DIFFUSE_LIGHT += clamp(dot(NORMAL, LIGHT), 0.0, 1.0) * ATTENUATION * LIGHT_COLOR;

    float snap = 2.0;
    vec3 light_pos = (p_inv_matrix * vec4(p_light_pos, 1.0)).xyz;
    vec3 snapped_world_pos = round(world_pos * snap) /snap;
    light_pos = round(light_pos *snap) / snap;
    float light_length = distance(snapped_world_pos, light_pos);
    light_length = round(light_length * 100.0) / 100.0;
    float light_range = 1.0/p_light_range;
    light_length = 1.0-clamp(light_length, 0.0, light_range) / light_range;

    bool skip = false;
    vec3 frontlight = clamp(dot(p_light_normal*-1.0, p_normal), 0.0, 1.0)* pow(light_length, 2.0) * p_light_color;
    vec3 normal_light = clamp(dot(p_light_normal, p_normal), 0.0, 1.0) * p_attenuation * p_light_color;
    //return vec3((p_light_normal.z + 1.0)*0.5, 0.0, 0.0);
    //return vec3(p_attenuation) * p_light_color;
    return mix(frontlight, normal_light, (p_light_normal.z + 1.0)*0.5);
    if (p_light_normal.z < 0.0 && light_length >= 0.0 && !skip) {
    	return clamp(dot(p_light_normal*-1.0, p_normal), 0.0, 1.0)* pow(light_length, 2.0) * p_light_color;
        //return  pow(light_length, 2.0) * p_light_color;
    } else {
        p_attenuation = round(p_attenuation * 100.0) / 100.0;
        return clamp(dot(p_light_normal, p_normal), 0.0, 1.0) * p_attenuation * p_light_color;
    }

    /*vec3 light_normal = LIGHT;
    if (light_normal.z < 0.0) {
        light_normal.z = -light_normal.z;
    }
    DIFFUSE_LIGHT += clamp(dot(light_normal, NORMAL), 0.0, 1.0) * ATTENUATION * LIGHT_COLOR;
    */
}