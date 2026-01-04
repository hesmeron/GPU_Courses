Shader "Unlit/ProceduralDrawShader"
{
    Properties
    {
        [MainTexture] _MainTex("Albedo", 2D) = "white" {}
        [MainColor] _BaseColor("Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags
        {
            
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
            "UniversalMaterialType" = "Lit"
            "IgnoreProjector" = "True"
            
        }
        
        LOD 100
        
        
        Pass
        {
            // no LightMode tag are also rendered by Universal Render Pipeline
            Name "ForwardLitProcedural"
            Tags
            {
                //"LightMode" = "UniversalForward"
            }

            // -------------------------------------
            // Render State Commands
            Blend One Zero
            ZWrite On
            Cull Back


            HLSLPROGRAM
            #pragma target 2.0

            // -------------------------------------
            // Shader Stages
            #pragma vertex vert
            #pragma fragment frag

            // -------------------------------------

            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ EVALUATE_SH_MIXED EVALUATE_SH_VERTEX
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
            #pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
            #pragma multi_compile_fragment _ _LIGHT_COOKIES
            #pragma multi_compile _ _FORWARD_PLUS
            #pragma multi_compile USE_FORWARD_PLUS
            #include_with_pragmas "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRenderingKeywords.hlsl"
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"


            // -------------------------------------
            // Unity defined keywords

            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ProbeVolumeVariants.hlsl"

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma instancing_options renderinglayer

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            //#ifndef UNIVERSAL_FORWARD_LIT_PASS_INCLUDED
#define UNIVERSAL_FORWARD_LIT_PASS_INCLUDED



            struct Attributes
            {
                 float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float2 texcoord     : TEXCOORD0;
                float2 staticLightmapUV   : TEXCOORD1;
                float2 dynamicLightmapUV  : TEXCOORD2;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
                float4 shadowCoord  : TEXCOORD3;
                float2 normalizedScreenSpaceUV  : TEXCOORD4;
            };
            

            StructuredBuffer<float4x4> _TransformationMatrices;
            
            sampler2D _MainTex;
            float4 _MainTex_ST;

            Varyings vert (Attributes v, uint instanceId: SV_InstanceID)
            {
                Varyings o;
                float4 positionWS = mul(_TransformationMatrices[instanceId], float4(v.positionOS.xyz, 1));
                o.positionCS = mul(UNITY_MATRIX_VP, positionWS);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.normalWS = v.normalOS;
                o.shadowCoord = TransformWorldToShadowCoord(positionWS);
                o.normalizedScreenSpaceUV = o.positionCS.xy / _ScreenParams.xy;
                
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

            half3 CustomLightingPhysicallyBased(float3 diffuse, Light light,half3 normalWS)
            {
                float3 attenuation = light.distanceAttenuation * light.shadowAttenuation;

                return CustomLightingPhysicallyBased(diffuse, light.color, light.direction,attenuation, normalWS);
            }
            
            float4 frag (Varyings inputData) : SV_Target
            {
                float4 col = tex2D(_MainTex, inputData.uv);
                //return col;
                half4 shadowMask = unity_ProbesOcclusion; 
                
                Light mainLight = GetMainLight(inputData.shadowCoord, inputData.positionWS, shadowMask);


                float3 attenuation = mainLight.distanceAttenuation * mainLight.shadowAttenuation;
                float3 diffuse = col;
                float3 mainLightColor = CustomLightingPhysicallyBased(diffuse, mainLight.color, mainLight.direction,
                    attenuation, inputData.normalWS);

                half3 lightColor = mainLightColor;

                uint pixelLightCount = GetAdditionalLightsCount();
                float3 additionalLightsColor;
                
                LIGHT_LOOP_BEGIN(pixelLightCount)
                    Light light = GetAdditionalLight(lightIndex, inputData.positionWS, shadowMask);
                    additionalLightsColor += CustomLightingPhysicallyBased(diffuse, light, inputData.normalWS);
                LIGHT_LOOP_END
                half4 color = float4(col.rgb * (lightColor + additionalLightsColor), 1);
                return color;
            }
            
            ENDHLSL
        }

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
            Blend One Zero
            ZWrite On
            Cull Back


            HLSLPROGRAM
            #pragma target 2.0

            // -------------------------------------
            // Shader Stages
            #pragma vertex CustomLitPassVertex
            #pragma fragment frag

            // -------------------------------------

            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ EVALUATE_SH_MIXED EVALUATE_SH_VERTEX
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
            #pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
            #pragma multi_compile_fragment _ _LIGHT_COOKIES
            #pragma multi_compile _ _FORWARD_PLUS
            #pragma multi_compile USE_FORWARD_PLUS
            #include_with_pragmas "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRenderingKeywords.hlsl"
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"


            // -------------------------------------
            // Unity defined keywords

            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ProbeVolumeVariants.hlsl"

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma instancing_options renderinglayer

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            //#ifndef UNIVERSAL_FORWARD_LIT_PASS_INCLUDED
#define UNIVERSAL_FORWARD_LIT_PASS_INCLUDED



            struct Attributes
            {
                 float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float2 texcoord     : TEXCOORD0;
                float2 staticLightmapUV   : TEXCOORD1;
                float2 dynamicLightmapUV  : TEXCOORD2;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
                float4 shadowCoord  : TEXCOORD3;
                float2 normalizedScreenSpaceUV  : TEXCOORD4;
            };
            
            sampler2D _MainTex;
            float4 _MainTex_ST;

            Varyings CustomLitPassVertex(Attributes input)
            {
                Varyings output = (Varyings)0;
                float3 positionWS = TransformObjectToWorld(input.positionOS);
                float4 positionCS = TransformWorldToHClip(positionWS);
                float3 normalWS = TransformObjectToWorldNormal(input.normalOS);
                
                output.uv = TRANSFORM_TEX(input.texcoord, _MainTex);
                
                output.normalWS = normalWS;

                output.positionWS = positionWS;

                output.positionCS = positionCS;


                return output;
            }



            
            half3 CustomLightingPhysicallyBased(float3 diffuse,
                half3 lightColor, half3 lightDirectionWS, float lightAttenuation,
                half3 normalWS)
            {
                half NdotL = saturate(dot(normalWS, lightDirectionWS));
                half3 radiance = lightColor * (lightAttenuation * NdotL);


                return diffuse * radiance;
            }

            half3 CustomLightingPhysicallyBased(float3 diffuse, Light light,half3 normalWS)
            {
                float3 attenuation = light.distanceAttenuation * light.shadowAttenuation;

                return CustomLightingPhysicallyBased(diffuse, light.color, light.direction,attenuation, normalWS);
            }

            

            float4 frag (Varyings inputData) : SV_Target
            {
                float4 col = tex2D(_MainTex, inputData.uv);
                //return col;
                half4 shadowMask = unity_ProbesOcclusion; 
                
                Light mainLight = GetMainLight(inputData.shadowCoord, inputData.positionWS, shadowMask);


                float3 attenuation = mainLight.distanceAttenuation * mainLight.shadowAttenuation;
                float3 diffuse = col;
                float3 mainLightColor = CustomLightingPhysicallyBased(diffuse, mainLight.color, mainLight.direction,
                    attenuation, inputData.normalWS);

                half3 lightColor = mainLightColor;

                uint pixelLightCount = GetAdditionalLightsCount();
                float3 additionalLightsColor;
                
                LIGHT_LOOP_BEGIN(pixelLightCount)
                    Light light = GetAdditionalLight(lightIndex, inputData.positionWS, shadowMask);
                    additionalLightsColor += CustomLightingPhysicallyBased(diffuse, light, inputData.normalWS);
                LIGHT_LOOP_END
                half4 color = float4(col.rgb * (lightColor + additionalLightsColor), 1);
                return color;
                }
                ENDHLSL
            }


    }
}
