Shader "Universal Render Experimental/Lit2"
{
    Properties
    {
        // Specular vs Metallic workflow
        _WorkflowMode("WorkflowMode", Float) = 1.0

        [MainTexture] _BaseMap("Albedo", 2D) = "white" {}
        [MainColor] _BaseColor("Color", Color) = (1,1,1,1)

        _Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5

        _Smoothness("Smoothness", Range(0.0, 1.0)) = 0.5
        _SmoothnessTextureChannel("Smoothness texture channel", Float) = 0

        _Metallic("Metallic", Range(0.0, 1.0)) = 0.0
        _MetallicGlossMap("Metallic", 2D) = "white" {}

        _SpecColor("Specular", Color) = (0.2, 0.2, 0.2)
        _SpecGlossMap("Specular", 2D) = "white" {}

        [ToggleOff] _SpecularHighlights("Specular Highlights", Float) = 1.0
        [ToggleOff] _EnvironmentReflections("Environment Reflections", Float) = 1.0

        _BumpScale("Scale", Float) = 1.0
        _BumpMap("Normal Map", 2D) = "bump" {}

        _Parallax("Scale", Range(0.005, 0.08)) = 0.005
        _ParallaxMap("Height Map", 2D) = "black" {}

        _OcclusionStrength("Strength", Range(0.0, 1.0)) = 1.0
        _OcclusionMap("Occlusion", 2D) = "white" {}

        [HDR] _EmissionColor("Color", Color) = (0,0,0)
        _EmissionMap("Emission", 2D) = "white" {}

        _DetailMask("Detail Mask", 2D) = "white" {}
        _DetailAlbedoMapScale("Scale", Range(0.0, 2.0)) = 1.0
        _DetailAlbedoMap("Detail Albedo x2", 2D) = "linearGrey" {}
        _DetailNormalMapScale("Scale", Range(0.0, 2.0)) = 1.0
        [Normal] _DetailNormalMap("Normal Map", 2D) = "bump" {}

        // SRP batching compatibility for Clear Coat (Not used in Lit)
        [HideInInspector] _ClearCoatMask("_ClearCoatMask", Float) = 0.0
        [HideInInspector] _ClearCoatSmoothness("_ClearCoatSmoothness", Float) = 0.0

        // Blending state
        _Surface("__surface", Float) = 0.0
        _Blend("__blend", Float) = 0.0
        _Cull("__cull", Float) = 2.0
        [ToggleUI] _AlphaClip("__clip", Float) = 0.0
        [HideInInspector] _SrcBlend("__src", Float) = 1.0
        [HideInInspector] _DstBlend("__dst", Float) = 0.0
        [HideInInspector] _SrcBlendAlpha("__srcA", Float) = 1.0
        [HideInInspector] _DstBlendAlpha("__dstA", Float) = 0.0
        [HideInInspector] _ZWrite("__zw", Float) = 1.0
        [HideInInspector] _BlendModePreserveSpecular("_BlendModePreserveSpecular", Float) = 1.0
        [HideInInspector] _AlphaToMask("__alphaToMask", Float) = 0.0
        [HideInInspector] _AddPrecomputedVelocity("_AddPrecomputedVelocity", Float) = 0.0

        [ToggleUI] _ReceiveShadows("Receive Shadows", Float) = 1.0
        // Editmode props
        _QueueOffset("Queue offset", Float) = 0.0

        // ObsoleteProperties
        [HideInInspector] _MainTex("BaseMap", 2D) = "white" {}
        [HideInInspector] _Color("Base Color", Color) = (1, 1, 1, 1)
        [HideInInspector] _GlossMapScale("Smoothness", Float) = 0.0
        [HideInInspector] _Glossiness("Smoothness", Float) = 0.0
        [HideInInspector] _GlossyReflections("EnvironmentReflections", Float) = 0.0

        [HideInInspector][NoScaleOffset]unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_ShadowMasks("unity_ShadowMasks", 2DArray) = "" {}
    }

    SubShader
    {
        // Universal Pipeline tag is required. If Universal render pipeline is not set in the graphics settings
        // this Subshader will fail. One can add a subshader below or fallback to Standard built-in to make this
        // material work with both Universal Render Pipeline and Builtin Unity Pipeline
        Tags
        {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
            "UniversalMaterialType" = "Lit"
            "IgnoreProjector" = "True"
        }
        LOD 300

        // ------------------------------------------------------------------
        //  Forward pass. Shades all light in a single pass. GI + emission + Fog
        Pass
        {
            // Lightmode matches the ShaderPassName set in UniversalRenderPipeline.cs. SRPDefaultUnlit and passes with
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
            #pragma vertex LitPassVertex
            #pragma fragment LitPassFragment

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
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #ifndef UNIVERSAL_FORWARD_LIT_PASS_INCLUDED
#define UNIVERSAL_FORWARD_LIT_PASS_INCLUDED

#ifndef UNIVERSAL_LIGHTING_INCLUDED
#define UNIVERSAL_LIGHTING_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/BRDF.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Debug/Debugging3D.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/GlobalIllumination.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RealtimeLights.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/AmbientOcclusion.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"

#if defined(LIGHTMAP_ON)
    #define DECLARE_LIGHTMAP_OR_SH(lmName, shName, index) float2 lmName : TEXCOORD##index
    #define OUTPUT_LIGHTMAP_UV(lightmapUV, lightmapScaleOffset, OUT) OUT.xy = lightmapUV.xy * lightmapScaleOffset.xy + lightmapScaleOffset.zw;
    #define OUTPUT_SH4(absolutePositionWS, normalWS, viewDir, OUT, OUT_OCCLUSION)
    #define OUTPUT_SH(normalWS, OUT)
#else
    #define DECLARE_LIGHTMAP_OR_SH(lmName, shName, index) half3 shName : TEXCOORD##index
    #define OUTPUT_LIGHTMAP_UV(lightmapUV, lightmapScaleOffset, OUT)
    #ifdef USE_APV_PROBE_OCCLUSION
        #define OUTPUT_SH4(absolutePositionWS, normalWS, viewDir, OUT, OUT_OCCLUSION) OUT.xyz = SampleProbeSHVertex(absolutePositionWS, normalWS, viewDir, OUT_OCCLUSION)
    #else
        #define OUTPUT_SH4(absolutePositionWS, normalWS, viewDir, OUT, OUT_OCCLUSION) OUT.xyz = SampleProbeSHVertex(absolutePositionWS, normalWS, viewDir)
    #endif
    // Note: This is the legacy function, which does not support APV.
    // Kept to avoid breaking shaders still calling it (UUM-37723)
    #define OUTPUT_SH(normalWS, OUT) OUT.xyz = SampleSHVertex(normalWS)
#endif

///////////////////////////////////////////////////////////////////////////////
//                      Lighting Functions                                   //
///////////////////////////////////////////////////////////////////////////////
half3 LightingLambert(half3 lightColor, half3 lightDir, half3 normal)
{
    half NdotL = saturate(dot(normal, lightDir));
    return lightColor * NdotL;
}

half3 LightingSpecular(half3 lightColor, half3 lightDir, half3 normal, half3 viewDir, half4 specular, half smoothness)
{
    float3 halfVec = SafeNormalize(float3(lightDir) + float3(viewDir));
    half NdotH = half(saturate(dot(normal, halfVec)));
    half modifier = pow(float(NdotH), float(smoothness)); // Half produces banding, need full precision
    // NOTE: In order to fix internal compiler error on mobile platforms, this needs to be float3
    float3 specularReflection = specular.rgb * modifier;
    return lightColor * specularReflection;
}

half3 LightingPhysicallyBased(BRDFData brdfData, BRDFData brdfDataClearCoat,
    half3 lightColor, half3 lightDirectionWS, float lightAttenuation,
    half3 normalWS, half3 viewDirectionWS,
    half clearCoatMask, bool specularHighlightsOff)
{
    half NdotL = saturate(dot(normalWS, lightDirectionWS));
    half3 radiance = lightColor * (lightAttenuation * NdotL);

    half3 brdf = brdfData.diffuse;
#ifndef _SPECULARHIGHLIGHTS_OFF
    [branch] if (!specularHighlightsOff)
    {
        brdf += brdfData.specular * DirectBRDFSpecular(brdfData, normalWS, lightDirectionWS, viewDirectionWS);

#if defined(_CLEARCOAT) || defined(_CLEARCOATMAP)
        // Clear coat evaluates the specular a second timw and has some common terms with the base specular.
        // We rely on the compiler to merge these and compute them only once.
        half brdfCoat = kDielectricSpec.r * DirectBRDFSpecular(brdfDataClearCoat, normalWS, lightDirectionWS, viewDirectionWS);

            // Mix clear coat and base layer using khronos glTF recommended formula
            // https://github.com/KhronosGroup/glTF/blob/master/extensions/2.0/Khronos/KHR_materials_clearcoat/README.md
            // Use NoV for direct too instead of LoH as an optimization (NoV is light invariant).
            half NoV = saturate(dot(normalWS, viewDirectionWS));
            // Use slightly simpler fresnelTerm (Pow4 vs Pow5) as a small optimization.
            // It is matching fresnel used in the GI/Env, so should produce a consistent clear coat blend (env vs. direct)
            half coatFresnel = kDielectricSpec.x + kDielectricSpec.a * Pow4(1.0 - NoV);

        brdf = brdf * (1.0 - clearCoatMask * coatFresnel) + brdfCoat * clearCoatMask;
#endif // _CLEARCOAT
    }
#endif // _SPECULARHIGHLIGHTS_OFF

    return brdf * radiance;
}

half3 LightingPhysicallyBased(BRDFData brdfData, BRDFData brdfDataClearCoat, Light light, half3 normalWS, half3 viewDirectionWS, half clearCoatMask, bool specularHighlightsOff)
{
    return LightingPhysicallyBased(brdfData, brdfDataClearCoat, light.color, light.direction, light.distanceAttenuation * light.shadowAttenuation, normalWS, viewDirectionWS, clearCoatMask, specularHighlightsOff);
}

// Backwards compatibility
half3 LightingPhysicallyBased(BRDFData brdfData, Light light, half3 normalWS, half3 viewDirectionWS)
{
    #ifdef _SPECULARHIGHLIGHTS_OFF
    bool specularHighlightsOff = true;
#else
    bool specularHighlightsOff = false;
#endif
    const BRDFData noClearCoat = (BRDFData)0;
    return LightingPhysicallyBased(brdfData, noClearCoat, light, normalWS, viewDirectionWS, 0.0, specularHighlightsOff);
}

half3 LightingPhysicallyBased(BRDFData brdfData, half3 lightColor, half3 lightDirectionWS, float lightAttenuation, half3 normalWS, half3 viewDirectionWS)
{
    Light light;
    light.color = lightColor;
    light.direction = lightDirectionWS;
    light.distanceAttenuation = lightAttenuation;
    light.shadowAttenuation   = 1;
    return LightingPhysicallyBased(brdfData, light, normalWS, viewDirectionWS);
}

half3 LightingPhysicallyBased(BRDFData brdfData, Light light, half3 normalWS, half3 viewDirectionWS, bool specularHighlightsOff)
{
    const BRDFData noClearCoat = (BRDFData)0;
    return LightingPhysicallyBased(brdfData, noClearCoat, light, normalWS, viewDirectionWS, 0.0, specularHighlightsOff);
}

half3 LightingPhysicallyBased(BRDFData brdfData, half3 lightColor, half3 lightDirectionWS, float lightAttenuation, half3 normalWS, half3 viewDirectionWS, bool specularHighlightsOff)
{
    Light light;
    light.color = lightColor;
    light.direction = lightDirectionWS;
    light.distanceAttenuation = lightAttenuation;
    light.shadowAttenuation   = 1;
    return LightingPhysicallyBased(brdfData, light, viewDirectionWS, specularHighlightsOff, specularHighlightsOff);
}

half3 VertexLighting(float3 positionWS, half3 normalWS)
{
    half3 vertexLightColor = half3(0.0, 0.0, 0.0);

#ifdef _ADDITIONAL_LIGHTS_VERTEX
    uint lightsCount = GetAdditionalLightsCount();
    uint meshRenderingLayers = GetMeshRenderingLayer();

    LIGHT_LOOP_BEGIN(lightsCount)
        Light light = GetAdditionalLight(lightIndex, positionWS);

#ifdef _LIGHT_LAYERS
    if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
#endif
    {
        half3 lightColor = light.color * light.distanceAttenuation;
        vertexLightColor += LightingLambert(lightColor, light.direction, normalWS);
    }

    LIGHT_LOOP_END
#endif

    return vertexLightColor;
}

struct LightingData
{
    half3 giColor;
    half3 mainLightColor;
    half3 additionalLightsColor;
    half3 vertexLightingColor;
    half3 emissionColor;
};

half3 CalculateLightingColor(LightingData lightingData, half3 albedo)
{
    half3 lightingColor = 0;

    if (IsOnlyAOLightingFeatureEnabled())
    {
        return lightingData.giColor; // Contains white + AO
    }

    if (IsLightingFeatureEnabled(DEBUGLIGHTINGFEATUREFLAGS_GLOBAL_ILLUMINATION))
    {
        lightingColor += lightingData.giColor;
    }

    if (IsLightingFeatureEnabled(DEBUGLIGHTINGFEATUREFLAGS_MAIN_LIGHT))
    {
        lightingColor += lightingData.mainLightColor;
    }

    if (IsLightingFeatureEnabled(DEBUGLIGHTINGFEATUREFLAGS_ADDITIONAL_LIGHTS))
    {
        lightingColor += lightingData.additionalLightsColor;
    }

    if (IsLightingFeatureEnabled(DEBUGLIGHTINGFEATUREFLAGS_VERTEX_LIGHTING))
    {
        lightingColor += lightingData.vertexLightingColor;
    }

    lightingColor *= albedo;

    if (IsLightingFeatureEnabled(DEBUGLIGHTINGFEATUREFLAGS_EMISSION))
    {
        lightingColor += lightingData.emissionColor;
    }

    return lightingColor;
}

half4 CalculateFinalColor(LightingData lightingData, half alpha)
{
    half3 finalColor = CalculateLightingColor(lightingData, 1);

    return half4(finalColor, alpha);
}

half4 CalculateFinalColor(LightingData lightingData, half3 albedo, half alpha, float fogCoord)
{
    #if defined(_FOG_FRAGMENT)
        #if (defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2))
        float viewZ = -fogCoord;
        float nearToFarZ = max(viewZ - _ProjectionParams.y, 0);
        half fogFactor = ComputeFogFactorZ0ToFar(nearToFarZ);
    #else
        half fogFactor = 0;
        #endif
    #else
    half fogFactor = fogCoord;
    #endif
    half3 lightingColor = CalculateLightingColor(lightingData, albedo);
    half3 finalColor = MixFog(lightingColor, fogFactor);

    return half4(finalColor, alpha);
}

LightingData CreateLightingData(InputData inputData, SurfaceData surfaceData)
{
    LightingData lightingData;

    lightingData.giColor = inputData.bakedGI;
    lightingData.emissionColor = surfaceData.emission;
    lightingData.vertexLightingColor = 0;
    lightingData.mainLightColor = 0;
    lightingData.additionalLightsColor = 0;

    return lightingData;
}
/*
half3 CalculateBlinnPhong(Light light, InputData inputData, SurfaceData surfaceData)
{
    half3 attenuatedLightColor = light.color * (light.distanceAttenuation * light.shadowAttenuation);
    half3 lightDiffuseColor = LightingLambert(attenuatedLightColor, light.direction, inputData.normalWS);

    half3 lightSpecularColor = half3(0,0,0);
    #if defined(_SPECGLOSSMAP) || defined(_SPECULAR_COLOR)
    half smoothness = exp2(10 * surfaceData.smoothness + 1);

    lightSpecularColor += LightingSpecular(attenuatedLightColor, light.direction, inputData.normalWS, inputData.viewDirectionWS, half4(surfaceData.specular, 1), smoothness);
    #endif

#if _ALPHAPREMULTIPLY_ON
    return lightDiffuseColor * surfaceData.albedo * surfaceData.alpha + lightSpecularColor;
#else
    return lightDiffuseColor * surfaceData.albedo + lightSpecularColor;
#endif
}*/


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

            
half4 AdditionalLightColor(InputData inputData, SurfaceData surfaceData, float3 positionWS, float3 normalWS)
{
    half4 shadowMask = CalculateShadowMask(inputData);
    AmbientOcclusionFactor aoFactor = CreateAmbientOcclusionFactor(inputData, surfaceData);
    uint pixelLightCount = GetAdditionalLightsCount();


    float3 additionalLightsColor;
    
    float4 diffuse = 1;

    LIGHT_LOOP_BEGIN(pixelLightCount)
        Light light = GetAdditionalLight(lightIndex, positionWS, shadowMask);
        additionalLightsColor += CustomLightingPhysicallyBased(diffuse, light, normalWS);
        //additionalLightsColor += LightingPhysicallyBased(brdfData, brdfDataClearCoat, light,inputData.normalWS, inputData.viewDirectionWS,surfaceData.clearCoatMask, false);
        
    LIGHT_LOOP_END



    return float4(additionalLightsColor,1);
}

////////////////////////////////////////////////////////////////////////////////
/// Phong lighting...
////////////////////////////////////////////////////////////////////////////////
///
/*
half4 UniversalFragmentBlinnPhong(InputData inputData, SurfaceData surfaceData)
{
    #if defined(DEBUG_DISPLAY)
    half4 debugColor;

    if (CanDebugOverrideOutputColor(inputData, surfaceData, debugColor))
    {
        return debugColor;
    }
    #endif

    uint meshRenderingLayers = GetMeshRenderingLayer();
    half4 shadowMask = CalculateShadowMask(inputData);
    AmbientOcclusionFactor aoFactor = CreateAmbientOcclusionFactor(inputData, surfaceData);
    Light mainLight = GetMainLight(inputData, shadowMask, aoFactor);

    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI, aoFactor);

    inputData.bakedGI *= surfaceData.albedo;

    LightingData lightingData = CreateLightingData(inputData, surfaceData);
#ifdef _LIGHT_LAYERS
    if (IsMatchingLightLayer(mainLight.layerMask, meshRenderingLayers))
#endif
    {
        lightingData.mainLightColor += CalculateBlinnPhong(mainLight, inputData, surfaceData);
    }

    #if defined(_ADDITIONAL_LIGHTS)
    uint pixelLightCount = GetAdditionalLightsCount();

    #if USE_FORWARD_PLUS
    [loop] for (uint lightIndex = 0; lightIndex < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS); lightIndex++)
    {
        FORWARD_PLUS_SUBTRACTIVE_LIGHT_CHECK

        Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);
#ifdef _LIGHT_LAYERS
        if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
#endif
        {
            lightingData.additionalLightsColor += CalculateBlinnPhong(light, inputData, surfaceData);
        }
    }
    #endif

    LIGHT_LOOP_BEGIN(pixelLightCount)
        Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);
#ifdef _LIGHT_LAYERS
        if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
#endif
        {
            lightingData.additionalLightsColor += CalculateBlinnPhong(light, inputData, surfaceData);
        }
    LIGHT_LOOP_END
    #endif

    #if defined(_ADDITIONAL_LIGHTS_VERTEX)
    lightingData.vertexLightingColor += inputData.vertexLighting * surfaceData.albedo;
    #endif

    return GetAdditionalLightsCount(); //CalculateFinalColor(lightingData, surfaceData.alpha);
}


// Deprecated: Use the version which takes "SurfaceData" instead of passing all of these arguments...
half4 UniversalFragmentBlinnPhong(InputData inputData, half3 diffuse, half4 specularGloss, half smoothness, half3 emission, half alpha, half3 normalTS)
{
    SurfaceData surfaceData;

    surfaceData.albedo = diffuse;
    surfaceData.alpha = alpha;
    surfaceData.emission = emission;
    surfaceData.metallic = 0;
    surfaceData.occlusion = 1;
    surfaceData.smoothness = smoothness;
    surfaceData.specular = specularGloss.rgb;
    surfaceData.clearCoatMask = 0;
    surfaceData.clearCoatSmoothness = 1;
    surfaceData.normalTS = normalTS;

    return UniversalFragmentBlinnPhong(inputData, surfaceData);
}
            */


#endif


// keep this file in sync with LitGBufferPass.hlsl



struct Attributes
{
    float4 positionOS   : POSITION;
    float3 normalOS     : NORMAL;
    float4 tangentOS    : TANGENT;
    float2 texcoord     : TEXCOORD0;
    float2 staticLightmapUV   : TEXCOORD1;
    float2 dynamicLightmapUV  : TEXCOORD2;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float2 uv                       : TEXCOORD0;
    float3 positionWS               : TEXCOORD1;
    float3 normalWS                 : TEXCOORD2;
    half  fogFactor                 : TEXCOORD5;



    float4 shadowCoord              : TEXCOORD6;


    float4 positionCS               : SV_POSITION;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

void InitializeInputData(Varyings input, half3 normalTS, out InputData inputData)
{
    inputData = (InputData)0;

#if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
    inputData.positionWS = input.positionWS;
#endif



    half3 viewDirWS = GetWorldSpaceNormalizeViewDir(input.positionWS);
#if defined(_NORMALMAP) || defined(_DETAIL)
    float sgn = input.tangentWS.w;      // should be either +1 or -1
    float3 bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
    half3x3 tangentToWorld = half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz);

    #if defined(_NORMALMAP)
    inputData.tangentToWorld = tangentToWorld;
    #endif
    inputData.normalWS = TransformTangentToWorld(normalTS, tangentToWorld);
#else
    inputData.normalWS = input.normalWS;
#endif

    inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
    inputData.viewDirectionWS = viewDirWS;

#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    inputData.shadowCoord = input.shadowCoord;
#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
    inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
#else
    inputData.shadowCoord = float4(0, 0, 0, 0);
#endif

    inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);

    #if defined(DEBUG_DISPLAY)
    #if defined(DYNAMICLIGHTMAP_ON)
    inputData.dynamicLightmapUV = input.dynamicLightmapUV;
    #endif
    #if defined(LIGHTMAP_ON)
    inputData.staticLightmapUV = input.staticLightmapUV;
    #else
    inputData.vertexSH = input.vertexSH;
    #endif
    #if defined(USE_APV_PROBE_OCCLUSION)
    inputData.probeOcclusion = input.probeOcclusion;
    #endif
    #endif
}

void InitializeBakedGIData(Varyings input, inout InputData inputData)
{
    #if defined(DYNAMICLIGHTMAP_ON)
    inputData.bakedGI = SAMPLE_GI(input.staticLightmapUV, input.dynamicLightmapUV, input.vertexSH, inputData.normalWS);
    inputData.shadowMask = SAMPLE_SHADOWMASK(input.staticLightmapUV);
    #elif !defined(LIGHTMAP_ON) && (defined(PROBE_VOLUMES_L1) || defined(PROBE_VOLUMES_L2))
    inputData.bakedGI = SAMPLE_GI(input.vertexSH,
        GetAbsolutePositionWS(inputData.positionWS),
        inputData.normalWS,
        inputData.viewDirectionWS,
        input.positionCS.xy,
        input.probeOcclusion,
        inputData.shadowMask);
    #else
    //inputData.bakedGI = SAMPLE_GI(input.staticLightmapUV, input.vertexSH, inputData.normalWS);
    inputData.shadowMask = SAMPLE_SHADOWMASK(input.staticLightmapUV);
    #endif
}

///////////////////////////////////////////////////////////////////////////////
//                  Vertex and Fragment functions                            //
///////////////////////////////////////////////////////////////////////////////

// Used in Standard (Physically Based) shader
Varyings LitPassVertex(Attributes input)
{
    Varyings output = (Varyings)0;

    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);

    // normalWS and tangentWS already normalize.
    // this is required to avoid skewing the direction during interpolation
    // also required for per-vertex lighting and SH evaluation
    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

    half3 vertexLight = VertexLighting(vertexInput.positionWS, normalInput.normalWS);

    half fogFactor = 0;
    #if !defined(_FOG_FRAGMENT)
        fogFactor = ComputeFogFactor(vertexInput.positionCS.z);
    #endif

    output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);

    // already normalized from normal transform to WS.
    output.normalWS = normalInput.normalWS;
#if defined(REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR) || defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
    real sign = input.tangentOS.w * GetOddNegativeScale();
    half4 tangentWS = half4(normalInput.tangentWS.xyz, sign);
#endif
#if defined(REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR)
    output.tangentWS = tangentWS;
#endif

#if defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
    half3 viewDirWS = GetWorldSpaceNormalizeViewDir(vertexInput.positionWS);
    half3 viewDirTS = GetViewDirectionTangentSpace(tangentWS, output.normalWS, viewDirWS);
    output.viewDirTS = viewDirTS;
#endif

    OUTPUT_LIGHTMAP_UV(input.staticLightmapUV, unity_LightmapST, output.staticLightmapUV);
#ifdef DYNAMICLIGHTMAP_ON
    output.dynamicLightmapUV = input.dynamicLightmapUV.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
#endif
   // OUTPUT_SH4(vertexInput.positionWS, output.normalWS.xyz, GetWorldSpaceNormalizeViewDir(vertexInput.positionWS), output.vertexSH, output.probeOcclusion);
#ifdef _ADDITIONAL_LIGHTS_VERTEX
    output.fogFactorAndVertexLight = half4(fogFactor, vertexLight);
#else
    output.fogFactor = fogFactor;
#endif

#if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
    output.positionWS = vertexInput.positionWS;
#endif

#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    output.shadowCoord = GetShadowCoord(vertexInput);
#endif

    output.positionCS = vertexInput.positionCS;

    return output;
}

