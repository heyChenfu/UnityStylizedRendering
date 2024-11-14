//天空盒的原理可能只是包裹着摄像机的一个立方体，且天空盒的位置不会因为摄像机移动而改变
//天空盒不写入深度，所有其他物体都会覆盖天空盒
Shader "Skybox/StylizedSkyboxURP"
{
    Properties
    {
        [Header(Sun)]
        _SunColor("Sun Color", Color) = (1,1,1,1)
        _SunRadius("Sun Radius",  Range(0, 2)) = 0.1

        [Header(Moon)]
        _MoonColor("Moon Color", Color) = (1,1,1,1)
        _MoonRadius("Moon Radius",  Range(0, 2)) = 0.15
        _MoonOffset("Moon Crescent",  Range(-1, 1)) = -0.1

        [Header(Day)]
        _DayTopColor("Day Sky Color Top", Color) = (0.4,1,1,1)
        _DayBottomColor("Day Sky Color Bottom", Color) = (0,0.8,1,1)

        [Header(Night)]
        _NightTopColor("Night Sky Color Top", Color) = (0,0,0,1)
		_NightBottomColor("Night Sky Color Bottom", Color) = (0,0,0.2,1)

        _OffsetHorizon("Horizon Offset",  Range(-1, 1)) = 0
        _HorizonIntensity("Horizon Intensity",  Range(0, 10)) = 3.3

    }
 
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }
 
        Pass
        {
            Name "ForwardUnlit"
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
 
            // Core.hlsl 文件包含常用的 HLSL 宏和函数的定义，还包含对其他 HLSL 文件（例如Common.hlsl、SpaceTransforms.hlsl 等）的 #include 引用。
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
 
            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 uv : TEXCOORD0;
                half3 normal : NORMAL;
            };
 
            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float3 uv : TEXCOORD0;
                half3 normal : NORMAL;
            };

            half4 _SunColor;
            half4 _MoonColor;
            half4 _DayTopColor;
            half4 _DayBottomColor;
            half4 _NightTopColor;
            half4 _NightBottomColor;
            float _SunRadius;
            float _MoonRadius;
            float _MoonOffset;
            float _OffsetHorizon;
            float _HorizonIntensity;
 
            // 顶点着色器定义具有在 Varyings 结构中定义的属性。vert 函数的类型必须与它返回的类型（结构）匹配。
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                // TransformObjectToHClip 函数将顶点位置从对象空间变换到齐次裁剪空间。
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = IN.uv;
                OUT.normal = TransformObjectToWorldNormal(IN.normal);
                return OUT;
            }
 
            half4 frag(Varyings IN) : SV_Target
            {
                float horizon = abs((IN.uv.y * _HorizonIntensity) - _OffsetHorizon);

                //IN.uv.xyz 天空盒使用的归一化的模型坐标作为UV坐标(也可以理解为天空盒改点反射方向), 且因为天空盒是以相机作为中心点的
                //计算天空盒当前片元离主光源距离
                float sun = length(IN.uv.xyz - _MainLightPosition.xyz);
                //取反, 距离太阳越近则越大
                float sunDisc = 1 - saturate(sun / _SunRadius);
                //放大倍数以将近太阳/月亮的颜色都一致而不是渐变
                sunDisc = saturate(sunDisc * 50);

                float3 moonPosition = -_MainLightPosition.xyz;
                //通过偏移额外产生一个月亮, 从而制造月牙效果
                float crescentMoon = length(float3(IN.uv.x + _MoonOffset, IN.uv.yz) - moonPosition);
                float crescentMoonDisc = 1 - saturate(crescentMoon / _MoonRadius);
                crescentMoonDisc = saturate(crescentMoonDisc * 50);
                float moon = length(IN.uv.xyz - moonPosition);
                float moonDisc = 1 - saturate(moon / _MoonRadius);
                moonDisc = saturate(moonDisc * 50);
                moonDisc = saturate(moonDisc - crescentMoonDisc);

                float3 sunAndMoon = sunDisc * _SunColor.xyz + moonDisc * _MoonColor.xyz;

				// gradient day sky
				float3 gradientDay = lerp(_DayBottomColor, _DayTopColor, saturate(horizon));
				// gradient night sky
				float3 gradientNight = lerp(_NightBottomColor, _NightTopColor, saturate(horizon));
				float3 skyGradients = lerp(gradientNight, gradientDay, saturate(_MainLightPosition.y));

                float3 finalColor = sunAndMoon + skyGradients;
                return float4(finalColor, 1);
            }
            ENDHLSL
        }

    }
}
