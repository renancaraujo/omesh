// Grain over the finished mesh. The mesh is rendered into an image with
// Picture.toImageSync, bound with setImageSampler, and this shader is drawn
// over the painted rect with drawRect.
#version 460 core
precision highp float;
#include <flutter/runtime_effect.glsl>

uniform vec2 uOrigin;      // rect top-left, logical px
uniform float uDpr;        // physical px per logical px
uniform float uAmount;     // grain peak, fraction of full scale (0 = off)
uniform float uShadows;    // grain weight in shadows
uniform float uMidtones;   // grain weight in midtones
uniform float uHighlights; // grain weight in highlights
uniform float uSeed;       // [0, 1000)
uniform vec2 uImageOrigin; // image top-left, logical px from the rect top-left
uniform vec2 uImageSize;   // image size, image px
uniform vec2 uImageScale;  // image px per logical px, at most uDpr
uniform sampler2D uInput;

out vec4 fragColor;

float hash13(vec3 p3) {
    p3 = fract(p3 * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yxz + 33.33);
    return fract((p3.x + p3.y) * p3.z + (p3.y + p3.z) * p3.x);
}
float toTriangular(float v) {
    float o = v * 2.0 - 1.0;
    return sign(o) * (1.0 - sqrt(1.0 - abs(o)));
}
float response3(float y, vec3 w) {
    float lo = mix(w.x, w.y, smoothstep(0.0, 0.5, y));
    return mix(lo, w.z, smoothstep(0.5, 1.0, y));
}

// Blends the four image pixels around px, for an image drawn larger than
// its own resolution.
vec4 sampleBetweenPixels(vec2 px) {
    vec2 p = px - 0.5;
    vec2 i = floor(p);
    vec2 f = p - i;
    vec2 texel = 1.0 / uImageSize;
    vec4 a = texture(uInput, (i + vec2(0.5, 0.5)) * texel);
    vec4 b = texture(uInput, (i + vec2(1.5, 0.5)) * texel);
    vec4 c = texture(uInput, (i + vec2(0.5, 1.5)) * texel);
    vec4 d = texture(uInput, (i + vec2(1.5, 1.5)) * texel);
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void main() {
    vec2 local = FlutterFragCoord().xy - uOrigin;
    vec2 px = (local - uImageOrigin) * uImageScale;
    vec4 base;
    if (uImageScale.x < uDpr || uImageScale.y < uDpr) {
        base = sampleBetweenPixels(clamp(px, vec2(0.5), uImageSize - 0.5));
    } else {
        base = texture(uInput, px / uImageSize);
    }
    if (uAmount > 0.0 && base.a > 0.0) {
        // Grain on the straight (un-premultiplied) color, weighted by brightness.
        // Each channel moves at most its distance to 0 or 1, so nothing is
        // clipped and the average color stays where it was. A channel outside
        // 0..1, as translucent lab and xyY meshes give, keeps its value.
        vec3 c = base.rgb / base.a;
        vec3 lo = min(c, vec3(0.0));
        vec3 hi = max(c, vec3(1.0));
        vec2 cell = mod(floor(local * uDpr), 4096.0);
        float n = toTriangular(hash13(vec3(cell, uSeed)));
        float y = dot(clamp(c, 0.0, 1.0), vec3(0.2126, 0.7152, 0.0722));
        float s = uAmount * response3(y, vec3(uShadows, uMidtones, uHighlights));
        c += min(vec3(s), min(c - lo, hi - c)) * n;
        base.rgb = c * base.a;
    }
    fragColor = base;
}