// Used in Standard (Physically Based) shader
void LitPassFragment(
    Varyings input
    , out half4 outColor : SV_Target0
#ifdef _WRITE_RENDERING_LAYERS
    , out float4 outRenderingLayers : SV_Target1
#endif
)
{
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

#if defined(_PARALLAXMAP)
#if defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
    half3 viewDirTS = input.viewDirTS;
#else
    half3 viewDirWS = GetWorldSpaceNormalizeViewDir(input.positionWS);
    half3 viewDirTS = GetViewDirectionTangentSpace(input.tangentWS, input.normalWS, viewDirWS);
#endif
    ApplyPerPixelDisplacement(viewDirTS, input.uv);
#endif

    SurfaceData surfaceData;
    InitializeStandardLitSurfaceData(input.uv, surfaceData);



    InputData inputData;
    InitializeInputData(input, surfaceData.normalTS, inputData);
    SETUP_DEBUG_TEXTURE_DATA(inputData, UNDO_TRANSFORM_TEX(input.uv, _BaseMap));



    InitializeBakedGIData(input, inputData);

    //half4 color = AdditionalLightColor(inputData, surfaceData, input.positionWS , input.normalWS);
    //color.rgb = MixFog(color.rgb, inputData.fogCoord);
   // color.a = 1; OutputAlpha(color.a, IsSurfaceTypeTransparent(_Surface));

    //outColor = color;


    uint pixelLightCount = GetAdditionalLightsCount();
    float3 additionalLightsColor;

    
    float4 diffuse = 1;
    half4 shadowMask = unity_ProbesOcclusion; 
    LIGHT_LOOP_BEGIN(pixelLightCount)
        Light light = GetAdditionalLight(lightIndex, inputData.positionWS, shadowMask);
        additionalLightsColor += CustomLightingPhysicallyBased(diffuse, light, inputData.normalWS);
        //additionalLightsColor += LightingPhysicallyBased(brdfData, brdfDataClearCoat, light,inputData.normalWS, inputData.viewDirectionWS,surfaceData.clearCoatMask, false);
        
    LIGHT_LOOP_END

    outColor = float4(additionalLightsColor,1);

}

