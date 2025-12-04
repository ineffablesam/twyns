#version 460 core

#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 iResolution;
uniform float iTime;
uniform sampler2D iChannel0; // Audio texture (512x2)
uniform sampler2D iChannel1; // Previous frame (feedback)

out vec4 fragColor;

// Smooth sampling with edge detection for distance-based audio
float smoothAudioSample(sampler2D tex, float distance) {
    float current = texture(tex, vec2(distance, 0.5)).r;

    // Always sample neighbors for consistent smoothing
    float left = texture(tex, vec2(max(distance - 0.002, 0.0), 0.5)).r;
    float right = texture(tex, vec2(min(distance + 0.002, 1.0), 0.5)).r;

    return (current * 0.6 + left * 0.2 + right * 0.2);
}

void main() {
    vec2 coord = FlutterFragCoord().xy;
    vec2 uv = coord / iResolution.xy;

    // Use Y coordinate for distance-based reaction (circular)
    float audioPos = uv.y; // This will create circular waves from center

    // Ultra-smooth audio sampling based on position, not angle
    float currentLevel = smoothAudioSample(iChannel0, audioPos);

    // Enhanced audio response curve
    currentLevel = pow(currentLevel, 0.7) * 1.8;

    // Get previous frame with smooth sampling
    vec4 oldColor = texture(iChannel1, uv);

    // Adaptive smoothing based on audio activity
    float dynamicDecay = mix(0.7, 0.4, currentLevel); // More persistence for low levels

    // Smooth mixing
    float smoothedLevel = mix(currentLevel, oldColor.r, dynamicDecay);

    // Gentle smoothing pass
    smoothedLevel = smoothstep(0.0, 1.0, smoothedLevel);

    // Output with enhanced continuity
    fragColor = vec4(smoothedLevel, smoothedLevel, smoothedLevel, 1.0);
}