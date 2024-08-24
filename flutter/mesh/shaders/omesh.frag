/*
Copyright (c) 2024, Renan Araujo

Licensed under Mozilla Public License Version 2.0 - https://github.com/renancaraujo/omesh/blob/main/LICENSE

Contains work from tobspr, Licensed under MIT https://github.com/tobspr/GLSL-Color-Spaces/blob/master/LICENSE
*/

#version 460 core

precision highp float;

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform vec2 uv00;
uniform vec2 uv11;
uniform vec4 uColor00;
uniform vec4 uColor01;
uniform vec4 uColor10;
uniform vec4 uColor11;
uniform float uBias00;
uniform float uBias01;
uniform float uBias10;
uniform float uBias11;
uniform float uInterpolationMode;
uniform float uDebugMode;

out vec4 fragColor;

const float lineThickness = 0.8;

/*
GLSL Color Space Utility Functions
(c) 2015 tobspr

-------------------------------------------------------------------------------

The MIT License (MIT)

Copyright (c) 2015

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

-------------------------------------------------------------------------------

Most formulas / matrices are from:
https://en.wikipedia.org/wiki/SRGB

Some are from:
http://www.chilliant.com/rgb2hsv.html
https://www.fourcc.org/fccyvrgb.php
*/

// Define saturation macro, if not already user-defined
#ifndef saturate
#define saturate(v) clamp(v, 0, 1)
#endif

const float SRGB_GAMMA = 1.0 / 2.2;
const float SRGB_INVERSE_GAMMA = 2.2;
const float SRGB_ALPHA = 0.055;

// Used to convert from linear RGB to XYZ space
const mat3 RGB_2_XYZ = (mat3(0.4124564, 0.2126729, 0.0193339, 0.3575761, 0.7151522, 0.1191920, 0.1804375, 0.0721750, 0.9503041));

// Used to convert from XYZ to linear RGB space
const mat3 XYZ_2_RGB = (mat3(3.2404542, -0.9692660, 0.0556434, -1.5371385, 1.8760108, -0.2040259, -0.4985314, 0.0415560, 1.0572252));

const vec3 LUMA_COEFFS = vec3(0.2126, 0.7152, 0.0722);

// Returns the luminance of a !! linear !! rgb color
float get_luminance(vec3 rgb) {
    return dot(LUMA_COEFFS, rgb);
}

// Converts a linear rgb color to a srgb color (approximated, but fast)
vec3 rgb_to_srgb_approx(vec3 rgb) {
    return pow(rgb, vec3(SRGB_GAMMA));
}

// Converts a srgb color to a rgb color (approximated, but fast)
vec3 srgb_to_rgb_approx(vec3 srgb) {
    return pow(srgb, vec3(SRGB_INVERSE_GAMMA));
}

// Converts a single linear channel to srgb
float linear_to_srgb(float channel) {
    if(channel <= 0.0031308)
        return 12.92 * channel;
    else
        return (1.0 + SRGB_ALPHA) * pow(channel, 1.0 / 2.4) - SRGB_ALPHA;
}

// Converts a single srgb channel to rgb
float srgb_to_linear(float channel) {
    if(channel <= 0.04045)
        return channel / 12.92;
    else
        return pow((channel + SRGB_ALPHA) / (1.0 + SRGB_ALPHA), 2.4);
}

// Converts a linear rgb color to a srgb color (exact, not approximated)
vec3 rgb_to_srgb(vec3 rgb) {
    return vec3(linear_to_srgb(rgb.r), linear_to_srgb(rgb.g), linear_to_srgb(rgb.b));
}

// Converts a srgb color to a linear rgb color (exact, not approximated)
vec3 srgb_to_rgb(vec3 srgb) {
    return vec3(srgb_to_linear(srgb.r), srgb_to_linear(srgb.g), srgb_to_linear(srgb.b));
}

// Converts a color from linear RGB to XYZ space
vec3 rgb_to_xyz(vec3 rgb) {
    return RGB_2_XYZ * rgb;
}

// Converts a color from XYZ to linear RGB space
vec3 xyz_to_rgb(vec3 xyz) {
    return XYZ_2_RGB * xyz;
}

// Converts a color from XYZ to xyY space (Y is luminosity)
vec3 xyz_to_xyY(vec3 xyz) {
    float Y = xyz.y;
    float x = xyz.x / (xyz.x + xyz.y + xyz.z);
    float y = xyz.y / (xyz.x + xyz.y + xyz.z);
    return vec3(x, y, Y);
}

// Converts a color from xyY space to XYZ space
vec3 xyY_to_xyz(vec3 xyY) {
    float Y = xyY.z;
    float x = Y * xyY.x / xyY.y;
    float z = Y * (1.0 - xyY.x - xyY.y) / xyY.y;
    return vec3(x, Y, z);
}

// Converts a color from linear RGB to xyY space
vec3 rgb_to_xyY(vec3 rgb) {
    vec3 xyz = rgb_to_xyz(rgb);
    return xyz_to_xyY(xyz);
}

// Converts a color from xyY space to linear RGB
vec3 xyY_to_rgb(vec3 xyY) {
    vec3 xyz = xyY_to_xyz(xyY);
    return xyz_to_rgb(xyz);
}

