shader_type canvas_item;

// Player position in pixel coordinates (update from GDScript)
uniform vec2 player_position;
// Radius settings in pixels
uniform float glow_radius;
uniform float inner_radius;
uniform float player_health = 1.0;

// Pulsation settings for the dynamic (moving) boundary:
uniform float pulsation_amplitude = 50.0; // How many pixels the boundary moves in/out
uniform float pulsation_speed = 3.0;      // Speed of pulsation

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
    // Convert SCREEN_UV to pixel coordinates.
    vec2 pixel_coords = SCREEN_UV * vec2(textureSize(SCREEN_TEXTURE, 0));
    
    // Calculate distance from the current pixel to the player.
    float distance_from_player = distance(pixel_coords, player_position);
    
    // Calculate a time-based offset that will pulsate the boundary.
    float dynamic_offset = sin(TIME * pulsation_speed) * pulsation_amplitude;
    
    // Adjust both inner and glow radii by the same offset so the transition remains circular.
    float dynamic_inner = inner_radius + dynamic_offset;
    float dynamic_glow  = glow_radius + dynamic_offset;
    
    // Compute an alpha mask:
    // - Fully transparent inside dynamic_inner.
    // - Fully dark outside dynamic_glow.
    // Smoothly interpolates in between.
    float alpha = smoothstep(dynamic_inner, dynamic_glow, distance_from_player);
    
    // Optionally modify alpha based on player_health.
    if (alpha < 1.0) {
        alpha = alpha - (player_health - 1.0);
    }
    
    // Output a black overlay with the computed alpha.
    // With proper blending, the transparent parts reveal the scene underneath.
    COLOR = vec4(0.0, 0.0, 0.0, alpha);
}
