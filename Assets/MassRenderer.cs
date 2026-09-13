using System;
using UnityEngine;

public class MassRenderer : MonoBehaviour
{
    [SerializeField] 
    private Bounds _bounds;

    [SerializeField] 
    private float _spacing;

    [SerializeField] 
    private int _instanceCount;

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
