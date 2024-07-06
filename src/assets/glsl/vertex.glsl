struct Global {
    vec2 noiseFreq;
    float noiseSpeed;
};

struct VertDeform {
    float incline;
    float offsetTop;
    float offsetBottom;
    vec2 noiseFreq;
    float noiseAmp;
    float noiseSpeed;
    float noiseFlow;
    float noiseSeed;
};

struct WaveLayers {
    vec3 color;
    vec2 noiseFreq;
    float noiseSpeed;
    float noiseFlow;
    float noiseSeed;
    float noiseFloor;
    float noiseCeil;
};

attribute vec2 uvNorm;

uniform float u_time;
uniform Global u_global;
uniform VertDeform u_vertDeform;
uniform WaveLayers u_waveLayers[4];
uniform vec2 u_resolution;
uniform vec3 u_baseColor;
uniform vec3 u_active_colors;
varying vec2 v_uv;
varying vec3 v_position;
varying vec3 v_color;
varying vec3 v_normal;
float PI = 3.141592653589793238;
float HALF_PI = 1.5707963267948966;

//
// Description : Array and textureless GLSL 2D/3D/4D simplex
//               noise functions.
//      Author : Ian McEwan, Ashima Arts.
//  Maintainer : ijm
//     Lastmod : 20110822 (ijm)
//     License : Copyright (C) 2011 Ashima Arts. All rights reserved.
//               Distributed under the MIT License. See LICENSE file.
//               https://github.com/ashima/webgl-noise
//

