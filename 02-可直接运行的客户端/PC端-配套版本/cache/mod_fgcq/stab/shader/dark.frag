#ifdef GL_ES
precision highp float;
#endif
varying vec4 v_position;
uniform int nodenum;
uniform mat2 nodeinfo[200];
uniform float opacity;
void main(void)
{
    float resOpacity = 1.0;
    for(int i = 0; i < nodenum; i++){
		vec4 a = vec4(nodeinfo[i][0][0], nodeinfo[i][0][1], 0.0, 0.0);
		vec4 b = vec4(v_position.xy, 0.0, 0.0);
		float dis = distance(a,b);
		float r = nodeinfo[i][1][0];
		float w = nodeinfo[i][1][1];
		float op = 1.0;
		if(dis < r){
			if(dis < r - w){
				resOpacity = 0.0;
				break;
            }
            op = (dis - r + w)/ w;
		}
        resOpacity = min(op, resOpacity);
        if (resOpacity <= 0.01){
            break;
        }
    }
    resOpacity = min(resOpacity * opacity, 1.0);
    gl_FragColor = vec4(0.0, 0.0, 0.0, resOpacity);
}

