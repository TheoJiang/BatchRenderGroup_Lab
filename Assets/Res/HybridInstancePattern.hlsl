// #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

// Ref: "Efficient Evaluation of Irradiance Environment Maps" from ShaderX 2
real3 SHEvalLinearL0L1Custom(real3 N,  float4x4 shMatrix1)
{
    real4 vA = real4(N, 1.0);

    real3 x1;
    x1 = mul(shMatrix1, vA).rgb;
    return x1;
}

real3 SHEvalLinearL2Custom(real3 N,  float4x4 shMatrix2)
{
    real3 x2;
    // 4 of the quadratic (L2) polynomials
    real4 vB = N.xyzz * N.yzzx;
    x2 = mul(shMatrix2, vB).rgb;

    // Final (5th) quadratic (L2) polynomial
    real vC = N.x * N.x - N.y * N.y;
    real3 x3 = shMatrix2[3].rgb * vC;

    return x2 + x3;
}

float3 SampleSH9Custom(float3 N, float4x4 shMatrix1, float4x4 shMatrix2)
{
    // Linear + constant polynomial terms
    float3 res = SHEvalLinearL0L1Custom(N,  shMatrix1);

    // Quadratic polynomials
    res += SHEvalLinearL2Custom(N,  shMatrix2);

    return res;
}

// Samples SH L0, L1 and L2 terms
half3 SampleSHCustom(half3 normalWS, float4x4 shMatrix1, float4x4 shMatrix2)
{
    // LPPV is not supported in Ligthweight Pipeline
    return max(half3(0, 0, 0), SampleSH9Custom(normalWS, shMatrix1, shMatrix2));
}
			
half3 SampleSHVertexCustom(half3 normalWS, float4x4 shMatrix1, float4x4 shMatrix2)
{
    #if defined(EVALUATE_SH_VERTEX)
    return max(half3(0, 0, 0), SampleSHCustom(normalWS,shMatrix1,shMatrix2));
    #elif defined(EVALUATE_SH_MIXED)
    // no max since this is only L2 contribution
    return SHEvalLinearL2Custom(normalWS, shMatrix2);
    #endif

    // Fully per-pixel. Nothing to compute.
    return half3(0.0, 0.0, 0.0);
}

#ifdef LIGHTMAP_ON
#define OUTPUT_SH_CUSTOM(normalWS, OUT)
#else
#ifndef UNITY_HYBRID_V1_INSTANCING_ENABLED
    #define OUTPUT_SH_CUSTOM(normalWS, OUT) OUT.xyz = SampleSHVertex(normalWS)
#else
    #define OUTPUT_SH_CUSTOM(normalWS, OUT) OUT.xyz = SampleSHVertexCustom(normalWS, shm1, shm2)
#endif
#endif



// SH Pixel Evaluation. Depending on target SH sampling might be done
// mixed or fully in pixel. See SampleSHVertex
half3 SampleSHPixelCustom(half3 L2Term, half3 normalWS, float4x4 shMatrix1, float4x4 shMatrix2)
{
    #if defined(EVALUATE_SH_VERTEX)
    return L2Term;
    #elif defined(EVALUATE_SH_MIXED)
    half3 L0L1Term = SHEvalLinearL0L1Custom(normalWS, shMatrix1);
    return max(half3(0, 0, 0), L2Term + L0L1Term);
    #endif
    
    // Default: Evaluate SH fully per-pixel
    return SampleSHCustom(normalWS, shMatrix1, shMatrix2);
}

// We either sample GI from baked lightmap or from probes.
// If lightmap: sampleData.xy = lightmapUV
// If probe: sampleData.xyz = L2 SH terms
#ifdef UNITY_DOTS_SHADER
half3 HackSampleSH(half3 normalWS)
{
    // Hack SH so that is is valid for hybrid V1
    real4 SHCoefficients[7];
    SHCoefficients[0] = float4(-0.02611f, -0.11903f, -0.02472f, 0.55319f);
    SHCoefficients[1] = float4(-0.04123, 0.0369, -0.03903, 0.62641);
    SHCoefficients[2] = float4(-0.06967, 0.23016, -0.06596, 0.81901);
    SHCoefficients[3] = float4(-0.02041, -0.01933, 0.07292, 0.05023);
    SHCoefficients[4] = float4(-0.03278, -0.03104, 0.0992, 0.07219);
    SHCoefficients[5] = float4(-0.05806, -0.05496, 0.10764, 0.09859);
    SHCoefficients[6] = float4(0.07564, 0.10311, 0.11301, 1.00);
    return max(half3(0, 0, 0), SampleSH9(SHCoefficients, normalWS));
}
#define SAMPLE_GI_CUSTOM(lmName, shName, normalWSName) HackSampleSH(normalWSName);
#elif defined(LIGHTMAP_ON)
#define SAMPLE_GI_CUSTOM(lmName, shName, normalWSName) SampleLightmap(lmName, normalWSName)
#else
    #ifdef UNITY_HYBRID_V1_INSTANCING_ENABLED
        #define SAMPLE_GI_CUSTOM(lmName, shName, normalWSName) SampleSHPixelCustom(shName, normalWSName, shm1, shm2)
    #else
        #define SAMPLE_GI_CUSTOM(lmName, shName, normalWSName) SampleSHPixel(shName, normalWSName)
    #endif
#endif
