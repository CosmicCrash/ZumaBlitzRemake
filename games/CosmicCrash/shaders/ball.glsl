#pragma language glsl3
uniform Image mask;
uniform Image cb_overlay;
uniform float cb_overlay_factor;
uniform vec4 ball_color;
uniform float powerup_transition;
uniform Image powerup_main;
uniform Image powerup_mask;
uniform Image powerup_icon;
uniform mat4 icon_transform;
const float white_level = 0.376;
const float frame_count = 80.0;
const float power_count = 5.0;
const float sprite_scale = 4.0 / 3.0;
const vec4 white = vec4(1.0,1.0,1.0,1.0);

#ifdef VERTEX
	vec4 position(mat4 transform_projection, vec4 vertex_position)
	{
		return transform_projection * vertex_position;
	}
#endif

#ifdef PIXEL
	vec4 colorfunc( Image maintex, Image masktex, vec2 texture_coords )
	{
		vec4 maincolor = Texel(maintex, texture_coords);
		vec4 maskcolor = Texel(masktex, texture_coords);
		return vec4(
			maincolor.rgb + (
				(maincolor.rgb/white_level)*(ball_color.rgb+white_level)
				- white_level/2 - maincolor.rgb
				) * (1.0 - maskcolor.rgb),
			maincolor.a );
	}

	vec2 transform_for_icons(vec2 texture_coords)
	{
		return (icon_transform * vec4(mod(texture_coords.x*frame_count,1.0)-0.5,texture_coords.y-0.5,0.0,0.0)).xy + vec2(0.5,0.5);
	}

	vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords )
	{
		vec4 texcolor = mix(
			colorfunc(tex, mask, texture_coords),
			colorfunc(powerup_main, powerup_mask, texture_coords),
			powerup_transition
		);
		vec2 icon_coords = transform_for_icons(texture_coords);
		vec4 cbcolor = Texel(cb_overlay,icon_coords);
		texcolor = mix(
			vec4(texcolor.rgb * min(1.0,2.0 - cb_overlay_factor*2),texcolor.a),
			white,
			cbcolor.a * min(1.0,cb_overlay_factor*2)
		);
		vec4 pwcolor = Texel(powerup_icon,icon_coords);
		texcolor = mix(
			texcolor,
			vec4(pwcolor.rgb,1.0),
			powerup_transition * pwcolor.a
		);
		return texcolor * color;
	}
#endif