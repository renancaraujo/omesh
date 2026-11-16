/*
Copyright (c) 2024, Renan Araujo

Licensed under Mozilla Public License Version 2.0 - https://github.com/renancaraujo/omesh/blob/main/LICENSE

Contains work from tobspr, Licensed under MIT https://github.com/tobspr/GLSL-Color-Spaces/blob/master/LICENSE
*/

#version 460 core

precision highp float;

#include <flutter/runtime_effect.glsl>

#define MAX_VERTICES 128

uniform vec4 uColors[MAX_VERTICES];
uniform vec4 uBiases[MAX_VERTICES / 4];
uniform vec2 uSize;
uniform vec2 uGrid;
uniform float uInterpolationMode;
uniform float uDebugMode;

out vec4 fragColor;

const float lineThickness = 0.8;

/*
From "GLSL Color Space Utility Functions", (c) 2015 tobspr, MIT License.
See the license in omesh.frag.
*/

const mat3 XYZ_2_RGB = (mat3(3.2404542, -0.9692660, 0.0556434, -1.5371385, 1.8760108, -0.2040259, -0.4985314, 0.0415560, 1.0572252));

vec3 xyY_to_rgb(vec3 xyY) {
    float Y = xyY.z;
    float x = Y * xyY.x / xyY.y;
    float z = Y * (1.0 - xyY.x - xyY.y) / xyY.y;
    return XYZ_2_RGB * vec3(x, Y, z);
}

/** End of code from "GLSL Color Space Utility Functions" */

float f2(float t) {
    float d = 6.0 / 29.0;
    return t > d ? t * t * t : 3.0 * d * d * (t - 4.0 / 29.0);
}

vec3 lab_to_rgb(vec3 lab) {
    float Xn = 0.950489;
    float Yn = 1.0;
    float Zn = 0.825188;
    float X = Xn * f2((lab.x + 16.0) / 116.0 + lab.y / 500.0);
    float Y = Yn * f2((lab.x + 16.0) / 116.0);
    float Z = Zn * f2((lab.x + 16.0) / 116.0 - lab.z / 200.0);
    return XYZ_2_RGB * vec3(X, Y, Z);
}

vec3 toRgb(vec3 color) {
    if(uInterpolationMode == 2.0) {
        return xyY_to_rgb(color);
    } else if(uInterpolationMode == 1.0) {
        return color;
    }
    return lab_to_rgb(color);
}

float bias(int index) {
    return uBiases[index / 4][index % 4];
}

float smoothOperator(float x) {
    return smoothstep(0.0, 1.0, x);
}

void main() {
    vec2 pos = FlutterFragCoord().xy;

    vec2 cells = uGrid - 1.0;
    vec2 cellPos = pos / uSize * cells;
    vec2 cell = clamp(floor(cellPos), vec2(0.0), cells - 1.0);
    vec2 uvInSquare = cellPos - cell;

    int width = int(uGrid.x + 0.5);
    int i00 = int(cell.y) * width + int(cell.x);
    int i01 = i00 + 1;
    int i10 = i00 + width;
    int i11 = i10 + 1;

    float b00 = bias(i00);
    float b01 = bias(i01);
    float b10 = bias(i10);
    float b11 = bias(i11);

    float tTop = uvInSquare.x;
    float tBottom = uvInSquare.x;
    float tVertical = uvInSquare.y;
    if(b00 != 0.0 || b01 != 0.0) {
        tTop = smoothOperator(tTop);
    }
    if(b10 != 0.0 || b11 != 0.0) {
        tBottom = smoothOperator(tBottom);
    }
    if(b00 + b01 + b10 + b11 != 0.0) {
        tVertical = smoothOperator(tVertical);
    }

    vec4 top = mix(uColors[i00], uColors[i01], tTop);
    vec4 bottom = mix(uColors[i10], uColors[i11], tBottom);
    vec4 mixed = mix(top, bottom, tVertical);
    vec4 color = vec4(toRgb(mixed.rgb), mixed.a);

    if(uDebugMode > 0.0) {
        vec2 fragCoord = gl_FragCoord.xy;
        float rectWidth = uSize.x / float(uDebugMode);
        float rectHeight = uSize.y / float(uDebugMode);
        float gridX = floor(fragCoord.x / rectWidth) * rectWidth + rectWidth / 2.0;
        float gridY = floor(fragCoord.y / rectHeight) * rectHeight + rectHeight / 2.0;
        if(distance(fragCoord, vec2(gridX, gridY)) < lineThickness) {
            color = vec4(1.0 - color.rgb, 1.0);
        }
    }

    fragColor = color;
}
