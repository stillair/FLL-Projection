#region usings
using System;
using System.Runtime.InteropServices;
using System.ComponentModel.Composition;
using System.Collections;
using System.Text;

using VVVV.PluginInterfaces.V1;
using VVVV.PluginInterfaces.V2;

#endregion usings

namespace mp.essentials.Nodes.Windows
{
	[PluginInfo(
        Name = "GetWindowText",
        Category = "Windows",
        Author = "microdee"
        )]
	public class WindowsGetWindowTextNode : IPluginEvaluate
	{
		#region fields & pins
		[Input("Handle In", DefaultValue = 0)]
		public ISpread<int> FInput;

		[Output("Title")]
		public ISpread<string> FTitle;
		#endregion fields & pins

		[DllImport("C:\\Windows\\System32\\user32.dll")]
		public static extern int GetWindowText(IntPtr hWnd, StringBuilder text, int count);

		//called when data for any output pin is requested
		public void Evaluate(int SpreadMax)
		{
			FTitle.SliceCount = SpreadMax;
			const int nChars = 256;

			for (int i = 0; i < SpreadMax; i++) {
				StringBuilder Buff = new StringBuilder(nChars);
				if(GetWindowText(new IntPtr(FInput[i]), Buff, nChars) > 0) FTitle[i] = Buff.ToString();
				else FTitle[i] = "?";
			}
		}
	}
}
