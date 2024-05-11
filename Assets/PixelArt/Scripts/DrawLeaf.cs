using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class DrawLeaf : MonoBehaviour
{
    public struct LeafData
    {
        public Vector3 Pos;
        public Vector3 Normal;
        public Quaternion Rotation;
        public float Size;
        public int MatIndex;
        public float SpeedOffset;
        public float LightOffset;
    }

    public Mesh ShapeMesh; //形状的Mesh
    public Mesh LeafMesh; //树叶的Mesh
    public List<Material> Mats = new List<Material>();

    [Range(0, 1f), Tooltip("树叶密度")]
    public float LeafDensity = 1; //树叶密度
    [Range(0.1f, 2f), Tooltip("树叶尺寸")]
    public float LeafSize = 1; //树叶尺寸
    [Range(0, 1f), Tooltip("树叶偏移")]
    public float LeafOffset = 0; //树叶偏移
    [Range(0, 1f), Tooltip("光照偏移")]
    public float LightOffset = 0;
    [Range(0, 1f), Tooltip("光照偏移几率")]
    public float LightOffsetDensity = 0;

    private List<LeafData> _leafDatas = new List<LeafData>();

    void Awake()
    {
        InitLeaf();
    }

    void Update()
    {
        DrawLeafs();

    }

    private void InitLeaf()
    {
        for (int i = 0; i < ShapeMesh.vertices.Length; ++i)
        {
            float random = Random.Range(0.0f, 1.0f);
            if (LeafDensity < random)
                continue;
            var pos = transform.TransformPoint(ShapeMesh.vertices[i]);
            var normal = transform.TransformPoint(ShapeMesh.normals[i]) - transform.position;
            Quaternion quaternion = Quaternion.Euler(0, 0, Random.Range(0, 360));
            float size = Random.Range(0.5f, 1f);
            int matIndex = Random.Range(0, Mats.Count);
            float speedOffset = Random.Range(0, 4f);
            float lightOffset = Random.Range(0, 1f);
            if (LightOffsetDensity < lightOffset)
                lightOffset = 0;
            LeafData data = new LeafData() { Pos = pos, Size = size, Normal = normal, Rotation = quaternion,
                MatIndex = matIndex, SpeedOffset = speedOffset, LightOffset = lightOffset };
            _leafDatas.Add(data);
        }

    }

    private void DrawLeafs()
    {
        List<List<Matrix4x4>> _matrix4X4s = new List<List<Matrix4x4>>();
        List<List<Vector4>> _normals = new List<List<Vector4>>();
        List<List<float>> _speedShift = new List<List<float>>();
        List<List<float>> _lightOffset = new List<List<float>>();

        for (int i = 0; i < Mats.Count; ++i)
        {
            _matrix4X4s.Add(new List<Matrix4x4>());
            _normals.Add(new List<Vector4>());
            _speedShift.Add(new List<float>());
            _lightOffset.Add(new List<float>());
        }
        foreach (LeafData data in _leafDatas)
        {
            int index = data.MatIndex;
            Vector3 pos = data.Pos + data.Normal * LeafOffset;
            Vector3 scale = Vector3.one * data.Size * LeafSize;
            Matrix4x4 matrix4X4 = Matrix4x4.TRS(pos, data.Rotation, scale);
            _matrix4X4s[index].Add(matrix4X4);
            _normals[index].Add(data.Normal);
            _speedShift[index].Add(data.SpeedOffset);
            _lightOffset[index].Add(data.LightOffset * LightOffset);
            //DrawMeshInstanced单次数目限制
            if (_matrix4X4s[index].Count >= 1023)
            {
                MaterialPropertyBlock block = new MaterialPropertyBlock();
                block.SetVectorArray("_Normal", _normals[index].ToArray());
                block.SetFloatArray("_SpeedOffset", _speedShift[index].ToArray());
                block.SetFloatArray("_LightOffset", _lightOffset[index].ToArray());
                Graphics.DrawMeshInstanced(LeafMesh, 0, Mats[index], _matrix4X4s[index].ToArray(), _matrix4X4s[index].Count,
                    block, UnityEngine.Rendering.ShadowCastingMode.Off, false);
                _matrix4X4s[index].Clear();
                _normals[index].Clear();
                _speedShift[index].Clear();
                _lightOffset[index].Clear();
            }
        }
        for (int i = 0; i < Mats.Count; ++i)
        {
            int index = i;
            if (_matrix4X4s[index].Count == 0)
                continue;
            MaterialPropertyBlock block = new MaterialPropertyBlock();
            block.SetVectorArray("_Normal", _normals[index].ToArray());
            block.SetFloatArray("_SpeedOffset", _speedShift[index].ToArray());
            block.SetFloatArray("_LightOffset", _lightOffset[index].ToArray());
            Graphics.DrawMeshInstanced(LeafMesh, 0, Mats[index], _matrix4X4s[index].ToArray(), _matrix4X4s[index].Count,
                block, UnityEngine.Rendering.ShadowCastingMode.Off, false);
            _matrix4X4s[index].Clear();
            _normals[index].Clear();
            _speedShift[index].Clear();
            _lightOffset[index].Clear();
        }

    }

}
