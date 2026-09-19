using System.Collections.Generic;
using UnityEngine;

public class RenderingResourceContainer : MonoBehaviour
{
    [SerializeField]
    private List<Material> _materials;

    public List<Material> Materials => _materials;
}
