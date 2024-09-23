using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class WaterWaveMono : MonoBehaviour
{

    [Header("Waves")]
    [SerializeField] 
    float steepness = 0.3f; //陡度
    [SerializeField] 
    float wavelength = 0.2f; //波长
    [SerializeField, Range(0, 1)] 
    float speed = 0.1f;
    [SerializeField] 
    float[] directions = new float[4];

    [Header("Buoyancy Objects")]
    [SerializeField]
    public float BuoyancyStrength = 1f; //向上浮动强度
    [SerializeField]
    public Rigidbody[] FloatingObjects; //水面浮动物

    private Vector3[] _FloatingObjectsProjections;

    // Start is called before the first frame update
    void Start()
    {
        MeshRenderer meshRenderer = GetComponent<MeshRenderer>();
        if (meshRenderer != null)
        {
            Material material = meshRenderer.material;
            material.SetFloat("_WaveSteepness", steepness);
            material.SetFloat("_WaveLength", wavelength);
            material.SetFloat("_WaveSpeed", speed);
            Vector4 waveDirections = new Vector4(directions[0], directions[1], directions[2], directions[3]);
            material.SetVector("_WaveDirections", waveDirections);
        }

        _FloatingObjectsProjections = new Vector3[FloatingObjects.Length];
        for (int i = 0; i < _FloatingObjectsProjections.Length; ++i)
        {
            FloatingObjects[i].useGravity = false;
            _FloatingObjectsProjections[i] = FloatingObjects[i].position;
        }
    }

    // Update is called once per frame
    void FixedUpdate()
    {
        for (int i = 0; i < _FloatingObjectsProjections.Length; ++i)
        {
            var objectPosition = FloatingObjects[i].position;
            _FloatingObjectsProjections[i] = objectPosition;
            _FloatingObjectsProjections[i].y = GerstnerWaveDisplacement.GetWaveDisplacement(
                objectPosition, steepness, wavelength, speed, directions).y;

            FloatingObjects[i].AddForceAtPosition(Physics.gravity, objectPosition, ForceMode.Force);
            var waveHeight = _FloatingObjectsProjections[i].y;
            var positionY = objectPosition.y;
            if (positionY < waveHeight)
            {
                // The object is underwater, apply buoyancy
                var submersion = Mathf.Clamp01(waveHeight - positionY);
                var buoyancy = Mathf.Abs(Physics.gravity.y) * submersion * BuoyancyStrength;
                // buoyancy
                FloatingObjects[i].AddForceAtPosition(Vector3.up * buoyancy, objectPosition, ForceMode.Acceleration);
            }
            // drag阻力, 使物体的速度与速度成正比, 用它来抑制物体在水中的运动, 逐渐降低速度
            FloatingObjects[i].AddForce(-FloatingObjects[i].velocity * Time.fixedDeltaTime, ForceMode.VelocityChange);
            // torque旋转阻力, 就像线性阻力会减慢物体的速度一样，扭矩会减慢物体的角速度
            FloatingObjects[i].AddTorque(-FloatingObjects[i].angularVelocity * Time.fixedDeltaTime, ForceMode.Impulse);

        }

    }

}
