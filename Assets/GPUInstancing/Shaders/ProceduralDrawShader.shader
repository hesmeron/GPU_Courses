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
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #pragma multi_compile _FORWARD_PLUS

            #include "HLSLSupport.cginc"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                //Retreive the normal on Object Space
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 positionCS : SV_POSITION;
                //World space position
                float3 positionWS : TEXCOORD1;
                //World space normal
                float3 normalWS : TEXCOORD2;
                //Coordinates on the shadowmap
                float4 shadowCoord  : TEXCOORD3;
            };

            StructuredBuffer<float4x4> _TransformationMatrices;
            
            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v, uint instanceId: SV_InstanceID)
            {
                v2f o;
                //Calculate world space position by mutliplying object space position
                //through ObjectToWorld matrix retreived from an array
                //When not using ProceduralDrawing we would multiply by UNITY_MATRIX_M
                float4 positionWS = mul(_TransformationMatrices[instanceId], float4(v.vertex.xyz, 1));
                //Calculate world space normal by mutliplying object space normal
                //through WorldToObject matrix by inversing the matrix retreived from an array
                //When not using ProceduralDrawing we would multiply by UNITY_MATRIX_I_M
                float3 normalWS = mul(v.normalOS, (float3x3)Inverse(_TransformationMatrices[instanceId]));
                o.positionCS = mul(UNITY_MATRIX_VP, positionWS);
                o.positionWS = positionWS;
                o.normalWS = normalWS;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                half4 shadowMask = unity_ProbesOcclusion; 
                Light mainLight = GetMainLight(i.shadowCoord, i.positionWS, shadowMask);
                
                half NdotL = saturate(dot(i.normalWS, mainLight.direction));
                float3 attenuation = mainLight.distanceAttenuation * mainLight.shadowAttenuation;
                half3 radiance = mainLight.color * (attenuation * NdotL);
                
                fixed3 col = tex2D(_MainTex, i.uv).rgb * radiance;
                return  float4(col, 1);
            }
            ENDHLSL
        }
    }
}
