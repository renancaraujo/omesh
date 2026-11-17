// Grain over the finished mesh. The mesh is rendered into an image with
// Picture.toImageSync, bound with setImageSampler, and this shader is drawn
// over the painted rect with drawRect.
#version 460 core
precision highp float;
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;        // rect size, logical px
uniform vec2 uOrigin;      // rect top-left, logical px
uniform float uDpr;        // image px per logical px
uniform float uAmount;     // grain peak, fraction of full scale (0 = off)
uniform float uShadows;    // grain weight in shadows
uniform float uMidtones;   // grain weight in midtones
uniform float uHighlights; // grain weight in highlights
uniform float uSeed;       // [0, 1000)
uniform sampler2D uInput;

out vec4 fragColor;

float hash13(vec3 p3) {
    p3 = fract(p3 * 0.1031);
    p3 += dot(p3, p3.zyx + 31.32);
    return fract((p3.x + p3.y) * p3.z);
}
float toTriangular(float v) {
    float o = v * 2.0 - 1.0;
    return sign(o) * (1.0 - sqrt(1.0 - abs(o)));
}
float response3(float y, vec3 w) {
    float lo = mix(w.x, w.y, smoothstep(0.0, 0.5, y));
    return mix(lo, w.z, smoothstep(0.5, 1.0, y));
}

void main() {
    vec2 local = FlutterFragCoord().xy - uOrigin;
    vec4 base = texture(uInput, local / uSize);
    if (uAmount > 0.0 && base.a > 0.0) {
        // Grain on the straight (un-premultiplied) color, weighted by brightness.
        vec3 c = clamp(base.rgb / base.a, 0.0, 1.0);
        vec2 cell = mod(floor(local * uDpr), 4096.0);
        float n = toTriangular(hash13(vec3(cell, uSeed)));
        float y = dot(c, vec3(0.2126, 0.7152, 0.0722));
        c = clamp(c + uAmount * response3(y, vec3(uShadows, uMidtones, uHighlights)) * n, 0.0, 1.0);
        base.rgb = c * base.a;
    }
    fragColor = base;
}
