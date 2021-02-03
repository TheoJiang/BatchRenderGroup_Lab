// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "XDT/Building/BuildingHSV"
{
	Properties
	{
		[HideInInspector] _AlphaCutoff("Alpha Cutoff ", Range(0, 1)) = 0.5
		[HideInInspector] _EmissionColor("Emission Color", Color) = (1,1,1,1)
		_Color("FR_Color", Color) = (0,0,0,0)
//		_BG_Color("BG_Color", Color) = (0,0,0,0)
//		_BG_Metallic("BG_Metallic", Range( 0 , 1)) = 0
//		_R_Metallic("R_Metallic", Range( 0 , 1)) = 0
//		_BG_Roughness("BG_Roughness", Range( 0 , 1)) = 0
//		_R_Roughness("R_Roughness", Range( 0 , 1)) = 0
//		_MaskTexture("MaskTexture", 2D) = "white" {}
//		_Normal("Normal", 2D) = "white" {}
//		_HSV("HSV", Vector) = (0,0,0,0)
//		_HSVColor("HSVColor", Vector) = (0,0,0,0)
		[HideInInspector] _texcoord( "", 2D ) = "white" {}

		[HideInInspector]_TransmissionShadow( "Transmission Shadow", Range( 0, 1 ) ) = 0.5
		[HideInInspector]_TransStrength( "Trans Strength", Range( 0, 50 ) ) = 1
		[HideInInspector]_TransNormal( "Trans Normal Distortion", Range( 0, 1 ) ) = 0.5
		[HideInInspector]_TransDirect( "Trans Direct", Range( 0, 1 ) ) = 0.9
		[HideInInspector]_TransAmbient( "Trans Ambient", Range( 0, 1 ) ) = 0.1
		[HideInInspector]_TransShadow( "Trans Shadow", Range( 0, 1 ) ) = 0.5

		[HideInInspector]_LogicColor( "LogicColor", Color) = (1,1,1,1)
		[Enum(Off, 0, On, 1)]_ZWrite( "ZWrite", int) = 1
		[Enum(UnityEngine.Rendering.BlendMode)]_SrcBlend( "SrcBlend", int) = 1
		[Enum(UnityEngine.Rendering.BlendMode)]_DstBlend( "DstBlend", int) = 0

	}

	SubShader
	{
		LOD 0

		

		Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" "Queue"="Geometry" }
		Cull Back
		HLSLINCLUDE
		#pragma target 3.0

		ENDHLSL

		
		Pass
		{
			
			Name "Forward"
			Tags { "LightMode"="UniversalForward" }
			
			Blend [_SrcBlend] [_DstBlend]
			ZWrite [_ZWrite]
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA
			

			HLSLPROGRAM
			#pragma multi_compile_instancing
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#define _NORMALMAP 1
			#define ASE_SRP_VERSION 999999

			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x

			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
			#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
			#pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
			#pragma multi_compile _ _SHADOWS_SOFT
			#pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE
			
			#pragma multi_compile _ DIRLIGHTMAP_COMBINED
			#pragma multi_compile _ LIGHTMAP_ON

			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS_FORWARD
			
			#if SHADER_TARGET >= 30 && (defined(SHADER_API_D3D11) || defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE) || defined(SHADER_API_VULKAN) || defined(SHADER_API_METAL))
			#define UNITY_SUPPORT_INSTANCING
			#endif
			#if defined(UNITY_SUPPORT_INSTANCING) && defined(INSTANCING_ON)
			#define UNITY_HYBRID_V1_INSTANCING_ENABLED
			#endif
			
			#if defined(UNITY_HYBRID_V1_INSTANCING_ENABLED)
			#define HYBRID_V1_CUSTOM_ADDITIONAL_MATERIAL_VARS	\
				UNITY_DEFINE_INSTANCED_PROP(float4x4 , shm1_Array)\
				UNITY_DEFINE_INSTANCED_PROP(float4x4 , shm2_Array)\
				UNITY_DEFINE_INSTANCED_PROP(float4 , _Color_Array)\

			#define shm1 UNITY_ACCESS_INSTANCED_PROP(unity_Builtins0 , shm1_Array)
			#define shm2 UNITY_ACCESS_INSTANCED_PROP(unity_Builtins0 , shm2_Array)
			#define _Color UNITY_ACCESS_INSTANCED_PROP(unity_Builtins0 , _Color_Array)

			#endif
			
			sampler2D _MaskTexture;
			sampler2D _Normal;


			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Assets/Res/HybridInstancePattern.hlsl"

			#if ASE_SRP_VERSION <= 70108
			#define REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR
			#endif

			

			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_tangent : TANGENT;
				float4 texcoord1 : TEXCOORD1;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				float4 lightmapUVOrVertexSH : TEXCOORD0;
				half4 fogFactorAndVertexLight : TEXCOORD1;
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
				float4 shadowCoord : TEXCOORD2;
				#endif
				float4 tSpace0 : TEXCOORD3;
				float4 tSpace1 : TEXCOORD4;
				float4 tSpace2 : TEXCOORD5;
				#if defined(ASE_NEEDS_FRAG_SCREEN_POSITION)
				float4 screenPos : TEXCOORD6;
				#endif
				float4 ase_texcoord7 : TEXCOORD7;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};
			CBUFFER_START(UnityPerMaterial)
			#ifndef UNITY_HYBRID_V1_INSTANCING_ENABLED
			float4 _Color;

			#else

			float4 _Color_dummy;

			#endif
			float4 _MaskTexture_ST;
			float4 _Normal_ST;
			float4 _LogicColor;
			#ifdef _TRANSMISSION_ASE
				float _TransmissionShadow;
			#endif
			#ifdef _TRANSLUCENCY_ASE
				float _TransStrength;
				float _TransNormal;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			CBUFFER_END

			float3 HSVToRGB( float3 c )
			{
				float4 K = float4( 1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0 );
				float3 p = abs( frac( c.xxx + K.xyz ) * 6.0 - K.www );
				return c.z * lerp( K.xxx, saturate( p - K.xxx ), c.y );
			}
			
			float3 RGBToHSV(float3 c)
			{
				float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
				float4 p = lerp( float4( c.bg, K.wz ), float4( c.gb, K.xy ), step( c.b, c.g ) );
				float4 q = lerp( float4( p.xyw, c.r ), float4( c.r, p.yzx ), step( p.x, c.r ) );
				float d = q.x - min( q.w, q.y );
				float e = 1.0e-10;
				return float3( abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
			}

			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				o.ase_texcoord7.xy = v.ase_texcoord.xy;
				o.ase_color = v.ase_color;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord7.zw = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = defaultVertexValue;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif
				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				float3 positionVS = TransformWorldToView( positionWS );
				float4 positionCS = TransformWorldToHClip( positionWS );

				VertexNormalInputs normalInput = GetVertexNormalInputs( v.ase_normal, v.ase_tangent );

				o.tSpace0 = float4( normalInput.normalWS, positionWS.x);
				o.tSpace1 = float4( normalInput.tangentWS, positionWS.y);
				o.tSpace2 = float4( normalInput.bitangentWS, positionWS.z);

				OUTPUT_LIGHTMAP_UV( v.texcoord1, unity_LightmapST, o.lightmapUVOrVertexSH.xy );
				OUTPUT_SH_CUSTOM( normalInput.normalWS.xyz, o.lightmapUVOrVertexSH.xyz );

				half3 vertexLight = VertexLighting( positionWS, normalInput.normalWS );
				#ifdef ASE_FOG
					half fogFactor = ComputeFogFactor( positionCS.z );
				#else
					half fogFactor = 0;
				#endif
				o.fogFactorAndVertexLight = half4(fogFactor, vertexLight);
				
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
				VertexPositionInputs vertexInput = (VertexPositionInputs)0;
				vertexInput.positionWS = positionWS;
				vertexInput.positionCS = positionCS;
				o.shadowCoord = GetShadowCoord( vertexInput );
				#endif
				
				o.clipPos = positionCS;
				#if defined(ASE_NEEDS_FRAG_SCREEN_POSITION)
				o.screenPos = ComputeScreenPos(positionCS);
				#endif
				return o;
			}
			
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}

			half4 frag ( VertexOutput IN  ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(IN);

				float3 WorldNormal = normalize( IN.tSpace0.xyz );
				float3 WorldTangent = IN.tSpace1.xyz;
				float3 WorldBiTangent = IN.tSpace2.xyz;
				float3 WorldPosition = float3(IN.tSpace0.w,IN.tSpace1.w,IN.tSpace2.w);
				float3 WorldViewDirection = _WorldSpaceCameraPos.xyz  - WorldPosition;
				float4 ShadowCoords = float4( 0, 0, 0, 0 );
				#if defined(ASE_NEEDS_FRAG_SCREEN_POSITION)
				float4 ScreenPos = IN.screenPos;
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
					ShadowCoords = IN.shadowCoord;
				#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
					ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
				#endif
	
				#if SHADER_HINT_NICE_QUALITY
					WorldViewDirection = SafeNormalize( WorldViewDirection );	
				#else
					WorldViewDirection = normalize( WorldViewDirection );	
				#endif

				float2 uv_MaskTexture = IN.ase_texcoord7.xy * _MaskTexture_ST.xy + _MaskTexture_ST.zw;
				float4 tex2DNode11 = tex2D( _MaskTexture, uv_MaskTexture );
				float4 temp_cast_0 = (tex2DNode11.a).xxxx;
				float3 hsvTorgb110 = RGBToHSV( _Color.rgb );
				// float3 hsvTorgb107 = HSVToRGB( float3(( _HSVColor.x + hsvTorgb110.x ),( _HSVColor.y + hsvTorgb110.y ),( _HSVColor.z + hsvTorgb110.z )) );
				// float4 lerpResult62 = lerp( float4( hsvTorgb107 , 0.0 ) , _Color , tex2DNode11.g);
				// float4 lerpResult63 = lerp( _BG_Color , lerpResult62 , tex2DNode11.r);
				float4 blendOpSrc64 = temp_cast_0;
				// float4 blendOpDest64 = lerpResult63;
				// float4 temp_output_64_0 = ( saturate( (( blendOpDest64 > 0.5 ) ? ( 1.0 - 2.0 * ( 1.0 - blendOpDest64 ) * ( 1.0 - blendOpSrc64 ) ) : ( 2.0 * blendOpDest64 * blendOpSrc64 ) ) ));
				// float3 hsvTorgb92 = RGBToHSV( temp_output_64_0.rgb );
				// float3 hsvTorgb96 = HSVToRGB( float3(( _HSV.x + hsvTorgb92.x ),( _HSV.y + hsvTorgb92.y ),( _HSV.z + hsvTorgb92.z )) );
				// float4 lerpResult100 = lerp( temp_output_64_0 , float4( hsvTorgb96 , 0.0 ) , tex2DNode11.b);
				// float4 AlbedColor45 = lerpResult100;
				
				float2 uv_Normal = IN.ase_texcoord7.xy * _Normal_ST.xy + _Normal_ST.zw;
				
				// float2 appendResult84 = (float2(_BG_Metallic , _BG_Roughness));
				// float2 appendResult83 = (float2(_R_Metallic , _R_Roughness));
				// float2 lerpResult101 = lerp( appendResult84 , appendResult83 , tex2DNode11.r);
				// float2 break103 = lerpResult101;
				
				float3 Albedo = _Color.rgb;
				float3 Normal = UnpackNormalScale( tex2D( _Normal, uv_Normal ), 1.0f );
				float3 Emission = 0;
				float3 Specular = 0.5;
				float Metallic = 0;
				float Smoothness = 0.5;
				float Occlusion = 1;
				float Alpha = 1;
				float AlphaClipThreshold = 0.5;
				float3 BakedGI = 0;
				float3 RefractionColor = 1;
				float RefractionIndex = 1;
				float3 Transmission = 1;
				float3 Translucency = 1;
				float3 FogColor = unity_FogColor.rgb;
				float _Replenish = 0;


				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				InputData inputData;
				inputData.positionWS = WorldPosition;
				inputData.viewDirectionWS = WorldViewDirection;
				inputData.shadowCoord = ShadowCoords;

				#ifdef _NORMALMAP
					inputData.normalWS = normalize(TransformTangentToWorld(Normal, half3x3( WorldTangent, WorldBiTangent, WorldNormal )));
				#else
					#if !SHADER_HINT_NICE_QUALITY
						inputData.normalWS = WorldNormal;
					#else
						inputData.normalWS = normalize( WorldNormal );
					#endif
				#endif

				#ifdef ASE_FOG
					inputData.fogCoord = IN.fogFactorAndVertexLight.x;
				#endif

				inputData.vertexLighting = IN.fogFactorAndVertexLight.yzw;
				inputData.bakedGI = SAMPLE_GI_CUSTOM( IN.lightmapUVOrVertexSH.xy, IN.lightmapUVOrVertexSH.xyz, inputData.normalWS );
				#ifdef _ASE_BAKEDGI
					inputData.bakedGI = BakedGI;
				#endif
				half4 color = UniversalFragmentPBR(
					inputData, 
					Albedo, 
					Metallic, 
					Specular, 
					Smoothness, 
					Occlusion, 
					Emission, 
					Alpha) * (1.0+_Replenish);

				#ifdef _TRANSMISSION_ASE
				{
					float shadow = _TransmissionShadow;

					Light mainLight = GetMainLight( inputData.shadowCoord );
					float3 mainAtten = mainLight.color * mainLight.distanceAttenuation;
					mainAtten = lerp( mainAtten, mainAtten * mainLight.shadowAttenuation, shadow );
					half3 mainTransmission = max(0 , -dot(inputData.normalWS, mainLight.direction)) * mainAtten * Transmission;
					color.rgb += Albedo * mainTransmission;

					#ifdef _ADDITIONAL_LIGHTS
						int transPixelLightCount = GetAdditionalLightsCount();
						for (int i = 0; i < transPixelLightCount; ++i)
						{
							Light light = GetAdditionalLight(i, inputData.positionWS);
							float3 atten = light.color * light.distanceAttenuation;
							atten = lerp( atten, atten * light.shadowAttenuation, shadow );

							half3 transmission = max(0 , -dot(inputData.normalWS, light.direction)) * atten * Transmission;
							color.rgb += Albedo * transmission;
						}
					#endif
				}
				#endif

				#ifdef _TRANSLUCENCY_ASE
				{
					float shadow = _TransShadow;
					float normal = _TransNormal;
					//int scattering = _TransScattering;
					float direct = _TransDirect;
					float ambient = _TransAmbient;
					float strength = _TransStrength;

					Light mainLight = GetMainLight( inputData.shadowCoord );
					float3 mainAtten = mainLight.color * mainLight.distanceAttenuation;
					mainAtten = lerp( mainAtten, mainAtten * mainLight.shadowAttenuation, shadow );

					half3 mainLightDir = mainLight.direction + inputData.normalWS * normal;
					half mainVdotL = pow( saturate( dot( inputData.viewDirectionWS, -mainLightDir ) ), 2 );
					half3 mainTranslucency = mainAtten * ( mainVdotL * direct + inputData.bakedGI * ambient ) * Translucency;
					color.rgb += Albedo * mainTranslucency * strength;

					#ifdef _ADDITIONAL_LIGHTS
						int transPixelLightCount = GetAdditionalLightsCount();
						for (int i = 0; i < transPixelLightCount; ++i)
						{
							Light light = GetAdditionalLight(i, inputData.positionWS);
							float3 atten = light.color * light.distanceAttenuation;
							atten = lerp( atten, atten * light.shadowAttenuation, shadow );

							half3 lightDir = light.direction + inputData.normalWS * normal;
							half VdotL = pow( saturate( dot( inputData.viewDirectionWS, -lightDir ) ), 2 );
							half3 translucency = atten * ( VdotL * direct + inputData.bakedGI * ambient ) * Translucency;
							color.rgb += Albedo * translucency * strength;
						}
					#endif
				}
				#endif

				#ifdef _REFRACTION_ASE
					float4 projScreenPos = ScreenPos / ScreenPos.w;
					float3 refractionOffset = ( RefractionIndex - 1.0 ) * mul( UNITY_MATRIX_V, WorldNormal ).xyz * ( 1.0 - dot( WorldNormal, WorldViewDirection ) );
					projScreenPos.xy += refractionOffset.xy;
					float3 refraction = SHADERGRAPH_SAMPLE_SCENE_COLOR( projScreenPos ) * RefractionColor;
					color.rgb = lerp( refraction, color.rgb, color.a );
					color.a = 1;
				#endif

				#ifdef ASE_FOG
					#ifdef TERRAIN_SPLAT_ADDPASS
						color.rgb = MixFogColor(color.rgb, half3( 0, 0, 0 ), IN.fogFactorAndVertexLight.x );
					#else
						color.rgb = MixFogColor(color.rgb, FogColor, IN.fogFactorAndVertexLight.x);
					#endif
				#endif
				color = color*_LogicColor;
				return color;
			}

			ENDHLSL
		}

		