/** End of code from "GLSL Color Space Utility Functions" */

float f1(float t) {
    float d = 6.0 / 29.0;
    return t > d * d * d ? pow(t, 1.0 / 3.0) : (t / (3.0 * d * d) + 4.0 / 29.0);
}

vec3 xyz_to_lab(vec3 xyz) {
    float Xn = 0.950489;  // reference white
    float Yn = 1.0;
    float Zn = 0.825188;
    float fx = f1(xyz.x / Xn);
    float fy = f1(xyz.y / Yn);
    float fz = f1(xyz.z / Zn);
    float L = 116.0 * fy - 16.0;  // maximum L = 100
    float a = 500.0 * (fx - fy);
    float b = 200.0 * (fy - fz);
    return vec3(L, a, b);
}
float f2(float t) {
    float d = 6.0 / 29.0;
    return t > d ? t * t * t : 3.0 * d * d * (t - 4.0 / 29.0);
}
vec3 lab_to_xyz(vec3 lab) {
    float Xn = 0.950489;
    float Yn = 1.0;
    float Zn = 0.825188;
    float X = Xn * f2((lab.x + 16.0) / 116.0 + lab.y / 500.0);
    float Y = Yn * f2((lab.x + 16.0) / 116.0);
    float Z = Zn * f2((lab.x + 16.0) / 116.0 - lab.z / 200.0);
    return vec3(X, Y, Z);
}
vec3 rgb_to_lab(vec3 rgb) {
    return xyz_to_lab(rgb_to_xyz(rgb));
}
vec3 lab_to_rgb(vec3 lab) {
    return xyz_to_rgb(lab_to_xyz(lab));
}
vec4 interpolateColor(vec4 a, vec4 b, float t) {
    vec4 res;
    res.a = mix(a.a, b.a, t);
    if(uInterpolationMode == 2.0) {
         //  XYY
        vec3 a_xyY = rgb_to_xyY(a.rgb);
        vec3 b_xyY = rgb_to_xyY(b.rgb);
        res.rgb = xyY_to_rgb(mix(a_xyY, b_xyY, t));
    } else if(uInterpolationMode == 1.0) {
        // linear
        res.rgb = mix(a.rgb, b.rgb, t);

    } else {
        // lab
        vec3 a_lab = rgb_to_lab(a.rgb);
        vec3 b_lab = rgb_to_lab(b.rgb);
        res.rgb = lab_to_rgb(mix(a_lab, b_lab, t));
    }
    return res;
}

float ssteppow(float x, float p) {
    float ix = 1.0 - x;
    x = pow(x, p);
    return x / (x + pow(ix, p));
}

// Carlos Sainz
float smoothOperator(float x) {
    // this is too smooth
    // return ssteppow(x * 0.99928 , 1.48);
    return smoothstep(0.0, 1.0, x);
}

void fragment(vec2 uv, vec2 pos, inout vec4 color) {
    float hasSoroundingBias = uBias00 + uBias01 + uBias10 + uBias11;
    vec2 uvInSquare = (uv - uv00) / (uv11 - uv00);

    // if uv is outside the square, return transparent
    if(uvInSquare.x < 0.0 || uvInSquare.x > 1.0 || uvInSquare.y < 0.0 || uvInSquare.y > 1.0) {
        color = vec4(0.0, 0.0, 0.0, 0.0);
        return;
    }

    vec4 a;
    vec4 b;
    if(hasSoroundingBias != 0.0) {
        if(uBias00 != 0.0 || uBias01 != 0.0) {
            a = interpolateColor(uColor00, uColor01, smoothOperator(uvInSquare.x));
        } else {
            a = interpolateColor(uColor00, uColor01, uvInSquare.x);
        }

        if(uBias10 != 0.0 || uBias11 != 0.0) {
            b = interpolateColor(uColor10, uColor11, smoothOperator(uvInSquare.x));
        } else {
            b = interpolateColor(uColor10, uColor11, uvInSquare.x);
        }

        color = interpolateColor(a, b, smoothOperator(uvInSquare.y));
    } else {
        b = interpolateColor(uColor10, uColor11, uvInSquare.x);
        a = interpolateColor(uColor00, uColor01, uvInSquare.x);
        color = interpolateColor(a, b, uvInSquare.y);
    }

}

void debugMode(vec2 uv, vec2 pos, inout vec4 color) {
    vec2 fragCoord = gl_FragCoord.xy;
    float rectWidth = uSize.x / float(uDebugMode);
    float rectHeight = uSize.y / float(uDebugMode);
    float gridX = floor(fragCoord.x / rectWidth) * rectWidth + rectWidth / 2.0;
    float gridY = floor(fragCoord.y / rectHeight) * rectHeight + rectHeight / 2.0;
    float distToCenter = distance(fragCoord, vec2(gridX, gridY));
    float radius = lineThickness * 1;
    if(distToCenter < radius) {
        color = vec4(1.0 - color.rgb, 1.0);
    }
}

void main() {
    vec2 pos = FlutterFragCoord().xy;
    vec2 uv = pos / uSize;
    vec4 color;

    fragment(uv, pos, color);
    if(uDebugMode > 0.0) {
        debugMode(uv, pos, color);
    }
    fragColor = color;
}