#endif

            ENDHLSL
        }
        
        Pass
        {
            // Lightmode matches the ShaderPassName set in UniversalRenderPipeline.cs. SRPDefaultUnlit and passes with
            // no LightMode tag are also rendered by Universal Render Pipeline
            Name "ForwardLitProcedural"
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
            #pragma vertex CustomLitPassVertex
            #pragma fragment LitPassFragment
            
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
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #ifndef UNIVERSAL_FORWARD_LIT_PASS_INCLUDED
#define UNIVERSAL_FORWARD_LIT_PASS_INCLUDED

#ifndef UNIVERSAL_LIGHTING_INCLUDED
#define UNIVERSAL_LIGHTING_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/BRDF.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Debug/Debugging3D.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/GlobalIllumination.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RealtimeLights.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/AmbientOcclusion.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"

#if defined(LIGHTMAP_ON)
    #define DECLARE_LIGHTMAP_OR_SH(lmName, shName, index) float2 lmName : TEXCOORD##index
    #define OUTPUT_LIGHTMAP_UV(lightmapUV, lightmapScaleOffset, OUT) OUT.xy = lightmapUV.xy * lightmapScaleOffset.xy + lightmapScaleOffset.zw;
    #define OUTPUT_SH4(absolutePositionWS, normalWS, viewDir, OUT, OUT_OCCLUSION)
    #define OUTPUT_SH(normalWS, OUT)
#else
    #define DECLARE_LIGHTMAP_OR_SH(lmName, shName, index) half3 shName : TEXCOORD##index
    #define OUTPUT_LIGHTMAP_UV(lightmapUV, lightmapScaleOffset, OUT)
    #ifdef USE_APV_PROBE_OCCLUSION
        #define OUTPUT_SH4(absolutePositionWS, normalWS, viewDir, OUT, OUT_OCCLUSION) OUT.xyz = SampleProbeSHVertex(absolutePositionWS, normalWS, viewDir, OUT_OCCLUSION)
    #else
        #define OUTPUT_SH4(absolutePositionWS, normalWS, viewDir, OUT, OUT_OCCLUSION) OUT.xyz = SampleProbeSHVertex(absolutePositionWS, normalWS, viewDir)
    #endif
    // Note: This is the legacy function, which does not support APV.
    // Kept to avoid breaking shaders still calling it (UUM-37723)
    #define OUTPUT_SH(normalWS, OUT) OUT.xyz = SampleSHVertex(normalWS)
#endif
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
                float4 shadowCoord  : TEXCOORD2;
                float2 normalizedScreenSpaceUV  : TEXCOORD3;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
struct Attributes
{
    float4 positionOS   : POSITION;
    float3 normalOS     : NORMAL;
    float4 tangentOS    : TANGENT;
    float2 texcoord     : TEXCOORD0;
    float2 staticLightmapUV   : TEXCOORD1;
    float2 dynamicLightmapUV  : TEXCOORD2;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float2 uv                       : TEXCOORD0;
    float3 positionWS               : TEXCOORD1;
    float3 normalWS                 : TEXCOORD2;
    half  fogFactor                 : TEXCOORD5;



    float4 shadowCoord              : TEXCOORD6;


    float4 positionCS               : SV_POSITION;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};     

// Used in Standard (Physically Based) shader
Varyings LitPassVertex(Attributes input)
{
    Varyings output = (Varyings)0;

    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);

    // normalWS and tangentWS already normalize.
    // this is required to avoid skewing the direction during interpolation
    // also required for per-vertex lighting and SH evaluation
    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

    //half3 vertexLight = VertexLighting(vertexInput.positionWS, normalInput.normalWS);

    half fogFactor = 0;
    #if !defined(_FOG_FRAGMENT)
        fogFactor = ComputeFogFactor(vertexInput.positionCS.z);
    #endif

    output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);

    // already normalized from normal transform to WS.
    output.normalWS = normalInput.normalWS;
