//��պе�ԭ�����ֻ�ǰ������������һ�������壬����պе�λ�ò�����Ϊ������ƶ����ı�
//��պв�д����ȣ������������嶼�Ḳ����պ�
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
 
            // Core.hlsl �ļ��������õ� HLSL ��ͺ����Ķ��壬������������ HLSL �ļ�������Common.hlsl��SpaceTransforms.hlsl �ȣ��� #include ���á�
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
 
            // ������ɫ����������� Varyings �ṹ�ж�������ԡ�vert ���������ͱ����������ص����ͣ��ṹ��ƥ�䡣
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                // TransformObjectToHClip ����������λ�ôӶ���ռ�任����βü��ռ䡣
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = IN.uv;
                OUT.normal = TransformObjectToWorldNormal(IN.normal);
                return OUT;
            }
 
            half4 frag(Varyings IN) : SV_Target
            {
                float horizon = abs((IN.uv.y * _HorizonIntensity) - _OffsetHorizon);

                //IN.uv.xyz ��պ�ʹ�õĹ�һ����ģ��������ΪUV����(Ҳ�������Ϊ��պиĵ㷴�䷽��), ����Ϊ��պ����������Ϊ���ĵ��
                //������պе�ǰƬԪ������Դ����
                float sun = length(IN.uv.xyz - _MainLightPosition.xyz);
                //ȡ��, ����̫��Խ����Խ��
                float sunDisc = 1 - saturate(sun / _SunRadius);
                //�Ŵ����Խ���̫��/��������ɫ��һ�¶����ǽ���
                sunDisc = saturate(sunDisc * 50);

                float3 moonPosition = -_MainLightPosition.xyz;
                //ͨ��ƫ�ƶ������һ������, �Ӷ���������Ч��
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
