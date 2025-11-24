// Outline (2px) shader
//
// Uniforms (how we pass them from ReScript / Kaplay)
// - u_resolution: vec2, intrinsic sprite pixel size, e.g. k->vec2(32., 32.)
// - u_color: vec3, Kaplay color (r,g,b in 0..255); we divide by 255 in GLSL
//
// What it does
// - For transparent pixels only, we sample around the current UV in a small circle
//   (1–2 texel radii) to detect the nearest solid pixel.
// - If a solid pixel is within 2 texels, we paint a solid ring in u_color.
//
// Why u_resolution matters
// - Texel size in UV space is 1.0 / u_resolution. Keeping this in intrinsic pixels
//   ensures a consistent ring thickness regardless of world scaling.
uniform vec2 u_resolution; // texture size in pixels (e.g. 32x32)
uniform vec3 u_color;      // Kaplay color (0-255 RGB)

// Static 2px red outline strictly following the alpha contour.
// Uses radial sampling to measure the nearest solid-neighbor distance in texels,
// and only draws when distance ∈ (0, 2].
vec4 frag(vec2 pos, vec2 uv, vec4 color, sampler2D tex) {
    const float ALPHA_THRESHOLD = 0.7;
    const float PI = 3.14159265359;
    const int SAMPLE_DIRECTIONS = 8;

    vec4 src = texture2D(tex, uv);
    if (src.a > ALPHA_THRESHOLD) {
        // Inside sprite: keep as-is
        return src;
    }

    // Convert 1 pixel to UV distance to step in whole texels
    vec2 texel = 1.0 / u_resolution; // 1 texel in UV space

    // Find nearest solid neighbor distance in texels (1..2), else large
    float minDistance = 10.0;
    for (int p = 1; p <= 2; p++) {
        float r = float(p);
        for (int i = 0; i < SAMPLE_DIRECTIONS; i++) {
            float a = float(i) * (2.0 * PI) / float(SAMPLE_DIRECTIONS);
            vec2 dir = vec2(cos(a), sin(a));
            vec2 sampleUV = uv + dir * texel * r;
            // Treat out-of-bounds as transparent; do NOT clamp to edge,
            // or you'd sample repeated border colors from the texture.
            if (sampleUV.x >= 0.0 && sampleUV.x <= 1.0 &&
                sampleUV.y >= 0.0 && sampleUV.y <= 1.0) {
                float sa = texture2D(tex, sampleUV).a;
                if (sa > ALPHA_THRESHOLD) {
                    minDistance = min(minDistance, r);
                }
            }
        }
    }

    // Draw only the 2px ring just outside the contour
    if (minDistance <= 2.0) {
        vec3 rgb = u_color / 255.0;
        return vec4(rgb, 1.0);
    }

    // Else keep transparent
    return src;
}

