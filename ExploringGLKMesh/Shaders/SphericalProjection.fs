// SphericalProjection (aka EquiRectangular Projection ERP)
#version 330 core

out vec4 fragColor;

uniform sampler2D equiRectMap;

smooth in vec2 uvCoords;

void main(void)
{
	fragColor = texture(equiRectMap, uvCoords);
}
    
