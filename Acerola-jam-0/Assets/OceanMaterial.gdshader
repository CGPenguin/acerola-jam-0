shader_type spatial;
render_mode cull_disabled, specular_schlick_ggx;


uniform float wave_height_1 = 0.4;
uniform float wave_length_1 = 9.0;
uniform float wave_exponent_1 = 0.79;
uniform float wave_velocity_1 = 7.0;
uniform vec2 wave_direction_1 = vec2(1.0, 0.4);
uniform float wave_dispersion_1 = 0.6;

uniform float wave_height_2 = 0.25;
uniform float wave_length_2 = 7.0;
uniform float wave_exponent_2 = 0.69;
uniform float wave_velocity_2 = 5.0;
uniform vec2 wave_direction_2 = vec2(0.2, 0.9);
uniform float wave_dispersion_2 = 0.23;
uniform int number_of_waves = 24;


// Pseudo-random number generator
// Source: https://stackoverflow.com/questions/4200224/random-noise-functions-for-glsl
float rand(vec2 co){
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

float wave_function(vec3 position, float wavelength, float amplitude, float velocity, vec2 wave_direction, float wave_dispersion, int index) {
	float frequency = 2.0 / wavelength;
	float time_scale = velocity * frequency;
	vec3 _position = position + vec3(10000.0, 0, 10000.0); // Offset position to hide sine function 0 point
	wave_direction.x += wave_dispersion * (rand(vec2(float(index))) - 0.5) * 2.0;
	float wave = amplitude * (sin((_position.x * wave_direction.x + _position.z * wave_direction.y) * frequency + TIME * time_scale));
	return wave;
}

float waves_calculation(vec3 position) {
	float offset = 0.0;
	for (int i = 0; i < number_of_waves; i++) {
		float scale = pow(wave_exponent_1, float(i));
		offset += wave_function(position, wave_length_1 * scale, wave_height_1 * scale, wave_velocity_1 * scale, wave_direction_1, wave_dispersion_1, i);
		scale = pow(wave_exponent_2, float(i));
		offset += wave_function(position, wave_length_2 * scale, wave_height_2 * scale, wave_velocity_2 * scale, wave_direction_2, wave_dispersion_2, i);
	}
	return offset;
}


void vertex() {
	
	float cell = 1.0;
	vec3 camera_world_space = INV_VIEW_MATRIX[3].xyz;
    float uvX=float(int(round(camera_world_space.x/cell)));
    float uvY=float(int(round(camera_world_space.z/cell)));

	//vec3 pos = VERTEX;
	vec3 pos = VERTEX + vec3(uvX, 0.0, uvY);
	COLOR = vec4(pos.xyz, 1.0);
	pos = vec3(pos.x, waves_calculation(pos), pos.z);

	VERTEX = pos;
	//VERTEX = (MODELVIEW_MATRIX * vec4(pos, 1.0)).xyz;
}

void fragment() {
	// Scene depth
	vec4 upos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, FRAGCOORD.z, 1.0);
	vec3 pixel_position = upos.xyz / upos.w;
	float distance = -pixel_position.z;

	ROUGHNESS = 0.05 + min(distance * 0.005, 0.7);
    
	vec3 e = vec3(0.001, 0.0, 0.0);
	vec3 normal = normalize(vec3(
		waves_calculation(COLOR.xyz - e) - waves_calculation(COLOR.xyz + e), 2.0 * e.x,
		waves_calculation(COLOR.xyz - e.zyx) - waves_calculation(COLOR.xyz + e.zyx)));
	NORMAL = mix(normal, vec3(0.0, 1.0, 0.0), clamp(distance * 0.001, 0.0, 1.0));
	//ALBEDO = vec3(waves_calculation(COLOR.xyz));
	ALBEDO = vec3(0.001,0.025,0.03);
}