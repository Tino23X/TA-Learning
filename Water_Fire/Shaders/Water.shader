﻿Shader "Custom/Water" {
    Properties {
        _MainTex ("RGB：颜色 A：透贴", 2d) = "gray"{}
        _Opacity ("透明度", range(0, 1)) = 0.5
        _WarpTex ("扭曲图", 2d) = "gray"{}
        _WarpInt ("扭曲强度", range(0, 1)) = 0.1
        _NoiseInt ("噪声强度", range(0, 5)) = 1
        _FlowSpeed ("流动速度", range(-10, 10)) = 5
    }
    SubShader {
        Tags {
            "Queue"="Transparent"               // 调整渲染顺序
            "RenderType"="Transparent"          // 对应改为Cutout
            "ForceNoShadowCasting"="True"       // 关闭阴影投射
            "IgnoreProjector"="True"            // 不响应投射器
        }
        Pass {
            Name "FORWARD"
            Tags {
                "LightMode"="ForwardBase"
            }
            Blend One OneMinusSrcAlpha          // 修改混合方式One/SrcAlpha OneMinusSrcAlpha
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #pragma multi_compile_fwdbase_fullshadows
            #pragma target 3.0
            // 输入参数
            uniform sampler2D _MainTex;
            uniform half _Opacity;
            uniform sampler2D _WarpTex;    uniform float4 _WarpTex_ST;
            uniform half _WarpInt;
            uniform half _NoiseInt;
            uniform half _FlowSpeed;
            // 输入结构
            struct VertexInput {
                float4 vertex : POSITION;       // 顶点位置 总是必要
                float2 uv : TEXCOORD0;          // UV信息 采样贴图用
            };
            // 输出结构
            struct VertexOutput {
                float4 pos : SV_POSITION;       // 顶点位置 总是必要
                float2 uv0 : TEXCOORD0;         // UV 采样MainTex用
                float2 uv1 : TEXCOORD1;         // UV 采样NoiseTex用
            };
            // 输入结构>>>顶点Shader>>>输出结构
            VertexOutput vert (VertexInput v) {
                VertexOutput o;
                o.pos = UnityObjectToClipPos( v.vertex);    // 顶点位置 OS>CS
                o.uv0 = v.uv;
                o.uv0.y = o.uv0.y + frac(_Time.x/2.0*_FlowSpeed);
                o.uv1 = TRANSFORM_TEX(v.uv, _WarpTex);
                o.uv1.y = 1.0-(o.uv1.y + frac(_Time.x * _FlowSpeed));
                return o;
            }
            // 输出结构>>>像素
            half4 frag(VertexOutput i) : COLOR {
                half3 var_WarpTex = tex2D(_WarpTex, i.uv1);
                half2 uvBias = (var_WarpTex.rg - 0.5) * _WarpInt;
                half2 uv0 = i.uv0 + uvBias;

                half4 var_MainTex = tex2D(_MainTex, uv0);
                
                half3 finalRGB = var_MainTex.rgb;
                half noise = lerp(1.0, var_WarpTex.b * 2.0, _NoiseInt);
                noise = max(0.0, noise);
                half opacity = var_MainTex.a * _Opacity * noise;

                return half4(finalRGB * opacity, opacity);                // 返回值
            }
            ENDCG
        }
    }
}