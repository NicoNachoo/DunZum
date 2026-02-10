-- src/Shaders.lua

Shaders = {}

Shaders.SolidColor = love.graphics.newShader[[
    extern vec4 color;
    vec4 effect(vec4 local_color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        vec4 texcolor = Texel(texture, texture_coords);
        if (texcolor.a == 0.0) {
            discard;
        }
        return color;
    }
]]
