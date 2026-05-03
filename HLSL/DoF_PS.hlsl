#include "Lighting_Header.hlsli"

// Texture and sampler registers
Texture2D normalTexture : register(t0);
Texture2D blurTexture : register(t1);
Texture2D depthTexture : register(t2);

SamplerState Sampler0 : register(s0);

struct InputType
{
    float4 position : SV_POSITION;
    float2 tex : TEXCOORD0;
    float3 normal : NORMAL;
};

cbuffer ActiveBuffer : register(b0)
{
    float percent;
    float cutoff;
    float weight;
    float active;
};

float4 main(InputType input) : SV_TARGET
{
    // Sample the scene as well as the bur texture
    float4 textureColour = normalTexture.Sample(Sampler0, input.tex);
    float4 blurColour = blurTexture.Sample(Sampler0, input.tex);
    
    // Sample the depth from the center of the screen to the current pixel, and use LinearizeDepth to get an appropriate depth value
    // The centerDepth would normally be divided by 200 but I felt that 75 gave better values
    float depth = LinearizeDepth(depthTexture.Sample(Sampler0, input.tex).x, 0.1f, 200.0f) / 75;
    float centreDepth = LinearizeDepth(depthTexture.Sample(Sampler0, float2(0.5f, 0.5f)).x, 0.1f, 200.0f) / 75;
    
    // If depth of field is enabled then continue, otherwise return the unmodified texture colour
    if (active)
    {
        float4 finalColour = { 0, 0, 0, 1 };
        float lerpValue;
        
        // Find the distance in depth values between the center pixel and the current pixel, then get the absolute of that value (0-1)
        lerpValue = abs(centreDepth - depth);
        
        // If the value is above the cutoff then completely blur
        if (lerpValue > cutoff)
        {
            finalColour = blurColour;
        }
        else
        {
            // Take the lerpvalue calculated before and multiply it by a weighting, which is added for more control over the effect, then add it to the final colour
            finalColour = lerp(textureColour, blurColour, lerpValue * weight);
        }
       
        return finalColour;
    }
    else
    {
        return textureColour;
    }
    
    // Debugging returns
    
    //return float4(depth, depth, depth, 1);
    //return blurColour;
    //return textureColour;
}