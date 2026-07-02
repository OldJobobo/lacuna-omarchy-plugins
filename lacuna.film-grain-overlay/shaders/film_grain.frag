#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
  mat4 qt_Matrix;
  float qt_Opacity;
  float time;
  float intensity;
  float grainSize;
  float accentBlend;
  vec4 grainColor;
  vec2 resolution;
};

float hash(vec2 p) {
  p = fract(p * vec2(123.34, 456.21));
  p += dot(p, p + 45.32);
  return fract(p.x * p.y);
}

void main() {
  vec2 cell = floor(qt_TexCoord0 * resolution / max(0.6, grainSize));
  float tick = floor(time * 16.0);
  float n = hash(cell + vec2(tick * 17.17, tick * 3.13));
  float fine = hash(cell * 1.73 + vec2(tick * 4.91, tick * 11.37));
  float alpha = (0.08 + n * 0.52 + fine * 0.12) * intensity;
  vec3 color = mix(vec3(1.0), grainColor.rgb, clamp(accentBlend, 0.0, 1.0));
  fragColor = vec4(color, alpha * qt_Opacity);
}
