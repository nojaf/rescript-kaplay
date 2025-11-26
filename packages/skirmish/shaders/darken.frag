// Darken shader: draws a black pixel wherever the sprite texel is opaque.
//
// Purpose
// - Minimal diagnostic shader to verify alpha handling and sampling.
// - If this shows a clean silhouette, your sprite transparency and sampling are good.
//
// Notes
// - Uses a higher alpha threshold (0.7) which is better for pixel-art sprites that
//   may have semi-transparent antialiased edges.
vec4 frag(vec2 pos, vec2 uv, vec4 color, sampler2D tex) {
    const float ALPHA_THRESHOLD = 0.7;
    vec4 src = texture2D(tex, uv);
    if (src.a > ALPHA_THRESHOLD) {
        return vec4(0.0, 0.0, 0.0, 1.0);
    } else {
        return src;
    }
}

