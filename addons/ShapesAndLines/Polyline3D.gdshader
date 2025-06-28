shader_type spatial;
render_mode cull_front, unshaded;

uniform float width = 10.0;
uniform bool debug = false;

vec2 rotate90Degrees(vec2 v) {
    return vec2(-v.y, v.x);
}

void vertex() {
	vec4 clip_position = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	
	vec4 position_with_offset = PROJECTION_MATRIX * (MODELVIEW_MATRIX * (vec4(VERTEX, 1.0) + vec4((2.*UV.x-.5) * NORMAL/100.0, 0.)));
	vec2 offset_direction = position_with_offset.xy / position_with_offset.w - clip_position.xy / clip_position.w;
	
	vec2 offset = (rotate90Degrees(normalize(offset_direction * VIEWPORT_SIZE))) / VIEWPORT_SIZE * clip_position.w * width * 2.0;
	POSITION = clip_position + vec4(offset, 0., 0.);
}

void fragment() {
	float xLengthOnScreen = length(vec2(1.0/dFdx(UV).x, 1.0/dFdy(UV).x));
	
	float uvXStretch = length(vec2(dFdx(UV).x, dFdy(UV).x));
	float uvYStretch = length(vec2(dFdx(UV).y, dFdy(UV).y));
	
	ALBEDO = COLOR.rgb;
	
	if (COLOR.a < 1.0) {
		ALPHA = COLOR.a;
	}
	
	if (debug) {
		float xStretch = 2.0 * uvXStretch;
		float yStretch = 2.0 * uvYStretch;
		float diagStretch = 2.0 * length(vec2(dFdx(UV).y + dFdx(UV).x, dFdy(UV).y + dFdy(UV).x));
		
		ALBEDO = vec3(UV.x, UV.y, 0.0);
		if (UV.x < xStretch || UV.x > 1.0 - xStretch || UV.y < yStretch || UV.y > 1.0 - yStretch || abs(UV.x - (1.-UV.y)) < diagStretch/2.0) {
			ALBEDO = vec3(1.,1.,1.);
		}	
	}
}