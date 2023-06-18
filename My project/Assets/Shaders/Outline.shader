Shader "Outline/Outline"
{
    Properties
    {
        _OutlineColor("Outline Color",Color) = (0,0,0,1)
        _Outline ("Outline",Range(0,1)) = 0.1
        _Fade("Fade" , Range(0, 1.0)) = 1
        [HideInInspector] _SrcBlend("__src", Float) = 1.0
        [HideInInspector] _DstBlend("__dst", Float) = 0.0
    }
    SubShader
    {
        Tags {  "RenderPipeline" = "UniversalRenderPipeline"  "IgnoreProjector" = "True" "RenderType" = "Opaque"}
        //LOD 100
        Cull Front
        ZTest LEqual

        Pass
        {
            Tags { "LightMode" = "UniversalForward" }
            Blend [_SrcBlend][_DstBlend]
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct appdata
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
				float4 tangent : TANGENT;
                float4 color : COLOR;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float alpha: TEXCOORD0;
            };
            
            CBUFFER_START(UnityPerMaterial)
            half4 _OutlineColor;
            half _Outline;
            half _Fade;
            CBUFFER_END

            Varyings vert (appdata v)
            {
                Varyings o;
                float2 rg=v.color.rg*2-1;
                float b=sqrt(1-dot(rg,rg));
                float3 vertNormal =float3(rg,b);
                float3 normalos= normalize(v.normalOS);
                float3 tangentos= normalize(v.tangent.xyz);
                float3 bitangent = cross(normalos,tangentos.xyz) * v.tangent.w ;
                //TBN逆矩阵（因为正交，逆矩阵可以反转）
				float3x3 TtoO = float3x3(tangentos.x, bitangent.x, normalos.x,
										tangentos.y, bitangent.y, normalos.y,
										tangentos.z, bitangent.z, normalos.z);
				//vertNormal = mul(TtoO, vertNormal)*v.color.b;	
				vertNormal = mul(TtoO, vertNormal);	
                
                o.positionCS =TransformObjectToHClip(v.positionOS.xyz);
                 //法线转到屏幕坐标
                float3 vNormal = normalize(mul((float3x3)UNITY_MATRIX_IT_MV, vertNormal));
                //再转到裁切坐标
                float2 projPos = normalize(mul((float2x2)UNITY_MATRIX_P,vNormal.xy));
                
                o.positionCS.xy += projPos * o.positionCS.w  * _Outline * 0.1;
                o.alpha=v.color.a;
                return o;
            }

            float4 frag (Varyings i) : SV_Target
            {
                
                return float4(_OutlineColor.xyz,i.alpha * _Fade);
            }
            ENDHLSL
        }
    }
}