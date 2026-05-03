float4 calculateDirectionalLighting(float3 lightDirection, float3 normal, float4 diffuse, float4 ambient)
{
    float intensity = saturate(dot(normal, lightDirection));
    float4 colour = saturate(diffuse * intensity);
    return ambient + colour;
}

//------------------------------------------------------------------------------------------------------------------------
//                  Calculate the point light including the specular and attenuation attributes
//------------------------------------------------------------------------------------------------------------------------
// Source:- https://www.youtube.com/watch?v=6B1IA_Tera4&list=PLqCJpWy5Fohd3S7ICFXwUomYW0Wv67pDD&index=28
float4 CalcPointLighting(float3 lightPos, float3 worldPos, float3 normal, float4 diffuseTotal, float4 ambientTotal, float attConst, float attLin, float attQuad, float specIntensity, float specExp, float3 camPos)
{
    //------------------------------
    //          Variables
    //------------------------------
    
    float3 vToL = lightPos - worldPos;  // vToL is short for "vector to light" and calculates the vector to the light (direction and distance)
    float3 distToL = length(vToL);      // Calculates the distance to the light
    float3 dirToL = vToL / distToL;     // Calculates the direction to the light
    
    // Setting light properties
    float3 diffuseColour = float3(diffuseTotal.x, diffuseTotal.y, diffuseTotal.z);
    float diffuseIntensity = diffuseTotal.w;
    float3 ambient = float3(ambientTotal.x, ambientTotal.y, ambientTotal.z);
    
    //------------------------------
    //         Calculations
    //------------------------------
    
    // Diffuse attenuation
    float att = 1.0f / (attConst + attLin * distToL + attQuad * (distToL * distToL));
    
    // Diffuse intensity
    float3 diffuse = diffuseColour * diffuseIntensity * att * max(0.0f, dot(dirToL, normal));
    
    //Reflected light vector
    float3 w = normal * dot(vToL, normal);
    float3 r = w * 2.0f - vToL;
    
    // Calculate specular intensity based on the angle between viewing vector
    float3 specular = att * (diffuseColour * diffuseIntensity) * specIntensity * pow(max(0.0f, dot(normalize(-r), normalize(worldPos))), specExp);
    
    // Final Colour
    return float4(saturate(diffuse + ambient + specular), 1.0f);

}

//------------------------------------------------------------------------------------------------------------------------
//                                          Calculate the spot light
//------------------------------------------------------------------------------------------------------------------------
float4 CalculateSpotLighting(float3 lightPos, float3 worldPos, float3 direction, float3 camPos, float3 normal, float4 diffuse, float4 ambient, float cutoff, float3 atten, float range, float cone)
{
    //------------------------------
    //          Variables
    //------------------------------
    float4 colour;
    float3 vToL;
    
    //------------------------------
    //         Calculations
    //------------------------------
    
    // calculate the cut off angle and /2. Then convert into degres from radians as it's easier to understand when changing the value in the ImGui display
    float intensity, finalCutoff = cutoff / (180 / 3.14) / 2;
    
    // vToL is short for "vector to light" and calculates the vector to the light
    vToL = normalize(lightPos - worldPos);
    
    // Calculate intensity using vToL and light direction, then using the cutoff to add the cutoff for the spotlight
    intensity = acos(dot(normalize(vToL), normalize(direction)));
    intensity = (finalCutoff - intensity) / finalCutoff;
    
    // To get colour use the directional lighting calculation using the values from this spot light
    colour = calculateDirectionalLighting(vToL, normal, diffuse, ambient);
    
    // Multiply the colour by intensity to give the "spotlight" effect
    colour.x *= intensity;
    colour.y *= intensity;
    colour.z *= intensity;
    
    return colour;
}