#if defined(REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR) || defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
    real sign = input.tangentOS.w * GetOddNegativeScale();
    half4 tangentWS = half4(normalInput.tangentWS.xyz, sign);
#endif
#if defined(REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR)
    output.tangentWS = tangentWS;
#endif

#if defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
    half3 viewDirWS = GetWorldSpaceNormalizeViewDir(vertexInput.positionWS);
    half3 viewDirTS = GetViewDirectionTangentSpace(tangentWS, output.normalWS, viewDirWS);
    output.viewDirTS = viewDirTS;
#endif

    OUTPUT_LIGHTMAP_UV(input.staticLightmapUV, unity_LightmapST, output.staticLightmapUV);
#ifdef DYNAMICLIGHTMAP_ON
    output.dynamicLightmapUV = input.dynamicLightmapUV.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
#endif
   // OUTPUT_SH4(vertexInput.positionWS, output.normalWS.xyz, GetWorldSpaceNormalizeViewDir(vertexInput.positionWS), output.vertexSH, output.probeOcclusion);
#ifdef _ADDITIONAL_LIGHTS_VERTEX
    output.fogFactorAndVertexLight = half4(fogFactor, vertexLight);
#else
    output.fogFactor = fogFactor;
#endif

#if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
    output.positionWS = vertexInput.positionWS;
