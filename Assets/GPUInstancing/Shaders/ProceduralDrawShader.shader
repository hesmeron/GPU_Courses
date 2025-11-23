Shader "Unlit/ProceduralDrawShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        
        Pass
        {
            // no LightMode tag are also rendered by Universal Render Pipeline
            Name "ForwardLit"
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            // -------------------------------------
            // Render State Commands
            Blend[_SrcBlend][_DstBlend], [_SrcBlendAlpha][_DstBlendAlpha]
            ZWrite[_ZWrite]
            Cull[_Cull]
            AlphaToMask[_AlphaToMask]

            HLSLPROGRAM
            #pragma target 2.0

            // -------------------------------------
            // Shader Stages
            #pragma vertex vert
            #pragma fragment frag

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local _PARALLAXMAP
            #pragma shader_feature_local _RECEIVE_SHADOWS_OFF
            #pragma shader_feature_local _ _DETAIL_MULX2 _DETAIL_SCALED
            #pragma shader_feature_local_fragment _SURFACE_TYPE_TRANSPARENT
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _ _ALPHAPREMULTIPLY_ON _ALPHAMODULATE_ON
            #pragma shader_feature_local_fragment _EMISSION
            #pragma shader_feature_local_fragment _METALLICSPECGLOSSMAP
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            #pragma shader_feature_local_fragment _OCCLUSIONMAP
            #pragma shader_feature_local_fragment _SPECULARHIGHLIGHTS_OFF
            #pragma shader_feature_local_fragment _ENVIRONMENTREFLECTIONS_OFF
            #pragma shader_feature_local_fragment _SPECULAR_SETUP

            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ EVALUATE_SH_MIXED EVALUATE_SH_VERTEX
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
            #pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
            #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
            #pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
            #pragma multi_compile_fragment _ _LIGHT_COOKIES
            #pragma multi_compile _ _LIGHT_LAYERS
            #pragma multi_compile _ _FORWARD_PLUS
            #include_with_pragmas "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRenderingKeywords.hlsl"
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"


            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ DYNAMICLIGHTMAP_ON
            #pragma multi_compile _ USE_LEGACY_LIGHTMAPS
            #pragma multi_compile _ LOD_FADE_CROSSFADE
            #pragma multi_compile_fog
            #pragma multi_compile_fragment _ DEBUG_DISPLAY
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ProbeVolumeVariants.hlsl"

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma instancing_options renderinglayer

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            //#ifndef UNIVERSAL_FORWARD_LIT_PASS_INCLUDED
#define UNIVERSAL_FORWARD_LIT_PASS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 normal : NORMAL;
            };

            struct Input
            {
                float2 uv : TEXCOORD0;
                float4 positionCS : SV_POSITION;
                float4 positionWS : TEXCOORD1;
                float4 normalWS : NORMAL;
            };

            StructuredBuffer<float4x4> _TransformationMatrices;
            
            sampler2D _MainTex;
            float4 _MainTex_ST;

            Input vert (appdata v, uint instanceId: SV_InstanceID)
            {
                Input o;
                float4 positionWS = mul(_TransformationMatrices[instanceId], float4(v.vertex.xyz, 1));
                o.positionCS = mul(UNITY_MATRIX_VP, positionWS);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normalWS = v.normal;
                
                return o;
            }
            
            half3 CustomLightingPhysicallyBased(float3 diffuse,
                half3 lightColor, half3 lightDirectionWS, float lightAttenuation,
                half3 normalWS)
            {
                half NdotL = saturate(dot(normalWS, lightDirectionWS));
                half3 radiance = lightColor * (lightAttenuation * NdotL);


                return diffuse * radiance;
            }
            
            half4 CustomFragmentPBR(InputData inputData, SurfaceData surfaceData)
            {

                // Clear-coat calculation...
                half4 shadowMask = CalculateShadowMask(inputData);
                //AmbientOcclusionFactor aoFactor = CreateAmbientOcclusionFactor(inputData, surfaceData);
                Light mainLight = GetMainLight(inputData.shadowCoord, inputData.positionWS, shadowMask);


                float3 attenuation = mainLight.distanceAttenuation * mainLight.shadowAttenuation;
                float3 diffuse = surfaceData.albedo;
                float3 mainLightColor = CustomLightingPhysicallyBased(diffuse, mainLight.color, mainLight.direction,
                    attenuation, inputData.normalWS);

                half3 lightColor = mainLightColor;
                return float4(lightColor, 1);
            }
            
            float4 frag (Input input) : SV_Target
            {
                float4 col = tex2D(_MainTex, input.uv);
                float2 uv = input.uv;
               // half4 albedoAlpha = half4(SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv));
                //float3 albedo = albedoAlpha.rgb * _BaseColor.rgb;

                half4 shadowMask = unity_ProbesOcclusion; 

                float4 coords = TransformWorldToShadowCoord(input.positionWS);
                Light mainLight = GetMainLight(coords, input.positionWS, shadowMask);


                float3 attenuation = mainLight.distanceAttenuation * mainLight.shadowAttenuation;
                //float3 diffuse = albedo;
                float3 mainLightColor = CustomLightingPhysicallyBased(1, mainLight.color, mainLight.direction,
                    attenuation, input.normalWS);

                half3 lightColor = mainLightColor;
                half4 color = float4(attenuation, 1);
                color.a = 1;

                return color;
/*
                
                half3 lightAccumulation = 0;
                float r;

                Light mainLight = GetMainLight();
                lightAccumulation.rgb += smoothstep(-0.5, 1.0, dot(-mainLight.direction, i.normal)) * sqrt(mainLight.color) * mainLight.distanceAttenuation;
                
                LIGHT_LOOP_BEGIN(0)
                {
                    Light light = GetAdditionalLight(lightIndex, i.positionWS);
                    {
                        lightAccumulation.rgb += smoothstep(-0.5, 1.0, dot(-light.direction, i.normal)) * sqrt(light.color) * light.distanceAttenuation;
                        r = light.distanceAttenuation;
                    }
                }
                LIGHT_LOOP_END
                
                half3 light = VertexLighting(i.positionWS, i.normal);

                return  float4(mainLight.distanceAttenuation, 0,0 ,1);
                //return col;
                
                return float4(lightAccumulation, 1);
                */
            }
            ENDHLSL
        }


    }
}