//		Pass
//		{
//			
//			Name "ShadowCaster"
//			Tags { "LightMode"="ShadowCaster" }
//
//			ZWrite On
//			ZTest LEqual
//
//			HLSLPROGRAM
//			#pragma multi_compile_instancing
//			#pragma multi_compile_fog
//			#define ASE_FOG 1
//			#define _NORMALMAP 1
//			#define ASE_SRP_VERSION 999999
//
//			#pragma prefer_hlslcc gles
//			#pragma exclude_renderers d3d11_9x
//
//			#pragma vertex vert
//			#pragma fragment frag
//
//			#define SHADERPASS_SHADOWCASTER
//			
//
//			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
//			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
//			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
//			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
//			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
//			
//			
//
//			struct VertexInput
//			{
//				float4 vertex : POSITION;
//				float3 ase_normal : NORMAL;
//				
//				UNITY_VERTEX_INPUT_INSTANCE_ID
//			};
//
//			struct VertexOutput
//			{
//				float4 clipPos : SV_POSITION;
//				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
//				float3 worldPos : TEXCOORD0;
//				#endif
//				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
//				float4 shadowCoord : TEXCOORD1;
//				#endif
//				
//				UNITY_VERTEX_INPUT_INSTANCE_ID
//				UNITY_VERTEX_OUTPUT_STEREO
//			};
//
//			CBUFFER_START(UnityPerMaterial)
//			#ifndef UNITY_HYBRID_V1_INSTANCING_ENABLED
//			float4 _BG_Color;
//			half4 _HSVColor;
//			float4 _Color;
//			half4 _HSV;
//			float _BG_Metallic;
//			float _BG_Roughness;
//			float _R_Metallic;
//			float _R_Roughness;
//			#else
//			float4 _BG_Color_dummy;
//			half4 _HSVColor_dummy;
//			float4 _Color_dummy;
//			half4 _HSV_dummy;
//			float _BG_Metallic_dummy;
//			float _BG_Roughness_dummy;
//			float _R_Metallic_dummy;
//			float _R_Roughness_dummy;
//			#endif
//			float4 _MaskTexture_ST;
//			float4 _Normal_ST;
//			float4 _LogicColor;
//			#ifdef _TRANSMISSION_ASE
//				float _TransmissionShadow;
//			#endif
//			#ifdef _TRANSLUCENCY_ASE
//				float _TransStrength;
//				float _TransNormal;
//				//int _TransScattering;
//				float _TransDirect;
//				float _TransAmbient;
//				float _TransShadow;
//			#endif
//			CBUFFER_END
//
//			
//			float3 _LightDirection;
//
//			VertexOutput VertexFunction( VertexInput v )
//			{
//				VertexOutput o;
//				UNITY_SETUP_INSTANCE_ID(v);
//				UNITY_TRANSFER_INSTANCE_ID(v, o);
//				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );
//
//				
//				#ifdef ASE_ABSOLUTE_VERTEX_POS
//					float3 defaultVertexValue = v.vertex.xyz;
//				#else
//					float3 defaultVertexValue = float3(0, 0, 0);
//				#endif
//				float3 vertexValue = defaultVertexValue;
//				#ifdef ASE_ABSOLUTE_VERTEX_POS
//					v.vertex.xyz = vertexValue;
//				#else
//					v.vertex.xyz += vertexValue;
//				#endif
//
//				v.ase_normal = v.ase_normal;
//
//				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
//				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
//				o.worldPos = positionWS;
//				#endif
//				float3 normalWS = TransformObjectToWorldDir(v.ase_normal);
//
//				float4 clipPos = TransformWorldToHClip( ApplyShadowBias( positionWS, normalWS, _LightDirection ) );
//
//				#if UNITY_REVERSED_Z
//					clipPos.z = min(clipPos.z, clipPos.w * UNITY_NEAR_CLIP_VALUE);
//				#else
//					clipPos.z = max(clipPos.z, clipPos.w * UNITY_NEAR_CLIP_VALUE);
//				#endif
//				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
//					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
//					vertexInput.positionWS = positionWS;
//					vertexInput.positionCS = clipPos;
//					o.shadowCoord = GetShadowCoord( vertexInput );
//				#endif
//				o.clipPos = clipPos;
//				return o;
//			}
//
//			VertexOutput vert ( VertexInput v )
//			{
//				return VertexFunction( v );
//			}
//
//			half4 frag(VertexOutput IN  ) : SV_TARGET
//			{
//				UNITY_SETUP_INSTANCE_ID( IN );
//				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );
//				
//				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
//				float3 WorldPosition = IN.worldPos;
//				#endif
//				float4 ShadowCoords = float4( 0, 0, 0, 0 );
//
//				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
//					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
//						ShadowCoords = IN.shadowCoord;
//					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
//						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
//					#endif
//				#endif
//
//				
//				float Alpha = 1;
//				float AlphaClipThreshold = 0.5;
//
//				#ifdef _ALPHATEST_ON
//					clip(Alpha - AlphaClipThreshold);
//				#endif
//
//				return 0;
//			}
//
//			ENDHLSL
//		}
//
//		
//		Pass
//		{
//			
//			Name "DepthOnly"
//			Tags { "LightMode"="DepthOnly" }
//
//			ZWrite On
//			ColorMask 0
//
//			HLSLPROGRAM
//			#pragma multi_compile_instancing
//			#pragma multi_compile_fog
//			#define ASE_FOG 1
//			#define _NORMALMAP 1
//			#define ASE_SRP_VERSION 999999
//
//			#pragma prefer_hlslcc gles
//			#pragma exclude_renderers d3d11_9x
//
//			#pragma vertex vert
//			#pragma fragment frag
//
//			#define SHADERPASS_DEPTHONLY
//
//			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
//			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
//			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
//			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
//
//			
//
//			struct VertexInput
//			{
//				float4 vertex : POSITION;
//				float3 ase_normal : NORMAL;
//				
//				UNITY_VERTEX_INPUT_INSTANCE_ID
//			};
//
//			struct VertexOutput
//			{
//				float4 clipPos : SV_POSITION;
//				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
//				float3 worldPos : TEXCOORD0;
//				#endif
//				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
//				float4 shadowCoord : TEXCOORD1;
//				#endif
//				
//				UNITY_VERTEX_INPUT_INSTANCE_ID
//				UNITY_VERTEX_OUTPUT_STEREO
//			};
//			CBUFFER_START(UnityPerMaterial)
//			#ifndef UNITY_HYBRID_V1_INSTANCING_ENABLED
//			float4 _BG_Color;
//			half4 _HSVColor;
//			float4 _Color;
//			half4 _HSV;
//			float _BG_Metallic;
//			float _BG_Roughness;
//			float _R_Metallic;
//			float _R_Roughness;
//			#else
//			float4 _BG_Color_dummy;
//			half4 _HSVColor_dummy;
//			float4 _Color_dummy;
//			half4 _HSV_dummy;
//			float _BG_Metallic_dummy;
//			float _BG_Roughness_dummy;
//			float _R_Metallic_dummy;
//			float _R_Roughness_dummy;
//			#endif
//			float4 _MaskTexture_ST;
//			float4 _Normal_ST;
//			float4 _LogicColor;
//			#ifdef _TRANSMISSION_ASE
//				float _TransmissionShadow;
//			#endif
//			#ifdef _TRANSLUCENCY_ASE
//				float _TransStrength;
//				float _TransNormal;
//				//int _TransScattering;
//				float _TransDirect;
//				float _TransAmbient;
//				float _TransShadow;
//			#endif
//			CBUFFER_END
//			
//
//			
//			VertexOutput VertexFunction( VertexInput v  )
//			{
//				VertexOutput o = (VertexOutput)0;
//				UNITY_SETUP_INSTANCE_ID(v);
//				UNITY_TRANSFER_INSTANCE_ID(v, o);
//				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
//
//				
//				#ifdef ASE_ABSOLUTE_VERTEX_POS
//					float3 defaultVertexValue = v.vertex.xyz;
//				#else
//					float3 defaultVertexValue = float3(0, 0, 0);
//				#endif
//				float3 vertexValue = defaultVertexValue;
//				#ifdef ASE_ABSOLUTE_VERTEX_POS
//					v.vertex.xyz = vertexValue;
//				#else
//					v.vertex.xyz += vertexValue;
//				#endif
//
//				v.ase_normal = v.ase_normal;
//				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
//				float4 positionCS = TransformWorldToHClip( positionWS );
//
//				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
//				o.worldPos = positionWS;
//				#endif
//
//				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
//					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
//					vertexInput.positionWS = positionWS;
//					vertexInput.positionCS = positionCS;
//					o.shadowCoord = GetShadowCoord( vertexInput );
//				#endif
//				o.clipPos = positionCS;
//				return o;
//			}
//
//			VertexOutput vert ( VertexInput v )
//			{
//				return VertexFunction( v );
//			}
//
//			half4 frag(VertexOutput IN  ) : SV_TARGET
//			{
//				UNITY_SETUP_INSTANCE_ID(IN);
//				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );
//
//				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
//				float3 WorldPosition = IN.worldPos;
//				#endif
//				float4 ShadowCoords = float4( 0, 0, 0, 0 );
//
//				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
//					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
//						ShadowCoords = IN.shadowCoord;
//					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
//						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
//					#endif
//				#endif
//
//				
//				float Alpha = 1;
//				float AlphaClipThreshold = 0.5;
//
//				#ifdef _ALPHATEST_ON
//					clip(Alpha - AlphaClipThreshold);
//				#endif
//
//				return 0;
//			}
//			ENDHLSL
//		}

	
	}
	/*ase_lod*/
	CustomEditor "UnityEditor.ShaderGraph.PBRMasterGUI"
	FallBack "Universal Render Pipeline/Lit"
	
	
}
/*ASEBEGIN
Version=18100
496;313;2064;1047;1666.454;836.6292;1.325788;True;False
Node;AmplifyShaderEditor.TexturePropertyNode;91;-1021.807,490.8134;Inherit;True;Property;_Normal;Normal;7;0;Create;True;0;0;False;0;False;None;None;False;white;Auto;Texture2D;-1;0;1;SAMPLER2D;0
Node;AmplifyShaderEditor.VertexColorNode;106;140.964,927.3549;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;84;-1535.747,840.7283;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;111;-1420.653,-609.788;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;99;185.8164,-494.0978;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.BlendOpsNode;64;-431.6992,-508.9474;Inherit;False;Overlay;True;3;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;2;FLOAT;1;False;1;COLOR;0
Node;AmplifyShaderEditor.SamplerNode;11;-2217.875,126.6424;Inherit;True;Property;_MaskTexture;MaskTexture;6;0;Create;True;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;80;-2138.922,-498.0488;Inherit;False;Property;_Color;FR_Color;0;0;Create;True;0;0;False;0;True;0,0,0,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RGBToHSVNode;110;-1781.036,-697.4646;Inherit;False;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.LerpOp;101;-1189.392,839.8364;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;97;170.8164,-707.0972;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;87;-2028.769,1050.767;Inherit;False;Property;_R_Roughness;R_Roughness;5;0;Create;True;0;0;False;0;True;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.Vector4Node;136;-2053.647,-954.627;Half;False;Property;_HSVColor;HSVColor;9;0;Create;True;0;0;False;0;True;0,0,0,0;0,0,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;83;-1551.04,1025.263;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;89;-2015.77,799.1673;Inherit;False;Property;_BG_Roughness;BG_Roughness;4;0;Create;True;0;0;False;0;True;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;98;173.8164,-600.0972;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;12;-668.9157,493.3205;Inherit;True;Property;_NormalTexture;NormalTexture;14;0;Create;True;0;0;False;0;False;-1;None;None;True;0;False;bump;Auto;True;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;81;-1051.764,-920.4067;Inherit;False;Property;_BG_Color;BG_Color;1;0;Create;True;0;0;False;0;True;0,0,0,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.HSVToRGBNode;96;414.1164,-573.2973;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.LerpOp;100;555.2952,-36.29292;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.Vector4Node;137;-457.4472,-983.9269;Half;False;Property;_HSV;HSV;8;0;Create;True;0;0;False;0;True;0,0,0,0;0,0,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;112;-1437.653,-715.7881;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;62;-1004.896,-614.0135;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;63;-725.7103,-500.5508;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.HSVToRGBNode;107;-1284.653,-735.7882;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;90;-2024.505,941.356;Inherit;False;Property;_R_Metallic;R_Metallic;3;0;Create;True;0;0;False;0;True;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RGBToHSVNode;92;-152.1665,-557.7743;Inherit;False;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.OneMinusNode;104;-205.2813,907.4704;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;88;-2020.905,685.8564;Inherit;False;Property;_BG_Metallic;BG_Metallic;2;0;Create;True;0;0;False;0;True;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;109;-1435.653,-822.7883;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;45;755.7362,-22.43122;Inherit;False;AlbedColor;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.BreakToComponentsNode;103;-582.7345,884.9251;Inherit;False;FLOAT2;1;0;FLOAT2;0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;151;1028.16,375.0507;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;1;New Amplify Shader;3794cf6a81975834faaf0b200235e796;True;Meta;0;3;Meta;0;False;False;False;True;0;False;-1;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;2;0;False;False;False;True;2;False;-1;False;False;False;False;False;True;1;LightMode=Meta;False;0;;0;0;Standard;0;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;148;1028.16,375.0507;Float;False;True;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;24;XDT/Building/BuildingHSV;3794cf6a81975834faaf0b200235e796;True;Forward;0;0;Forward;18;False;False;False;True;0;False;-1;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;2;0;True;1;0;True;-10;0;True;-11;0;1;False;-1;0;False;-1;False;False;False;True;True;True;True;True;0;False;-1;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;0;True;-9;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;1;LightMode=UniversalForward;False;0;;0;0;Standard;20;Workflow;1;Surface;0;  Refraction Model;0;Two Sided;1;Transmission;0;  Transmission Shadow;0.5,False,-1;Translucency;0;  Translucency Strength;1,False,-1;  Normal Distortion;0.5,False,-1;  Direct;0.9,False,-1;  Ambient;0.1,False,-1;  Shadow;0.5,False,-1;Cast Shadows;1;Receive Shadows;1;GPU Instancing;1;Built-in Fog;1;Meta Pass;0;Universal2D Pass;0;Override Baked GI;0;Vertex Position,InvertActionOnDeselection;1;0;5;True;True;True;False;False;False;;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;149;1028.16,375.0507;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;1;New Amplify Shader;3794cf6a81975834faaf0b200235e796;True;ShadowCaster;0;1;ShadowCaster;0;False;False;False;True;0;False;-1;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;2;0;False;False;False;False;False;False;True;1;False;-1;True;3;False;-1;False;True;1;LightMode=ShadowCaster;False;0;;0;0;Standard;0;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;150;1028.16,375.0507;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;1;New Amplify Shader;3794cf6a81975834faaf0b200235e796;True;DepthOnly;0;2;DepthOnly;0;False;False;False;True;0;False;-1;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;2;0;False;False;False;False;True;False;False;False;False;0;False;-1;False;True;1;False;-1;False;False;True;1;LightMode=DepthOnly;False;0;;0;0;Standard;0;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;152;1028.16,375.0507;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;1;New Amplify Shader;3794cf6a81975834faaf0b200235e796;True;Universal2D;0;4;Universal2D;0;False;False;False;True;0;False;-1;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;2;0;True;1;1;False;-1;0;False;-1;0;1;False;-1;0;False;-1;False;False;False;True;True;True;True;True;0;False;-1;False;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;1;LightMode=Universal2D;False;0;;0;0;Standard;0;0
WireConnection;84;0;88;0
WireConnection;84;1;89;0
WireConnection;111;0;136;3
WireConnection;111;1;110;3
WireConnection;99;0;137;3
WireConnection;99;1;92;3
WireConnection;64;0;11;4
WireConnection;64;1;63;0
WireConnection;110;0;80;0
WireConnection;101;0;84;0
WireConnection;101;1;83;0
WireConnection;101;2;11;1
WireConnection;97;0;137;1
WireConnection;97;1;92;1
WireConnection;83;0;90;0
WireConnection;83;1;87;0
WireConnection;98;0;137;2
WireConnection;98;1;92;2
WireConnection;12;0;91;0
WireConnection;96;0;97;0
WireConnection;96;1;98;0
WireConnection;96;2;99;0
WireConnection;100;0;64;0
WireConnection;100;1;96;0
WireConnection;100;2;11;3
WireConnection;112;0;136;2
WireConnection;112;1;110;2
WireConnection;62;0;107;0
WireConnection;62;1;80;0
WireConnection;62;2;11;2
WireConnection;63;0;81;0
WireConnection;63;1;62;0
WireConnection;63;2;11;1
WireConnection;107;0;109;0
WireConnection;107;1;112;0
WireConnection;107;2;111;0
WireConnection;92;0;64;0
WireConnection;104;0;103;1
WireConnection;109;0;136;1
WireConnection;109;1;110;1
WireConnection;45;0;100;0
WireConnection;103;0;101;0
WireConnection;148;0;45;0
WireConnection;148;1;12;0
WireConnection;148;3;103;0
WireConnection;148;4;104;0
WireConnection;148;5;106;1
ASEEND*/
//CHKSM=C12AEF72C25CC35A0BF05DAD5B89127514197028