#endif

#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    output.shadowCoord = GetShadowCoord(vertexInput);
#endif

    output.positionCS = vertexInput.positionCS;

    return output;
}
            
///////////////////////////////////////////////////////////////////////////////
//                      Lighting Functions                                   //
///////////////////////////////////////////////////////////////////////////////
half3 LightingLambert(half3 lightColor, half3 lightDir, half3 normal)
{
    half NdotL = saturate(dot(normal, lightDir));
    return lightColor * NdotL;
}

half3 LightingSpecular(half3 lightColor, half3 lightDir, half3 normal, half3 viewDir, half4 specular, half smoothness)
{
    float3 halfVec = SafeNormalize(float3(lightDir) + float3(viewDir));
    half NdotH = half(saturate(dot(normal, halfVec)));
    half modifier = pow(float(NdotH), float(smoothness)); // Half produces banding, need full precision
    // NOTE: In order to fix internal compiler error on mobile platforms, this needs to be float3
    float3 specularReflection = specular.rgb * modifier;
    return lightColor * specularReflection;
}

half3 LightingPhysicallyBased(BRDFData brdfData, BRDFData brdfDataClearCoat,
    half3 lightColor, half3 lightDirectionWS, float lightAttenuation,
    half3 normalWS, half3 viewDirectionWS,
    half clearCoatMask, bool specularHighlightsOff)
{
    half NdotL = saturate(dot(normalWS, lightDirectionWS));
    half3 radiance = lightColor * (lightAttenuation * NdotL);

    half3 brdf = brdfData.diffuse;
#ifndef _SPECULARHIGHLIGHTS_OFF
    [branch] if (!specularHighlightsOff)
    {
        brdf += brdfData.specular * DirectBRDFSpecular(brdfData, normalWS, lightDirectionWS, viewDirectionWS);

#if defined(_CLEARCOAT) || defined(_CLEARCOATMAP)
        // Clear coat evaluates the specular a second timw and has some common terms with the base specular.
        // We rely on the compiler to merge these and compute them only once.
        half brdfCoat = kDielectricSpec.r * DirectBRDFSpecular(brdfDataClearCoat, normalWS, lightDirectionWS, viewDirectionWS);

            // Mix clear coat and base layer using khronos glTF recommended formula
            // https://github.com/KhronosGroup/glTF/blob/master/extensions/2.0/Khronos/KHR_materials_clearcoat/README.md
            // Use NoV for direct too instead of LoH as an optimization (NoV is light invariant).
            half NoV = saturate(dot(normalWS, viewDirectionWS));
            // Use slightly simpler fresnelTerm (Pow4 vs Pow5) as a small optimization.
            // It is matching fresnel used in the GI/Env, so should produce a consistent clear coat blend (env vs. direct)
            half coatFresnel = kDielectricSpec.x + kDielectricSpec.a * Pow4(1.0 - NoV);

        brdf = brdf * (1.0 - clearCoatMask * coatFresnel) + brdfCoat * clearCoatMask;
#endif // _CLEARCOAT
    }
#endif // _SPECULARHIGHLIGHTS_OFF

    return brdf * radiance;
}

