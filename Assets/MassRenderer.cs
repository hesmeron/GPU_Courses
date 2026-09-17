using System;
using Unity.Collections;
using UnityEngine;

[ExecuteAlways]
public class MassRenderer : MonoBehaviour
{
    [SerializeField] 
    private Bounds _bounds;

    [SerializeField] 
    private float _spacing;

    [SerializeField] 
    private int _instanceCount;
    
    private Matrix4x4[] _cachedMatrices;
    
    public int InstanceCount => _instanceCount;
    //We use native matrices to cut down on the copy time to buffers
    NativeArray<Matrix4x4> _nativeMatrices;
    public Matrix4x4[] CachedMatrices => _cachedMatrices;
    public NativeArray<Matrix4x4> Matrices => _nativeMatrices;

    private void OnDrawGizmos()
    {
        Gizmos.matrix = transform.localToWorldMatrix;
        Gizmos.color = new Color(0,1,0,0.3f);
        Gizmos.DrawCube(_bounds.center, _bounds.size);
        Gizmos.color = Color.green;
        Gizmos.DrawWireCube(_bounds.center, _bounds.size);
        
        Gizmos.color = Color.red;

        Vector3 start = _bounds.min;

        for (int i = 0; i < _instanceCount; i++)
        {
            Vector3 pos = GetTargetPositionFromId(i);
            Gizmos.DrawSphere(pos, _spacing/2f);
        }
    }

    private void OnEnable()
    {
        //_cachedMatrices = GenerateMatrices();
        _nativeMatrices = GenerateNativeMatrixArray();
        
        InstancedDrawFeature.SubscribeToRendering(this);
    }
    private void OnDisable()
    {
        _nativeMatrices.Dispose();
        InstancedDrawFeature.UnsubscribeToRendering(this);
    }

    private void Awake()
    {

    }

    public Matrix4x4[] GetTrsMatrices()
    {
        if (_cachedMatrices != null)
        {
            return _cachedMatrices;
        }
        else
        {
            Matrix4x4[] matrices = new Matrix4x4[_instanceCount];
            for (int i = 0; i < _instanceCount; i++)
            {
                matrices[i] = Matrix4x4.TRS(GetTargetPositionFromId(i), Quaternion.identity, Vector3.one) * transform.localToWorldMatrix;
            }

            return matrices;
        }
    }
    
    private Matrix4x4[] GenerateMatrices()
    {
        Matrix4x4[] matrices = new Matrix4x4[_instanceCount];
        for (int i = 0; i < _instanceCount; i++)
        {
            matrices[i] = Matrix4x4.TRS(GetTargetPositionFromId(i), Quaternion.identity, Vector3.one) * transform.localToWorldMatrix;
        }

        return matrices;
        
    }    
    private NativeArray<Matrix4x4> GenerateNativeMatrixArray()
    {
        NativeArray<Matrix4x4> matrices = new NativeArray<Matrix4x4>(_instanceCount, Allocator.Persistent);
        for (int i = 0; i < _instanceCount; i++)
        {
            matrices[i] = Matrix4x4.TRS(GetTargetPositionFromId(i), Quaternion.identity, Vector3.one) * transform.localToWorldMatrix;
        }

        return matrices;
        
    }
    
    private Vector3 GetTargetPositionFromId(int id)
    {
        Vector3 start = _bounds.min;
        int numberOfColumnsPerRow =  Mathf.FloorToInt(_bounds.size.x / _spacing);
        int x  = id%numberOfColumnsPerRow;
        int y = (id -x)/numberOfColumnsPerRow;
        Vector3 offset = new Vector3(x, 0, y) * _spacing;
        Vector3 pos = start + offset;
        return pos;
    }
}
