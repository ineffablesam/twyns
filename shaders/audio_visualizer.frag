#version 460 core

#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uResolution;
uniform float uTime;
uniform sampler2D uChannel1; // Buffer A (smoothed audio level by distance)

// Shader control parameters from Flutter
uniform float uWarpStrength;    // Controls distortion intensity
uniform float uColorIntensity;  // Controls color brightness
uniform float uSmoothness;      // Controls overall smoothness
uniform float uGlowFalloff;     // Controls outer glow intensity

out vec4 fragColor;

#define PI 3.14159265359

// Enhanced color palette with smoother transitions
vec3 palette(in float t) {
    vec3 a = vec3(0.259,0.369,0.62);
    vec3 b = vec3(0.,0.016,0.067);
    vec3 c = vec3(0.012,0.451,0.953);
    vec3 d = vec3(0.,0.016,0.067);
    return a + b * cos(6.28318 * (c * t + d));
}

// Smooth sampling function for distance-based audio
float smoothSample(sampler2D tex, float distance) {
    float base = texture(tex, vec2(distance, 0.5)).r;

    // Sample surrounding points for ultra-smooth interpolation
    float left1 = texture(tex, vec2(max(distance - 0.003, 0.0), 0.5)).r;
    float left2 = texture(tex, vec2(max(distance - 0.001, 0.0), 0.5)).r;
    float right1 = texture(tex, vec2(min(distance + 0.001, 1.0), 0.5)).r;
    float right2 = texture(tex, vec2(min(distance + 0.003, 1.0), 0.5)).r;

    // Gaussian-like smoothing
    return (base * 0.4 + left1 * 0.15 + left2 * 0.15 + right1 * 0.15 + right2 * 0.15);
}

void main() {
    vec2 coord = FlutterFragCoord().xy;

    // Center and normalize coordinates with sub-pixel precision
    vec2 uv = (2.0 * coord - uResolution.xy) / min(uResolution.x, uResolution.y);

    // Use only distance for circular reaction - NO ANGLE
    float dist = length(uv);

    // Normalize distance to 0-1 range
    float normalizedDist = dist / 1.5;

    // Ultra-smooth audio level sampling based on DISTANCE not angle
    float level = smoothSample(uChannel1, normalizedDist);

    // Enhanced audio response curve
    float responsiveLevel = pow(level, mix(0.4, 0.9, uSmoothness));
    responsiveLevel *= (1.0 + uColorIntensity * 0.5); // Boost based on intensity

    // Smooth distance calculation
    float visualDist = dist * 1.8; // Scale for better visual range

    // Enhanced warping with smoother transitions
    if (visualDist < 1.2) {
        // Inner area: smooth warping based on audio
        float warpIntensity = uWarpStrength * responsiveLevel;
        float warpFactor = mix(8.0, 2.0, warpIntensity); // Dynamic warp range

        // Smooth power curve
        visualDist = pow(visualDist, warpFactor);

        // Apply additional smoothing based on smoothness parameter
        visualDist = mix(visualDist, smoothstep(0.0, 1.2, visualDist), uSmoothness * 0.4);
    } else {
        // Outer glow: smooth exponential falloff
        float falloff = uGlowFalloff * 0.8;
        visualDist = exp(falloff * (1.2 - visualDist));
    }

    // Enhanced color calculation with circular animation
    float colorTime = uTime / 4.0 + dist * 2.0; // Use distance instead of angle for time
    vec3 baseColor = palette(colorTime);

    // Smooth color intensity based on audio
    float colorBoost = 1.0 + uColorIntensity * responsiveLevel * 2.0;
    vec3 finalColor = baseColor * colorBoost * visualDist;

    // Ultra-smooth color clamping
    vec4 color = vec4(finalColor, 1.0);
    color = tanh(color); // Smooth clamping

    // Final smoothness pass
    color = mix(color, smoothstep(0.0, 1.0, color), uSmoothness * 0.3);

    fragColor = color;
}