half3 LightingPhysicallyBased(BRDFData brdfData, BRDFData brdfDataClearCoat, Light light, half3 normalWS, half3 viewDirectionWS, half clearCoatMask, bool specularHighlightsOff)
{
    return LightingPhysicallyBased(brdfData, brdfDataClearCoat, light.color, light.direction, light.distanceAttenuation * light.shadowAttenuation, normalWS, viewDirectionWS, clearCoatMask, specularHighlightsOff);
}

// Backwards compatibility
half3 LightingPhysicallyBased(BRDFData brdfData, Light light, half3 normalWS, half3 viewDirectionWS)
{
    #ifdef _SPECULARHIGHLIGHTS_OFF
    bool specularHighlightsOff = true;
#else
    bool specularHighlightsOff = false;
#endif
    const BRDFData noClearCoat = (BRDFData)0;
    return LightingPhysicallyBased(brdfData, noClearCoat, light, normalWS, viewDirectionWS, 0.0, specularHighlightsOff);
}

half3 LightingPhysicallyBased(BRDFData brdfData, half3 lightColor, half3 lightDirectionWS, float lightAttenuation, half3 normalWS, half3 viewDirectionWS)
{
    Light light;
    light.color = lightColor;
    light.direction = lightDirectionWS;
    light.distanceAttenuation = lightAttenuation;
    light.shadowAttenuation   = 1;
    return LightingPhysicallyBased(brdfData, light, normalWS, viewDirectionWS);
}

half3 LightingPhysicallyBased(BRDFData brdfData, Light light, half3 normalWS, half3 viewDirectionWS, bool specularHighlightsOff)
{
    const BRDFData noClearCoat = (BRDFData)0;
    return LightingPhysicallyBased(brdfData, noClearCoat, light, normalWS, viewDirectionWS, 0.0, specularHighlightsOff);
}

half3 LightingPhysicallyBased(BRDFData brdfData, half3 lightColor, half3 lightDirectionWS, float lightAttenuation, half3 normalWS, half3 viewDirectionWS, bool specularHighlightsOff)
{
    Light light;
    light.color = lightColor;
    light.direction = lightDirectionWS;
    light.distanceAttenuation = lightAttenuation;
    light.shadowAttenuation   = 1;
    return LightingPhysicallyBased(brdfData, light, viewDirectionWS, specularHighlightsOff, specularHighlightsOff);
}

half3 VertexLighting(float3 positionWS, half3 normalWS)
{
    half3 vertexLightColor = half3(0.0, 0.0, 0.0);

#ifdef _ADDITIONAL_LIGHTS_VERTEX
    uint lightsCount = GetAdditionalLightsCount();
    uint meshRenderingLayers = GetMeshRenderingLayer();

    LIGHT_LOOP_BEGIN(lightsCount)
        Light light = GetAdditionalLight(lightIndex, positionWS);

#ifdef _LIGHT_LAYERS
    if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
#endif
    {
        half3 lightColor = light.color * light.distanceAttenuation;
        vertexLightColor += LightingLambert(lightColor, light.direction, normalWS);
    }

    LIGHT_LOOP_END
#endif

    return vertexLightColor;
}

struct LightingData
{
    half3 giColor;
    half3 mainLightColor;
    half3 additionalLightsColor;
    half3 vertexLightingColor;
    half3 emissionColor;
};

half3 CalculateLightingColor(LightingData lightingData, half3 albedo)
{
    half3 lightingColor = 0;

    if (IsOnlyAOLightingFeatureEnabled())
    {
        return lightingData.giColor; // Contains white + AO
    }

    if (IsLightingFeatureEnabled(DEBUGLIGHTINGFEATUREFLAGS_GLOBAL_ILLUMINATION))
    {
        lightingColor += lightingData.giColor;
    }

    if (IsLightingFeatureEnabled(DEBUGLIGHTINGFEATUREFLAGS_MAIN_LIGHT))
    {
        lightingColor += lightingData.mainLightColor;
    }

    if (IsLightingFeatureEnabled(DEBUGLIGHTINGFEATUREFLAGS_ADDITIONAL_LIGHTS))
    {
        lightingColor += lightingData.additionalLightsColor;
    }

    if (IsLightingFeatureEnabled(DEBUGLIGHTINGFEATUREFLAGS_VERTEX_LIGHTING))
    {
        lightingColor += lightingData.vertexLightingColor;
    }

    lightingColor *= albedo;

    if (IsLightingFeatureEnabled(DEBUGLIGHTINGFEATUREFLAGS_EMISSION))
    {
        lightingColor += lightingData.emissionColor;
    }

    return lightingColor;
}

