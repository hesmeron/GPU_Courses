using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;

//This class has to inherit from ContexItem class
public class CullingFrameData : ContextItem
{
    //We have a variable that holds a reference to the buffer with culled matrices
    public BufferHandle CulledMatricesBuffer;
    public BufferHandle ArgsBuffer;
    
    public override void Reset()
    {
        //We reset this itewm by setting CulledMatricesBuffer to null
        CulledMatricesBuffer = BufferHandle.nullHandle;
        ArgsBuffer = BufferHandle.nullHandle;
    }
}