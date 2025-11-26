// Animated glow ring shader
//
// Uniforms (passed from ReScript / Kaplay)
// - u_time: float, k->time (seconds since start)
// - u_resolution: vec2, intrinsic sprite pixel size, e.g. k->vec2(32., 32.)
// - u_thickness: float, base ring center radius in texels (pixels); use small values like 0.7..3
// - u_color: vec3, Kaplay RGB (0..255); divided by 255 here
// - u_intensity: float (0..1-ish), overall alpha multiplier of the glow
// - u_pulse_speed: float, speed of the breathing effect
//
// What it does
// - Like outline2px, compute nearest edge distance in texels by radial sampling.
// - Instead of a fixed 2px ring, render a band centered at u_thickness and
//   modulate its center and width with time to create a breathing glow.
uniform float u_time;
uniform vec2 u_resolution;   // intrinsic sprite pixel size (e.g. 32x32)
uniform float u_thickness;   // base ring radius in pixels (texels)
uniform vec3 u_color;        // Kaplay RGB (0-255)
uniform float u_intensity;   // 0..1-ish strength multiplier
uniform float u_pulse_speed; // ring pulse speed

vec4 frag(vec2 pos, vec2 uv, vec4 color, sampler2D tex) {
    vec4 current_pixel_from_texture = texture2D(tex, uv);

    // Match the alpha behavior we settled on for pixel-art sprites
    const float ALPHA_THRESHOLD = 0.7;
    const float PI = 3.14159265359;
    const int SAMPLE_DIRECTIONS = 16;

    // If the current pixel is effectively opaque, leave it as is.
    if (current_pixel_from_texture.a > ALPHA_THRESHOLD) {
        return current_pixel_from_texture;
    }

    // --- Outline-like distance field (like outline2px, with animation) ---
    vec3 glowColor = u_color / 255.0;
    vec2 texel = 1.0 / u_resolution;

    // Find nearest solid pixel distance in texels
    const int MAX_RADIUS = 32;
    int scanMax = int(min(float(MAX_RADIUS), u_thickness + 6.0)); // small margin beyond ring
    float minDistance = float(MAX_RADIUS);
    for (int p = 1; p <= MAX_RADIUS; p++) {
        if (p > scanMax) break;
        float r = float(p);
        for (int i = 0; i < SAMPLE_DIRECTIONS; i++) {
            float a = float(i) * (2.0 * PI) / float(SAMPLE_DIRECTIONS);
            vec2 dir = vec2(cos(a), sin(a));
            vec2 suv = uv + dir * texel * r;
            if (suv.x >= 0.0 && suv.x <= 1.0 && suv.y >= 0.0 && suv.y <= 1.0) {
                if (texture2D(tex, suv).a > ALPHA_THRESHOLD) {
                    minDistance = min(minDistance, r);
                }
            }
        }
    }

    // Animated ring band centered at u_thickness with a breathing width
    float pulse = 0.5 + 0.5 * sin(u_time * u_pulse_speed);   // 0..1
    float ringCenter = u_thickness + pulse * 0.75;           // shift slightly with time
    float ringWidth  = 1.0 + 0.75 * pulse;                   // band thickness 1..1.75

    // Band mask using two smoothsteps (inner edge and outer edge)
    float inner = smoothstep(ringCenter - ringWidth, ringCenter, minDistance);
    float outer = 1.0 - smoothstep(ringCenter, ringCenter + ringWidth, minDistance);
    float ringMask = clamp(inner * outer, 0.0, 1.0);

    // Intensity modulation
    float glowAlpha = clamp(ringMask * u_intensity, 0.0, 1.0);

    vec4 glowPixel = vec4(glowColor, glowAlpha);
    return mix(current_pixel_from_texture, glowPixel, glowAlpha);
}