half4 CalculateFinalColor(LightingData lightingData, half alpha)
{
    half3 finalColor = CalculateLightingColor(lightingData, 1);

    return half4(finalColor, alpha);
}

half4 CalculateFinalColor(LightingData lightingData, half3 albedo, half alpha, float fogCoord)
{
    #if defined(_FOG_FRAGMENT)
        #if (defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2))
        float viewZ = -fogCoord;
        float nearToFarZ = max(viewZ - _ProjectionParams.y, 0);
        half fogFactor = ComputeFogFactorZ0ToFar(nearToFarZ);
    #else
        half fogFactor = 0;
        #endif
    #else
    half fogFactor = fogCoord;
    #endif
    half3 lightingColor = CalculateLightingColor(lightingData, albedo);
    half3 finalColor = MixFog(lightingColor, fogFactor);

    return half4(finalColor, alpha);
}

LightingData CreateLightingData(InputData inputData, SurfaceData surfaceData)
{
    LightingData lightingData;

    lightingData.giColor = inputData.bakedGI;
    lightingData.emissionColor = surfaceData.emission;
    lightingData.vertexLightingColor = 0;
    lightingData.mainLightColor = 0;
    lightingData.additionalLightsColor = 0;

    return lightingData;
}
/*
half3 CalculateBlinnPhong(Light light, InputData inputData, SurfaceData surfaceData)
{
    half3 attenuatedLightColor = light.color * (light.distanceAttenuation * light.shadowAttenuation);
    half3 lightDiffuseColor = LightingLambert(attenuatedLightColor, light.direction, inputData.normalWS);

    half3 lightSpecularColor = half3(0,0,0);
    #if defined(_SPECGLOSSMAP) || defined(_SPECULAR_COLOR)
    half smoothness = exp2(10 * surfaceData.smoothness + 1);

    lightSpecularColor += LightingSpecular(attenuatedLightColor, light.direction, inputData.normalWS, inputData.viewDirectionWS, half4(surfaceData.specular, 1), smoothness);
    #endif

#if _ALPHAPREMULTIPLY_ON
    return lightDiffuseColor * surfaceData.albedo * surfaceData.alpha + lightSpecularColor;
#else
    return lightDiffuseColor * surfaceData.albedo + lightSpecularColor;
#endif
}*/


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

            
half4 AdditionalLightColor(InputData inputData, SurfaceData surfaceData, float3 positionWS, float3 normalWS)
{
    half4 shadowMask = CalculateShadowMask(inputData);
    AmbientOcclusionFactor aoFactor = CreateAmbientOcclusionFactor(inputData, surfaceData);
    uint pixelLightCount = GetAdditionalLightsCount();


    float3 additionalLightsColor;
    
    float4 diffuse = 1;

    LIGHT_LOOP_BEGIN(pixelLightCount)
        Light light = GetAdditionalLight(lightIndex, positionWS, shadowMask);
        additionalLightsColor += CustomLightingPhysicallyBased(diffuse, light, normalWS);
        //additionalLightsColor += LightingPhysicallyBased(brdfData, brdfDataClearCoat, light,inputData.normalWS, inputData.viewDirectionWS,surfaceData.clearCoatMask, false);
        
    LIGHT_LOOP_END



    return float4(additionalLightsColor,1);
}

////////////////////////////////////////////////////////////////////////////////
/// Phong lighting...
////////////////////////////////////////////////////////////////////////////////
///
/*
half4 UniversalFragmentBlinnPhong(InputData inputData, SurfaceData surfaceData)
{
    #if defined(DEBUG_DISPLAY)
    half4 debugColor;

    if (CanDebugOverrideOutputColor(inputData, surfaceData, debugColor))
    {
        return debugColor;
    }
    #endif

    uint meshRenderingLayers = GetMeshRenderingLayer();
    half4 shadowMask = CalculateShadowMask(inputData);
    AmbientOcclusionFactor aoFactor = CreateAmbientOcclusionFactor(inputData, surfaceData);
    Light mainLight = GetMainLight(inputData, shadowMask, aoFactor);

    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI, aoFactor);

    inputData.bakedGI *= surfaceData.albedo;

    LightingData lightingData = CreateLightingData(inputData, surfaceData);
#ifdef _LIGHT_LAYERS
    if (IsMatchingLightLayer(mainLight.layerMask, meshRenderingLayers))
#endif
    {
        lightingData.mainLightColor += CalculateBlinnPhong(mainLight, inputData, surfaceData);
    }

    #if defined(_ADDITIONAL_LIGHTS)
    uint pixelLightCount = GetAdditionalLightsCount();

    #if USE_FORWARD_PLUS
    [loop] for (uint lightIndex = 0; lightIndex < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS); lightIndex++)
    {
        FORWARD_PLUS_SUBTRACTIVE_LIGHT_CHECK

        Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);
#ifdef _LIGHT_LAYERS
        if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
#endif
        {
            lightingData.additionalLightsColor += CalculateBlinnPhong(light, inputData, surfaceData);
        }
    }
    #endif

    LIGHT_LOOP_BEGIN(pixelLightCount)
        Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);
#ifdef _LIGHT_LAYERS
        if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
#endif
        {
            lightingData.additionalLightsColor += CalculateBlinnPhong(light, inputData, surfaceData);
        }
    LIGHT_LOOP_END
    #endif

    #if defined(_ADDITIONAL_LIGHTS_VERTEX)
    lightingData.vertexLightingColor += inputData.vertexLighting * surfaceData.albedo;
    #endif

    return GetAdditionalLightsCount(); //CalculateFinalColor(lightingData, surfaceData.alpha);
}


// Deprecated: Use the version which takes "SurfaceData" instead of passing all of these arguments...
half4 UniversalFragmentBlinnPhong(InputData inputData, half3 diffuse, half4 specularGloss, half smoothness, half3 emission, half alpha, half3 normalTS)
{
    SurfaceData surfaceData;

    surfaceData.albedo = diffuse;
    surfaceData.alpha = alpha;
    surfaceData.emission = emission;
    surfaceData.metallic = 0;
    surfaceData.occlusion = 1;
    surfaceData.smoothness = smoothness;
    surfaceData.specular = specularGloss.rgb;
    surfaceData.clearCoatMask = 0;
    surfaceData.clearCoatSmoothness = 1;
    surfaceData.normalTS = normalTS;

    return UniversalFragmentBlinnPhong(inputData, surfaceData);
}
            */


