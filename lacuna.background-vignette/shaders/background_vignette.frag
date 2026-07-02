#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
  mat4 qt_Matrix;
  float qt_Opacity;
  float intensity;
  float radius;
  float softness;
  float edgeWeight;
  vec2 resolution;
};

void main() {
  vec2 uv = qt_TexCoord0;
  vec2 center = vec2(0.5, 0.5);
  vec2 aspect = vec2(max(1.0, resolution.x / max(1.0, resolution.y)), 1.0);
  vec2 d = (uv - center) * aspect;
  float radial = smoothstep(radius, radius + softness, length(d));

  float left = 1.0 - smoothstep(0.0, 0.22, uv.x);
  float right = smoothstep(0.78, 1.0, uv.x);
  float top = 1.0 - smoothstep(0.0, 0.18, uv.y);
  float bottom = smoothstep(0.72, 1.0, uv.y);
  float edge = max(max(left, right) * edgeWeight, max(top * 0.55, bottom * 0.82));
  float alpha = clamp(max(radial, edge) * intensity, 0.0, 1.0);
  fragColor = vec4(0.0, 0.0, 0.0, alpha * qt_Opacity);
}
