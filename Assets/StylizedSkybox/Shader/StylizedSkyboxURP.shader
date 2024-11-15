//天空盒的原理可能只是包裹着摄像机的一个立方体，且天空盒的位置不会因为摄像机移动而改变
//天空盒不写入深度，所有其他物体都会覆盖天空盒
Shader "Skybox/StylizedSkyboxURP"
{
    Properties
    {
        [Header(Sun)]
        _SunColor("Sun Color", Color) = (1,1,1,1)
        _SunRadius("Sun Radius",  Range(0.01, 2)) = 0.1

        [Header(Moon)]
        _MoonColor("Moon Color", Color) = (1,1,1,1)
        _MoonRadius("Moon Radius",  Range(0.01, 2)) = 0.15
        _MoonOffset("Moon Crescent",  Range(-1, 1)) = -0.1

        [Header(Day)]
        _DayTopColor("Day Sky Color Top", Color) = (0.4,1,1,1)
        _DayBottomColor("Day Sky Color Bottom", Color) = (0,0.8,1,1)

        [Header(Night)]
        _NightTopColor("Night Sky Color Top", Color) = (0,0,0,1)
		_NightBottomColor("Night Sky Color Bottom", Color) = (0,0,0.2,1)

        [Header(Horizon)]
        _OffsetHorizon("Horizon Offset",  Range(-1, 1)) = 0
        _HorizonIntensity("Horizon Intensity",  Range(0, 10)) = 3.3
        _HorizonColorDay("Day Horizon Color", Color) = (0,0.8,1,1)

        [Header(Stars)]
        _Stars("Stars Texture", 2D) = "black" {}

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
                float3 worldPos : TEXCOORD1;
            };

            TEXTURE2D(_Stars);
            SAMPLER(sampler_Stars);
            half4 _SunColor;
            half4 _MoonColor;
            half4 _DayTopColor;
            half4 _DayBottomColor;
            half4 _NightTopColor;
            half4 _NightBottomColor;
            half4 _HorizonColorDay;
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
                OUT.worldPos = TransformObjectToWorld(IN.positionOS.xyz);
                return OUT;
            }
 
            half4 frag(Varyings IN) : SV_Target
            {
                //天空盒的UV坐标的 y 分量表示当前视线在垂直方向的高度。通常在天空盒中，y=1 表示天空顶端，y=0 表示地平线
                //horizon 代表了当前视线距离地平线的相对程度。视线靠近地平线时，horizon 的值会接近于零，而远离地平线时，horizon 的值会变大
                float horizon = abs((IN.uv.y * _HorizonIntensity) - _OffsetHorizon);
                // (伪视差)当观察角度朝上(y 较大)时，skyUV 会相对缩小，而当观察角度靠近地面(y 较小)时，skyUV 会放大。
                //这种拉伸并不是为了真正的视差效果，而是让星星的显示和视角高度产生关联
				float2 skyUV = IN.worldPos.xz / IN.worldPos.y;

                //IN.uv.xyz 天空盒使用的归一化的模型坐标作为UV坐标(天空盒的UV坐标通常会与观察方向相对应), 且因为天空盒是以相机作为中心点的
                //因为这两个向量uv和_MainLightPosition都是单位向量，所以它们的差值会在0(完全对齐)到较小的值(偏离方向)之间
                //距离值越小，说明当前视线越接近太阳方向
                float sun = length(IN.uv.xyz - _MainLightPosition.xyz);
                //取反, 距离太阳越近则越大
                float sunDisc = 1 - saturate(sun / _SunRadius);
                //放大倍数以将近太阳/月亮的颜色一致而不是渐变
                sunDisc = saturate(sunDisc * 10);

                float3 moonPosition = -_MainLightPosition.xyz;
                //通过偏移额外产生一个月亮, 从而制造月牙效果
                float crescentMoon = length(float3(IN.uv.x + _MoonOffset, IN.uv.yz) - moonPosition);
                float crescentMoonDisc = 1 - saturate(crescentMoon / _MoonRadius);
                crescentMoonDisc = saturate(crescentMoonDisc * 10);
                float moon = length(IN.uv.xyz - moonPosition);
                float moonDisc = 1 - saturate(moon / _MoonRadius);
                moonDisc = saturate(moonDisc * 10);
                moonDisc = saturate(moonDisc - crescentMoonDisc);

                float3 sunAndMoon = sunDisc * _SunColor.xyz + moonDisc * _MoonColor.xyz;

				//白天黑夜颜色
				float3 gradientDay = lerp(_DayBottomColor, _DayTopColor, saturate(horizon));
				float3 gradientNight = lerp(_NightBottomColor, _NightTopColor, saturate(horizon));
				float3 skyGradients = lerp(gradientNight, gradientDay, saturate(_MainLightPosition.y));

                //地平线颜色
                float3 horizonGlow = saturate((1 - horizon) * saturate(_MainLightPosition.y)) * _HorizonColorDay;

                //星星
                float3 stars = SAMPLE_TEXTURE2D(_Stars, sampler_Stars, skyUV);
                stars *= 1 - saturate(_MainLightPosition.y);

                float3 finalColor = sunAndMoon + skyGradients + horizonGlow + stars;
                return float4(finalColor, 1);
            }
            ENDHLSL
        }

    }
}
