shader_type canvas_item;

uniform vec4 color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float radius : hint_range(0.0, 100.0) = 10.0;

void fragment() {
    // 控件本地坐标，0 = 左上，1 = 右下
    vec2 uv = LOCAL_COORDS / vec2(VIEWPORT_SIZE);

    // 获取控件实际大小
    vec2 size = vec2(VIEWPORT_SIZE);

    // 把坐标映射到 -0.5 ~ 0.5
    vec2 local = uv - 0.5;

    // 缩放到控件尺寸
    local *= size;

    // 计算圆角距离
    vec2 d = abs(local) - (size * 0.5 - radius);
    float outside = max(d.x, d.y);
    outside = max(outside, 0.0);

    // 平滑边缘
    float alpha = 1.0 - smoothstep(0.0, 1.0, outside);

    COLOR = vec4(color.rgb, color.a * alpha);
}