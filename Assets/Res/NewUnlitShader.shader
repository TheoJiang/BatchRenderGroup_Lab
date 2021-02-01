Shader "Unlit/NewUnlitShader"
{
    Properties
    {
        albedo ("albedo tex", 2d) = "white" {}
        normal ("normal tex", 2d) = "white" {}
        mask ("mask tex", 2d) = "white" {}
        smoothness ("smoothness tex", 2d) = "white" {}
        metal ("metal tex", 2d) = "white" {}
        wrappingUV ("wrapping UV", vector) = (0,0,1,1)
        wrappingUV2 ("wrapping UV 2", vector) = (0,0,1,1)
        
        floatnumber ("floatnumber test", float) = 1.0
        slider ("slider test", range(0,1)) = 1

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
            #include "Packages/com.unity.shadergraph/ShaderGraphLibrary/ShaderVariablesFunctions.hlsl"
            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            CBUFFER_START(UnityPerMaterial)
            float4 wrappingUV;
            float4 wrappingUV2;
            float floatnumber;
            float slider;
            float4 albedo_ST;
            CBUFFER_END
            TEXTURE2D(albedo); SAMPLER(sampleralbedo);
            SAMPLER(_SampleTexture2D_6C761A2C_Sampler_3_Linear_Repeat);
            
            //sampler2D albedo;
            //float4 albedo_ST;
            //float4 wrappingUV;
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex);
                
                v.uv = v.uv * wrappingUV.zw + wrappingUV.xy;  
                o.uv = TRANSFORM_TEX(v.uv, albedo);
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                // sample the texture
                half4 _SampleTexture2D_6C761A2C_RGBA_0 = SAMPLE_TEXTURE2D(albedo, sampleralbedo, i.uv);

                //half4 col = tex2D(albedo, i.uv);
                // apply fog
                return _SampleTexture2D_6C761A2C_RGBA_0;
            }
            ENDHLSL
        }
    }
    
    CustomEditor "UniversalShaderGUI"
}
