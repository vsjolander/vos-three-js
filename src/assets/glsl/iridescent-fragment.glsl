uniform float u_time; // Time variable for animation
uniform vec2 u_resolution; // Screen resolution

varying vec2 v_uv; // Interpolated UV coordinates from vertex shader
varying vec3 v_normal;

void main() {
    // Calculate the position of the current pixel
    vec2 position = (gl_FragCoord.xy / u_resolution.xy) * 2.0 - 1.0;

    // Calculate the angle of the current pixel from the center of the screen
    float angle = atan(position.y, position.x);

    // Calculate the iridescence color based on time and angle
    vec3 iridescence = vec3(
    0.5 + 0.5 * sin(u_time * 5e-3 + angle),
    0.5 + 0.5 * sin(u_time * 7e-3 + angle),
    0.5 + 0.5 * sin(u_time * 9e-3 + angle)
    );

    // Output the final color for the current pixel
    gl_FragColor = vec4(v_normal, 1.0);
}