vec3 mod289(vec3 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 mod289(vec4 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 permute(vec4 x) {
    return mod289(((x*34.0)+1.0)*x);
}

vec4 taylorInvSqrt(vec4 r)
{
    return 1.79284291400159 - 0.85373472095314 * r;
}

float snoise(vec3 v)
{
    const vec2  C = vec2(1.0/6.0, 1.0/3.0) ;
    const vec4  D = vec4(0.0, 0.5, 1.0, 2.0);

    // First corner
    vec3 i  = floor(v + dot(v, C.yyy) );
    vec3 x0 =   v - i + dot(i, C.xxx) ;

    // Other corners
    vec3 g = step(x0.yzx, x0.xyz);
    vec3 l = 1.0 - g;
    vec3 i1 = min( g.xyz, l.zxy );
    vec3 i2 = max( g.xyz, l.zxy );

    //   x0 = x0 - 0.0 + 0.0 * C.xxx;
    //   x1 = x0 - i1  + 1.0 * C.xxx;
    //   x2 = x0 - i2  + 2.0 * C.xxx;
    //   x3 = x0 - 1.0 + 3.0 * C.xxx;
    vec3 x1 = x0 - i1 + C.xxx;
    vec3 x2 = x0 - i2 + C.yyy; // 2.0*C.x = 1/3 = C.y
    vec3 x3 = x0 - D.yyy;      // -1.0+3.0*C.x = -0.5 = -D.y

    // Permutations
    i = mod289(i);
    vec4 p = permute( permute( permute(
    i.z + vec4(0.0, i1.z, i2.z, 1.0 ))
    + i.y + vec4(0.0, i1.y, i2.y, 1.0 ))
    + i.x + vec4(0.0, i1.x, i2.x, 1.0 ));

    // Gradients: 7x7 points over a square, mapped onto an octahedron.
    // The ring size 17*17 = 289 is close to a multiple of 49 (49*6 = 294)
    float n_ = 0.142857142857; // 1.0/7.0
    vec3  ns = n_ * D.wyz - D.xzx;

    vec4 j = p - 49.0 * floor(p * ns.z * ns.z);  //  mod(p,7*7)

    vec4 x_ = floor(j * ns.z);
    vec4 y_ = floor(j - 7.0 * x_ );    // mod(j,N)

    vec4 x = x_ *ns.x + ns.yyyy;
    vec4 y = y_ *ns.x + ns.yyyy;
    vec4 h = 1.0 - abs(x) - abs(y);

    vec4 b0 = vec4( x.xy, y.xy );
    vec4 b1 = vec4( x.zw, y.zw );

    //vec4 s0 = vec4(lessThan(b0,0.0))*2.0 - 1.0;
    //vec4 s1 = vec4(lessThan(b1,0.0))*2.0 - 1.0;
    vec4 s0 = floor(b0)*2.0 + 1.0;
    vec4 s1 = floor(b1)*2.0 + 1.0;
    vec4 sh = -step(h, vec4(0.0));

    vec4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
    vec4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;

    vec3 p0 = vec3(a0.xy,h.x);
    vec3 p1 = vec3(a0.zw,h.y);
    vec3 p2 = vec3(a1.xy,h.z);
    vec3 p3 = vec3(a1.zw,h.w);

    //Normalise gradients
    vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
    p0 *= norm.x;
    p1 *= norm.y;
    p2 *= norm.z;
    p3 *= norm.w;

    // Mix final noise value
    vec4 m = max(0.6 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
    m = m * m;
    return 42.0 * dot( m*m, vec4( dot(p0,x0), dot(p1,x1),
    dot(p2,x2), dot(p3,x3) ) );
}

float sineOut(float t) {
    return sin(t * HALF_PI);
}

vec3 rainbow(float level)
{
    /*
        Target colors
        =============

        L  x   color
        0  0.0 vec4(1.0, 0.0, 0.0, 1.0);
        1  0.2 vec4(1.0, 0.5, 0.0, 1.0);
        2  0.4 vec4(1.0, 1.0, 0.0, 1.0);
        3  0.6 vec4(0.0, 0.5, 0.0, 1.0);
        4  0.8 vec4(0.0, 0.0, 1.0, 1.0);
        5  1.0 vec4(0.5, 0.0, 0.5, 1.0);
    */

    float r = float(level <= 2.0) + float(level > 4.0) * 0.5;
    float g = max(1.0 - abs(level - 2.0) * 0.5, 0.0);
    float b = (1.0 - (level - 4.0) * 0.5) * float(level >= 4.0);
    return vec3(r, g, b);
}

vec3 smoothRainbow (float x)
{
    float level1 = floor(x*6.0);
    float level2 = min(6.0, floor(x*6.0) + 1.0);

    vec3 a = rainbow(level1);
    vec3 b = rainbow(level2);

    return mix(a, b, fract(x*6.0));
}

//
// https://github.com/jamieowen/glsl-blend
//

// Normal

vec3 blendNormal(vec3 base, vec3 blend) {
    return blend;
}

vec3 blendNormal(vec3 base, vec3 blend, float opacity) {
    return (blendNormal(base, blend) * opacity + base * (1.0 - opacity));
}

// http://lolengine.net/blog/2013/09/21/picking-orthogonal-vector-combing-coconuts
vec3 orthogonal(vec3 v) {
    return normalize(abs(v.x) > abs(v.z) ? vec3(-v.y, v.x, 0.0)
    : vec3(0.0, -v.z, v.y));
}

vec3 displace(vec3 point, vec2 noiseCoord, float time, float tilt, float incline, float offset) {

    vec2 st = 1. - uvNorm.xy;

    //float noise = snoise(vec3(uv * vec2(3.,4.), time));

    float noise = snoise(vec3(
        noiseCoord.x * u_vertDeform.noiseFreq.x + time * u_vertDeform.noiseFlow,
        noiseCoord.y * u_vertDeform.noiseFreq.y,
        time * u_vertDeform.noiseSpeed + u_vertDeform.noiseSeed
    )) * u_vertDeform.noiseAmp;

    noise *= 1.0 - pow(abs(uvNorm.y), 2.0);

    noise = max(0.0, noise);

    return vec3(
        point.x,
        point.y  + tilt + incline + noise - offset,
        point.z
    );
}

void main() {

    v_normal = normal;

    float time = u_time* u_global.noiseSpeed;
    vec2 noiseCoord = u_resolution * uvNorm * u_global.noiseFreq;
    float tilt = u_resolution.y / 2.0 * uvNorm.y;
    float incline = u_resolution.x * uvNorm.x / 2.0 * u_vertDeform.incline;
    float offset = u_resolution.x / 2.0 * u_vertDeform.incline * mix(u_vertDeform.offsetBottom, u_vertDeform.offsetTop, uv.y);

    vec3 displacedPosition = displace(position, noiseCoord, time, tilt, incline, offset);


    if (u_active_colors[0] == 1.) {
        v_color = u_baseColor;
    }

    for (int i = 0; i < u_waveLayers.length(); i++) {
        if (u_active_colors[i + 1] == 1.) {
            WaveLayers layer = u_waveLayers[i];

            float noise = smoothstep(
            layer.noiseFloor,
            layer.noiseCeil,
            snoise(vec3(
            noiseCoord.x * layer.noiseFreq.x + time * layer.noiseFlow,
            noiseCoord.y * layer.noiseFreq.y,
            time * layer.noiseSpeed + layer.noiseSeed
            )) / 2.0 + 0.5
            );

            v_color = blendNormal(v_color, layer.color, pow(noise, 4.));
        }
    }

    gl_Position = projectionMatrix * modelViewMatrix * vec4(displacedPosition, 1.0);

    //v_uv = abs(uvNorm);

    float noise = snoise(vec3(
        noiseCoord.x * 4.,
        noiseCoord.y * 5.,
        time * 5.
    ));

    noise *= 1.0 - pow(abs(uvNorm.y), 2.0);

    noise = min(.95, noise);

    //v_color = vec3(.95, .95, .95) - vec3( noise ) * .25;
    v_color = vec3(0.1, .15, 0.05) + vec3(0., displacedPosition.y - incline - tilt + offset, 0.) * .001;
    float normalizedY = 2. * ((displacedPosition.y - noiseCoord.y) / (noiseCoord.y + 1. - noiseCoord.y)) - 1.;
    /*v_color = vec3(
        smoothstep(.1, .7, (displacedPosition.y - incline - tilt + offset) * .009),
        smoothstep(.6, .95, (displacedPosition.y - incline - tilt + offset) * .009),
        smoothstep(-1., 0., (displacedPosition.y - incline - tilt + offset) * .009)
    );*/

    /*v_color = smoothRainbow((displacedPosition.y - incline - tilt + offset) * 1e-3);*/
}
