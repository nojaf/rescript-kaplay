# Kaplay Shaders

## Load & Apply

Load once: `k->loadShader("name", ~frag=source)`
Apply in add: `addShader(k, "name", ~uniform=() => {...})`
Apply after: `obj->use(addShader(k, "name", ~uniform=() => {...}))`
Uniform fn returns record, omit `()` on @send methods unless labeled args

## Uniform Types

- Float: `float`
- Vec2: `k->vec2(w, h)`
- Color: `{r:int, g:int, b:int}` or `k->Color.*` or `k->Color.fromHex("#rrggbb")`
  - In GLSL: divide by 255.0 for 0-1 range

## Resolution, Scale, Atlas

- Pixel-accurate needs intrinsic pixel size in `u_resolution` (e.g. 32x32), NOT world size
- `~options={singular: true}` on loadSprite avoids atlas bleeding (doesn't affect shader math)
- `crisp: true` in kaplay initOptions keeps edges sharp

## Alpha Thresholding

Pixel-art: use higher threshold (0.7) to ignore semi-transparent edges

## Example

```rescript
k->loadShader("outline2px", ~frag=outline2pxSource)
gameObj->use(addShader(k, "outline2px", ~uniform=() => {
  "u_resolution": k->vec2(32., 32.), // intrinsic pixels
  "u_color": k->Color.cyan,
}))
```

## Param Mapping

| Uniform | GLSL | ReScript | Notes |
|---------|------|----------|-------|
| u_time | float | k->time | seconds |
| u_resolution | vec2 | k->vec2(32., 32.) | intrinsic sprite pixels |
| u_thickness | float | 0.7..3. | ring center radius texels |
| u_color | vec3 | k->Color.cyan | divide by 255 in shader |
| u_intensity | float | 0.0..1.0 | alpha multiplier |
| u_pulse_speed | float | 1.0..10.0 | animation speed |

## Example Fragments

### darken.frag (debug)
```glsl
vec4 frag(vec2 pos, vec2 uv, vec4 color, sampler2D tex) {
  const float ALPHA_THRESHOLD = 0.7;
  vec4 src = texture2D(tex, uv);
  return src.a > ALPHA_THRESHOLD ? vec4(0.0, 0.0, 0.0, 1.0) : src;
}
```

### outline2px.frag (2px contour)
```glsl
uniform vec2 u_resolution;
uniform vec3 u_color; // 0-255

vec4 frag(vec2 pos, vec2 uv, vec4 color, sampler2D tex) {
  const float ALPHA_THRESHOLD = 0.7;
  const float PI = 3.14159265359;
  const int SAMPLE_DIRECTIONS = 8;

  vec4 src = texture2D(tex, uv);
  if (src.a > ALPHA_THRESHOLD) return src;

  vec2 texel = 1.0 / u_resolution;
  float minDistance = 10.0;
  for (int p = 1; p <= 2; p++) {
    float r = float(p);
    for (int i = 0; i < SAMPLE_DIRECTIONS; i++) {
      float a = float(i) * (2.0 * PI) / float(SAMPLE_DIRECTIONS);
      vec2 dir = vec2(cos(a), sin(a));
      vec2 sampleUV = uv + dir * texel * r;
      if (sampleUV.x >= 0.0 && sampleUV.x <= 1.0 &&
          sampleUV.y >= 0.0 && sampleUV.y <= 1.0) {
        if (texture2D(tex, sampleUV).a > ALPHA_THRESHOLD) {
          minDistance = min(minDistance, r);
        }
      }
    }
  }

  if (minDistance <= 2.0) return vec4(u_color / 255.0, 1.0);
  return src;
}
```

### glow.frag
Animated ring using u_time, u_resolution, u_thickness, u_color, u_intensity, u_pulse_speed

## Troubleshooting

- Jagged ring: increase SAMPLE_DIRECTIONS to 16/24
- Thickness shifts with scale: ensure u_resolution = intrinsic pixels, not world size
- Color mismatch: divide by 255 in GLSL
- Edge bleeding: use `~options={singular: true}` on loadSprite