//------------------------------------------------------------------------------------------------------------------------
//                  Calculate directional lighting and calculate the shadows it should produce
//------------------------------------------------------------------------------------------------------------------------
float4 shadowCalculation(float3 lightDir, float4 lightDiff, float4 lightAmb, float3 lightNorm, float4 viewPos, Texture2D currentDepthMap, float bias, SamplerState shadowSampler)
{
    float4 tColour = { 0, 0, 0, 1 };
    
    // Caclulate the coordinates for the projected texture
    float2 projTex = viewPos.xy / viewPos.w;
    projTex *= float2(0.5, -0.5);
    projTex += float2(0.5f, 0.5f);
    
    // If the geometry isn't in the shadow map return black
    if (projTex.x < 0.f || projTex.x > 1.f || projTex.y < 0.f || projTex.y > 1.f)
    {
        return float4(0, 0, 0, 1);
    }

    // Sample the shadow map to get the depth of the geometry
    float currentDepthValue = currentDepthMap.Sample(shadowSampler, projTex).r;
    
    // Calculate the depth from the view position of this light
    float lightDepthValue = viewPos.z / viewPos.w;
    lightDepthValue -= bias;
    
    // if the light depth is less than the current depth then it should be lit, otherwise it would be a shadow
    if (lightDepthValue < currentDepthValue)
    {
        return tColour = calculateDirectionalLighting(-lightDir, lightNorm, lightDiff, lightAmb);
        //return float4(0.0f, 0.0f, 1.0f, 1.0f);
        //return float4(lightDepthValue, lightDepthValue, lightDepthValue, 1.0f);

    }
    
    return tColour;
}

// Enhances the depth values given from the Camera's perspective through the near and far planes (0.1f and 200.0f respectively)
// Source:- https://learnopengl.com/depth-testing
float LinearizeDepth(float depth, float near, float far)
{
    float z = depth * 2.0 - 1.0; // back to NDC 
    return (2.0 * near * far) / (far + near - z * (far - near));
}

//------------------------------------------------------------------------------------------------------------------------
//                  Calculate the spot light while creating the shadows it would produce
//------------------------------------------------------------------------------------------------------------------------
float4 spotlightShadowCalculation(float3 lightPosition, float3 lightDirection, float3 worldPosition, float4 viewPos, float3 normal, float4 diffuse, float4 ambient, float cutoff, Texture2D currentDepthMap, float bias, SamplerState shadowSampler, float2 uvTex)
{
    //------------------------------
    //          Variables
    //------------------------------
    
    float4 colour = { 0, 0, 0, 1 };
    float3 vToL;
    float intensity;
    float finalCutoff = cutoff / (180 / 3.14) / 2;
    
    //------------------------------
    //         Calculations
    //------------------------------
    
    // vToL is short for "vector to light" and calculates the vector to the light
    vToL = normalize(lightPosition - worldPosition);
    
    // Using the cutoff calculate the intensity
    intensity = acos(dot(normalize(vToL), normalize(lightDirection)));
    intensity = (finalCutoff - intensity) / finalCutoff;
    
    // Manipulate the projected texture coordinates to get appropriate depth values
    float2 projTex = viewPos.xy / viewPos.w;
    projTex *= float2(0.5, -0.5);
    projTex += float2(0.5f, 0.5f);
    
    // If the geometry isn't in the shadow map return black
    if (projTex.x < 0.f || projTex.x > 1.f || projTex.y < 0.f || projTex.y > 1.f)
    {
        return float4(0, 0, 0, 1);
        //return float4(0, 1, 0, 1);
    }
    
    // Get the depth of the geometry by sampling the shadow map, LinearizeDepth gives an appropriate depth value
    float currentDepthValue = LinearizeDepth(currentDepthMap.Sample(shadowSampler, projTex).x, 0.1f, 200.0f) / 200;
    
    // Calculate the depth from the light, then LinearizeDepth gives an appropriate depth value
    float lightDepthValue = viewPos.z / viewPos.w;
    lightDepthValue = LinearizeDepth(lightDepthValue, 0.1f, 200.0f) / 200;
    lightDepthValue -= bias;
    
    // if the light depth is less than the current depth then it should be lit, otherwise it would be a shadow
    if (lightDepthValue < currentDepthValue)
    {
        colour = calculateDirectionalLighting(vToL, normal, diffuse, ambient);
        colour.x *= intensity;
        colour.y *= intensity;
        colour.z *= intensity;
        //return float4(0, 0, 1, 1);

    }
    
    // If intensity is 0, then no light should be shining here so return black
    if (intensity <= 0.0f)
    {
        return float4(0, 0, 0, 1);
        //return float4(1, 0, 0, 1);

    }
    
    return colour;
    
    // Debug variables
    
    //return float4(currentDepthValue, currentDepthValue, currentDepthValue, 1.0f);
    //return float4(lightDepthValue, lightDepthValue, lightDepthValue, 1.0f);
    //return float4(0, 0, 0, 1);

}