#endif


// keep this file in sync with LitGBufferPass.hlsl
            
void InitializeInputData(Varyings input, half3 normalTS, out InputData inputData)
{
    inputData = (InputData)0;

#if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
    inputData.positionWS = input.positionWS;
#endif



    half3 viewDirWS = GetWorldSpaceNormalizeViewDir(input.positionWS);
#if defined(_NORMALMAP) || defined(_DETAIL)
    float sgn = input.tangentWS.w;      // should be either +1 or -1
    float3 bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
    half3x3 tangentToWorld = half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz);

    #if defined(_NORMALMAP)
    inputData.tangentToWorld = tangentToWorld;
    #endif
    inputData.normalWS = TransformTangentToWorld(normalTS, tangentToWorld);
#else
    inputData.normalWS = input.normalWS;
#endif

    inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
    inputData.viewDirectionWS = viewDirWS;

#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    inputData.shadowCoord = input.shadowCoord;
#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
    inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
#else
    inputData.shadowCoord = float4(0, 0, 0, 0);
#endif

    inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);

    #if defined(DEBUG_DISPLAY)
    #if defined(DYNAMICLIGHTMAP_ON)
    inputData.dynamicLightmapUV = input.dynamicLightmapUV;
    #endif
    #if defined(LIGHTMAP_ON)
    inputData.staticLightmapUV = input.staticLightmapUV;
    #else
    inputData.vertexSH = input.vertexSH;
    #endif
    #if defined(USE_APV_PROBE_OCCLUSION)
    inputData.probeOcclusion = input.probeOcclusion;
    #endif
    #endif
}

void InitializeBakedGIData(Varyings input, inout InputData inputData)
{
    #if defined(DYNAMICLIGHTMAP_ON)
    inputData.bakedGI = SAMPLE_GI(input.staticLightmapUV, input.dynamicLightmapUV, input.vertexSH, inputData.normalWS);
    inputData.shadowMask = SAMPLE_SHADOWMASK(input.staticLightmapUV);
    #elif !defined(LIGHTMAP_ON) && (defined(PROBE_VOLUMES_L1) || defined(PROBE_VOLUMES_L2))
    inputData.bakedGI = SAMPLE_GI(input.vertexSH,
        GetAbsolutePositionWS(inputData.positionWS),
        inputData.normalWS,
        inputData.viewDirectionWS,
        input.positionCS.xy,
        input.probeOcclusion,
        inputData.shadowMask);
    #else
    //inputData.bakedGI = SAMPLE_GI(input.staticLightmapUV, input.vertexSH, inputData.normalWS);
    inputData.shadowMask = SAMPLE_SHADOWMASK(input.staticLightmapUV);
    #endif
}

///////////////////////////////////////////////////////////////////////////////
//                  Vertex and Fragment functions                            //
///////////////////////////////////////////////////////////////////////////////

// Used in Standard (Physically Based) shader
Varyings CustomLitPassVertex(Attributes input)
{
    Varyings output = (Varyings)0;

    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    //UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);

    // normalWS and tangentWS already normalize.
    // this is required to avoid skewing the direction during interpolation
    // also required for per-vertex lighting and SH evaluation
    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

    half3 vertexLight = VertexLighting(vertexInput.positionWS, normalInput.normalWS);

    half fogFactor = 0;
    #if !defined(_FOG_FRAGMENT)
        fogFactor = ComputeFogFactor(vertexInput.positionCS.z);
    #endif

    output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);

    // already normalized from normal transform to WS.
    output.normalWS = normalInput.normalWS;
#if defined(REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR) || defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
    real sign = input.tangentOS.w * GetOddNegativeScale();
    half4 tangentWS = half4(normalInput.tangentWS.xyz, sign);
#endif
#if defined(REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR)
    output.tangentWS = tangentWS;
#endif

#if defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
    half3 viewDirWS = GetWorldSpaceNormalizeViewDir(vertexInput.positionWS);
    half3 viewDirTS = GetViewDirectionTangentSpace(tangentWS, output.normalWS, viewDirWS);
    output.viewDirTS = viewDirTS;
#endif

    OUTPUT_LIGHTMAP_UV(input.staticLightmapUV, unity_LightmapST, output.staticLightmapUV);

#if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
    output.positionWS = vertexInput.positionWS;
#endif

#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    output.shadowCoord = GetShadowCoord(vertexInput);
#endif

    output.positionCS = vertexInput.positionCS;

    return output;
}

// Used in Standard (Physically Based) shader
void LitPassFragment(
    Varyings input
    , out half4 outColor : SV_Target0
#ifdef _WRITE_RENDERING_LAYERS
    , out float4 outRenderingLayers : SV_Target1
#endif
)
{
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

#if defined(_PARALLAXMAP)
#if defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
    half3 viewDirTS = input.viewDirTS;
#else
    half3 viewDirWS = GetWorldSpaceNormalizeViewDir(input.positionWS);
    half3 viewDirTS = GetViewDirectionTangentSpace(input.tangentWS, input.normalWS, viewDirWS);
#endif
    ApplyPerPixelDisplacement(viewDirTS, input.uv);
#endif

    SurfaceData surfaceData;
    InitializeStandardLitSurfaceData(input.uv, surfaceData);



    InputData inputData;
    InitializeInputData(input, surfaceData.normalTS, inputData);
    SETUP_DEBUG_TEXTURE_DATA(inputData, UNDO_TRANSFORM_TEX(input.uv, _BaseMap));



    InitializeBakedGIData(input, inputData);

    //half4 color = AdditionalLightColor(inputData, surfaceData, input.positionWS , input.normalWS);
    //color.rgb = MixFog(color.rgb, inputData.fogCoord);
   // color.a = 1; OutputAlpha(color.a, IsSurfaceTypeTransparent(_Surface));

    //outColor = color;


    uint pixelLightCount = GetAdditionalLightsCount();
    float3 additionalLightsColor;

    
    float4 diffuse = 1;
    half4 shadowMask = unity_ProbesOcclusion; 
    LIGHT_LOOP_BEGIN(pixelLightCount)
        Light light = GetAdditionalLight(lightIndex, inputData.positionWS, shadowMask);
        additionalLightsColor += CustomLightingPhysicallyBased(diffuse, light, inputData.normalWS);
        //additionalLightsColor += LightingPhysicallyBased(brdfData, brdfDataClearCoat, light,inputData.normalWS, inputData.viewDirectionWS,surfaceData.clearCoatMask, false);
        
    LIGHT_LOOP_END

    outColor = float4(additionalLightsColor,1);

}

#endif

            ENDHLSL
        }

    }

    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}
