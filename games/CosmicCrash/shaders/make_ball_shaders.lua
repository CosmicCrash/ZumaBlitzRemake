local json = [[
{
	"vertexShader": "shaders/ball.glsl",
	"pixelShader": "shaders/ball.glsl",
	"parameters": [
		{
			"type": "image",
			"name": "mask",
			"init": "images/game/ball_%i/mask.png"
		},
		{
			"type": "image",
			"name": "cb_overlay",
			"init": "images/game/ball_%i/cb_overlay.png"
		},
		{
			"type": "number",
			"name": "cb_overlay_factor",
			"init": 0.0
		},
		{
			"type": "color",
			"name": "ball_color",
			"init": [ %.3f, %.3f, %.3f, 1.0 ]
		},
		{
			"type": "number",
			"name": "powerup_transition",
			"init": 0.0
		},
		{
			"type": "image",
			"name": "powerup_main",
			"init": "images/game/ball_powerup/color.png"
		},
		{
			"type": "image",
			"name": "powerup_mask",
			"init": "images/game/ball_powerup/mask.png"
		},
		{
			"type": "image",
			"name": "powerup_icon"
		},
		{
			"type": "transform",
			"name": "icon_transform"
		}
	],
    "internal": false
}
]]

local colors = {
	{ 0.078, 0.396, 0.949 },
	{ 0.996, 0.761, 0.000 },
	{ 0.937, 0.035, 0.122 },
	{ 0.373, 0.871, 0.231 },
	{ 0.729, 0.192, 1.000 },
	{ 1.000, 0.973, 0.820 },
	{ 0.051, 0.012, 0.035 },
	{ 0.165, 0.859, 0.980 },
	{ 0.914, 0.329, 0.125 }
}

for i,v in ipairs(colors) do
	local s = json:format(i,i,v[1],v[2],v[3])
	local f = io.open('ball_'..i..'.json','w+')
	f:write(s)
	f:close()
end