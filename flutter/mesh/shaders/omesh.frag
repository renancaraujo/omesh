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

// Used to convert from XYZ to linear RGB space
const mat3 XYZ_2_RGB = (mat3(3.2404542, -0.9692660, 0.0556434, -1.5371385, 1.8760108, -0.2040259, -0.4985314, 0.0415560, 1.0572252));

// Converts a color from XYZ to linear RGB space
vec3 xyz_to_rgb(vec3 xyz) {
    return XYZ_2_RGB * xyz;
}

// Converts a color from xyY space to XYZ space
vec3 xyY_to_xyz(vec3 xyY) {
    float Y = xyY.z;
    float x = Y * xyY.x / xyY.y;
    float z = Y * (1.0 - xyY.x - xyY.y) / xyY.y;
    return vec3(x, Y, z);
}

// Converts a color from xyY space to linear RGB
vec3 xyY_to_rgb(vec3 xyY) {
    vec3 xyz = xyY_to_xyz(xyY);
    return xyz_to_rgb(xyz);
}

/** End of code from "GLSL Color Space Utility Functions" */

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
vec3 lab_to_rgb(vec3 lab) {
    return xyz_to_rgb(lab_to_xyz(lab));
}

vec3 toRgb(vec3 color) {
    if(uInterpolationMode == 2.0) {
        return xyY_to_rgb(color);
    } else if(uInterpolationMode == 1.0) {
        return color;
    }
    return lab_to_rgb(color);
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
    vec2 uvInSquare = (uv - uv00) / (uv11 - uv00);

    float tTop = uvInSquare.x;
    float tBottom = uvInSquare.x;
    float tVertical = uvInSquare.y;
    if(uBias00 != 0.0 || uBias01 != 0.0) {
        tTop = smoothOperator(tTop);
    }
    if(uBias10 != 0.0 || uBias11 != 0.0) {
        tBottom = smoothOperator(tBottom);
    }
    if(uBias00 + uBias01 + uBias10 + uBias11 != 0.0) {
        tVertical = smoothOperator(tVertical);
    }

    vec4 top = mix(uColor00, uColor01, tTop);
    vec4 bottom = mix(uColor10, uColor11, tBottom);
    vec4 mixed = mix(top, bottom, tVertical);
    color = vec4(toRgb(mixed.rgb), mixed.a);
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
