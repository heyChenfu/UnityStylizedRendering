void DistortUV_float(float2 UV, float Amount, out float2 Out)
{
    float time = _Time.y;
    
    UV.x += Amount * 0.1 * sin(UV.y * 5.0 + time * 0.5);
    UV.y += Amount * 0.1 * sin(UV.x * 5.0 + time * 0.5);

    Out = UV;
}