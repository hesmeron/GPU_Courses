using UnityEditor;
using UnityEngine;

//[CustomEditor(typeof(MassRenderer))]
[CustomEditor(typeof(MassRenderer)), CanEditMultipleObjects]
public class MassRendererEditor : Editor
{
    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();
        string[] choices;
        int choiceIndex = 0;
        MassRenderer renderer = (MassRenderer)target;
        RenderingResourceContainer container = renderer.RenderingResourceContainer;
        if (container != null && container.Materials.Count > 0)
        {
            EditorGUILayout.LabelField("Material");
            choices = new string[container.Materials.Count];

            for (var index = 0; index < container.Materials.Count; index++)
            {
                Material mat = container.Materials[index];
                choices[index] = mat.name;
            }

            if (container.Materials.Contains(renderer.Material))
            {
                choiceIndex = container.Materials.IndexOf(renderer.Material);
            }
            else
            {
                choiceIndex = 0;
            }

            choiceIndex = EditorGUILayout.Popup(choiceIndex, choices);
            renderer.Material = container.Materials[choiceIndex];
        }
    }
}
