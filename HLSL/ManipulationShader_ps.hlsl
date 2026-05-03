#include "Manipulation_Header.hlsli"
#include "Lighting_Header.hlsli"

Texture2D texture0 : register(t0);
Texture2D nMap : register(t1);
Texture2D shadowMap : register(t2);
Texture2D shadowMap2 : register(t3);

SamplerState sampler0 : register(s0);

cbuffer LightBuffer : register(b0)
{
    // Variables that don't change between lights
    bool normalMapEnabled;
    float3 normalPadding;
    float3 camPos;
    float padding;
    
    // Directional Light variables
    float4 diffuse;
    float4 ambient;
    float3 lightDir;
    float active;
    
    // Point light variables
    float4 diffuse1;
    float4 ambient1;
    float3 lightPos;
    float specInt;
    float specExp;
    float attenConst;
    float attenLin;
    float attenQuad;
    float active1;
    float3 padding2;
	
    // Spot light variables
    float4 diffuse2;
    float3 lightDir2;
    float active2;
    float4 ambient2;
    float3 lightPos2;
    float cutoff2;
    float3 atten;
    float range;
};

struct InputType
{
	float4 position : SV_POSITION;
	float2 tex : TEXCOORD0;
	float3 normal : NORMAL;
    float3 worldPosition : TEXCOORD1;
    float4 lightViewPos1 : TEXCOORD2;
    float4 lightViewPos2 : TEXCOORD3;
};

float4 main(InputType input) : SV_TARGET
{
    //------------------------------
    //          Variables
    //------------------------------
    
    // Declaring the local variables used to produce the final total colour from all lights
	float4 textureColour;
    float3 n;
    float4 lightColour[3];
    float4 totalLightColour = { 0, 0, 0, 1 };
    
    // Setting active states to an array to toggle light calculations depending on which ones are active or not
    // 0 = directional | 1 = point | 2 = spot
    float activeStates[3] = { active, active1, active2 };

	// Sample the texture
	textureColour = texture0.Sample(sampler0, input.tex);   
    
    
    //------------------------------
    //          Unfinished
    //------------------------------
    
    // I was attempting to add normal mapping but decided to dedicate the time on other parts of the project as I was running out of time
    
    // if normal map is enabled get normals
    /*if (normalMapEnabled)
    {
        const float3 normalSample = nMap.Sample(sampler0, input.tex).xyz;
        n.x = normalSample.x * 2.0f - 1.0f;
        n.y = normalSample.y;
        n.z = normalSample.z * 2.0f - 1.0f;
    }*/
    
    //------------------------------
    //      Function calls
    //------------------------------
    
    
    // Calculate lights using functions from Lighting_Header.hlsli
    
    // 0 -> calculate the directional light including all the shadows it would create
    // 1 -> calculate the point light including it's specular properties and attenuation
    // 2 -> calculate the spot light including all the shadows it would create
    
	lightColour[0] = shadowCalculation(lightDir, diffuse, ambient, input.normal, input.lightViewPos1, shadowMap, 0.005f, sampler0);
    lightColour[1] = CalcPointLighting(lightPos, input.worldPosition, input.normal, diffuse1, ambient1, attenConst, attenLin, attenQuad, specInt, specExp, camPos);
    lightColour[2] = spotlightShadowCalculation(lightPos2, -lightDir2, input.worldPosition, input.lightViewPos2, input.normal, diffuse2, ambient2, cutoff2, shadowMap2, 0.005f, sampler0, input.tex);
    
    // Loop through all lights to check if that light is currently active, if so add that light to the total
    for (int i = 0; i < 3; i++)
    {
        if (activeStates[i])
        {
            totalLightColour += lightColour[i];
        }
    }
    
    return totalLightColour * textureColour;
    
    //------------------------------------------------------------
    //    Debugging returns used to test lights individually
    //------------------------------------------------------------
    
    //return lightColour[0];
    //return lightColour[1];
    //return lightColour[2];
	//return textureColour;
    //return float4(1, 1, 1, 1);
    //return float4(input.normal.x, input.normal.y, input.normal.z, 1);
}



