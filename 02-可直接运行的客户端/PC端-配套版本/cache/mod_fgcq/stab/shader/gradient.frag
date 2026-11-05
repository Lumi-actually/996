#ifdef GL_ES
precision mediump float;
#endif

varying vec4 v_fragmentColor;
varying vec2 v_texCoord;

uniform vec3 startColor;
uniform vec3 endColor;

uniform float xFlag;
uniform float yFlag;

void main(void) {
    vec4 color = v_fragmentColor * texture2D(CC_Texture0, v_texCoord);
    color.rgb = mix(startColor, endColor, v_texCoord.x * xFlag + v_texCoord.y * yFlag).rgb;
    gl_FragColor = color;
}
