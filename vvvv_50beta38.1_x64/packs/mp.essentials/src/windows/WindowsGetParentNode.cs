#region usings
using System;
using System.Runtime.InteropServices;
using System.ComponentModel.Composition;
using System.Collections;

using VVVV.PluginInterfaces.V1;
using VVVV.PluginInterfaces.V2;

#endregion usings

namespace mp.essentials.Nodes.Windows
{
	[PluginInfo(
        Name = "GetParent",
        Category = "Windows",
        Author = "microdee"
        )]
	public class WindowsGetParentNode : IPluginEvaluate
	{
		#region fields & pins
		[Input("Handle In", DefaultValue = 0)]
		public ISpread<int> FInput;

		[Output("Handle Out")]
		public ISpread<int> FOutput;
		#endregion fields & pins
		
		[DllImport("C:\\Windows\\System32\\user32.dll")]
		public static extern IntPtr GetParent(IntPtr hwnd);

		//called when data for any output pin is requested
		public void Evaluate(int SpreadMax)
		{
			FOutput.SliceCount = SpreadMax;

			for (int i = 0; i < SpreadMax; i++)
				FOutput[i] = GetParent(new IntPtr(FInput[i])).ToInt32();
		}
	}
}
