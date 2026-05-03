#include "Manipulation_Header.hlsli"

Texture2D texture0 : register(t0);
SamplerState sampler0 : register(s0);

cbuffer MatrixBuffer : register(b0)
{
	matrix worldMatrix;
	matrix viewMatrix;
	matrix projectionMatrix;
    
    matrix lightViewMatrix1;
    matrix lightOrthoMatrix1;
    
    matrix lightViewMatrix2;
    matrix lightProjectionMatrix2;
    
};

struct InputType
{
	float4 position : POSITION;
	float2 tex : TEXCOORD0;
	float3 normal : NORMAL;
};

struct OutputType
{
	float4 position : SV_POSITION;
	float2 tex : TEXCOORD0;
	float3 normal : NORMAL;
    float3 worldPosition : TEXCOORD1;
    float4 lightViewPos1 : TEXCOORD2;
    float4 lightViewPos2 : TEXCOORD3;
};

OutputType main(InputType input)
{
    OutputType output;

	//float4 texColour = texture0.SampleLevel(sampler0, input.tex, 0);
	//input.position.y += texColour.r * 30;
    input.position.y = GetHeight(input.tex.x, input.tex.y, texture0, sampler0) * 30;
    input.normal = CalculateVertexNormal(input.tex.x, input.tex.y, 100, 30, texture0, sampler0);

	// Calculate the position of the vertex against the world, view, and projection matrices.
    output.position = mul(input.position, worldMatrix);
    output.position = mul(output.position, viewMatrix);
    output.position = mul(output.position, projectionMatrix);
	
    // Calculate the position of the vertex against the world matrix as well as the point light's projection and view matrix
    output.lightViewPos1 = mul(input.position, worldMatrix);
    output.lightViewPos1 = mul(output.lightViewPos1, lightViewMatrix1);
    output.lightViewPos1 = mul(output.lightViewPos1, lightOrthoMatrix1);
    
    // Calculate the position of the vertex against the world matrix as well as the spot light's projection and view matrix
    output.lightViewPos2 = mul(input.position, worldMatrix);
    output.lightViewPos2 = mul(output.lightViewPos2, lightViewMatrix2);
    output.lightViewPos2 = mul(output.lightViewPos2, lightProjectionMatrix2);
	
	
    output.worldPosition = mul(input.position, worldMatrix).xyz;

	// Store the texture coordinates for the pixel shader.
    output.tex = input.tex;

	// Calculate the normal vector against the world matrix only and normalise.
    output.normal = mul(input.normal, (float3x3) worldMatrix);
    output.normal = normalize(output.normal);

    return output;
}