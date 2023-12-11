// SphericalProjection (aka EquiRectangular Projection ERP)
// The calculations are done in view space.
//
#version 330 core

// Incoming per vertex... position and texture coordinates
layout (location = 0) in vec4 position;
layout (location = 2) in vec2 texCoords;

uniform mat4   projectionMatrix;
uniform mat4   mvMatrix;

// Output to the fragment shader
smooth out vec2 uvCoords;

void main(void)
{
	// Transform the vertex position into Eye/View Space
	vec4 vVert4 = mvMatrix * position;

	// Pass on the texture coordinates
	uvCoords = texCoords;

	// Don't forget to transform the geometry!
	gl_Position = projectionMatrix * vVert4;
}
