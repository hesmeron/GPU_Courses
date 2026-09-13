using UnityEngine;

public class Comapriosn : MonoBehaviour
{
    [SerializeField] 
    private GameObject prefab;
    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start()
    {
        int width = 100;
        int height = 100;
        

        Matrix4x4[] matrices = new Matrix4x4[width*height];

        for (int x = 0; x < width; x++)
        {
            for (int z = 0; z < height; z++)
            {
                //We simply fill out this array with evenly spaced soldiers
                Vector3 pos = new Vector3(x * 1.2f, 0, z * 1.5f);
                Instantiate(prefab, pos, Quaternion.identity);
            }
        }
    }
}
