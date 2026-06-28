#include <metal_stdlib>
using namespace metal;

// MARK: - Aurora shader
//
// A stitchable colorEffect that paints soft, flowing aurora curtains. Domain-warped
// fractal noise (FBM) sculpts a vertical band whose height drifts; vertical ray
// streaks texture it; a green→magenta gradient colours it; it's confined to the
// upper sky and faded by `intensity`. See docs/features/prayer-times/aurora.md.

static float hash21(float2 p) {
    p = fract(p * float2(123.34, 345.45));
    p += dot(p, p + 34.345);
    return fract(p.x * p.y);
}

static float vnoise(float2 p) {
    float2 i = floor(p), f = fract(p);
    float2 u = f * f * (3.0 - 2.0 * f);
    float a = hash21(i);
    float b = hash21(i + float2(1, 0));
    float c = hash21(i + float2(0, 1));
    float d = hash21(i + float2(1, 1));
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

static float fbm(float2 p) {
    float v = 0.0, a = 0.5;
    for (int i = 0; i < 5; i++) {
        v += a * vnoise(p);
        p *= 2.02;
        a *= 0.5;
    }
    return v;
}

[[ stitchable ]]
half4 aurora(float2 position, half4 color, float2 size, float time, float intensity) {
    float2 uv = position / size;                  // 0..1, y down (0 = top)
    float t = time * 0.06;

    // Curtain baseline: slowly drifting horizontal noise sets the band's height.
    float drift  = fbm(float2(uv.x * 1.6 + t, t * 0.6));
    float center = 0.16 + 0.20 * drift;           // sits in the upper sky
    float width  = 0.12 + 0.10 * fbm(float2(uv.x * 2.4 - t * 0.8, 7.0));

    // Soft vertical band (gaussian falloff).
    float dy   = (uv.y - center) / width;
    float band = exp(-dy * dy);

    // Vertical ray streaks.
    float rays = fbm(float2(uv.x * 14.0 + t * 1.5, uv.y * 1.5 - t));
    rays = 0.55 + 0.65 * rays;

    float glow = band * rays;

    // Colour: green core → magenta toward the lower edge of the curtain.
    half3 green   = half3(0.25, 1.0, 0.55);
    half3 magenta = half3(0.75, 0.25, 0.95);
    float edge    = clamp((uv.y - center) / width * 0.5 + 0.5, 0.0, 1.0);
    half3 col     = mix(green, magenta, half(edge));

    // Confine to the upper sky and apply the event intensity.
    float sky = smoothstep(0.62, 0.18, uv.y);
    float a   = clamp(glow * sky * intensity * 0.75, 0.0, 1.0);

    return half4(col * half(a), half(a));          // premultiplied
}
