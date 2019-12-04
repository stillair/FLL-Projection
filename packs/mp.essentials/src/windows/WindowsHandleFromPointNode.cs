#region usings
using System;
using System.Runtime.InteropServices;
using System.ComponentModel.Composition;
using System.Collections;
using System.Windows;
using System.Windows.Forms;
using System.Drawing;
using System.Text;

using VVVV.PluginInterfaces.V1;
using VVVV.PluginInterfaces.V2;

using WPoint = System.Drawing.Point;

#endregion usings

namespace mp.essentials.Nodes.Windows
{
	[PluginInfo(
        Name = "HandleFromCursor",
        Category = "Windows",
        Author = "microdee"
        )]
	public class WindowsHandleFromPointNode : IPluginEvaluate
	{		
		[Input("Update", DefaultBoolean = true)]
		public ISpread<bool> FUpdate;
		
		[Output("Handle Out")]
		public ISpread<int> FParent;
		[Output("Cursor Pos")]
		public ISpread<int> FCurPos;
		
		[Output("Title")]
		public ISpread<string> FTitle;
		
		[DllImport("C:\\Windows\\System32\\user32.dll")]
		public static extern bool GetCursorPos(out WPoint lpPoint);
		
		[DllImport("C:\\Windows\\System32\\user32.dll")]
		public static extern IntPtr WindowFromPoint(WPoint lpPoint);
		
		[DllImport("C:\\Windows\\System32\\user32.dll")]
		public static extern IntPtr ChildWindowFromPoint(IntPtr hWndParent, WPoint Point);
		
		[DllImport("C:\\Windows\\System32\\user32.dll")]
		public static extern int GetWindowText(IntPtr hWnd, StringBuilder text, int count);

		//called when data for any output pin is requested
		public void Evaluate(int SpreadMax)
		{
			if(FUpdate[0])
			{
				FParent.SliceCount = 1;
				FTitle.SliceCount = 1;
				FCurPos.SliceCount = 2;
				const int nChars = 256;
				
				WPoint ptCursor = new WPoint();
				GetCursorPos(out ptCursor);
				FCurPos[0] = ptCursor.X;
				FCurPos[1] = ptCursor.Y;
				
				IntPtr Parent = WindowFromPoint(ptCursor);
				IntPtr Child = ChildWindowFromPoint(Parent, ptCursor);
				StringBuilder Buff = new StringBuilder(nChars);
				if(GetWindowText(Parent, Buff, nChars) > 0) FTitle[0] = Buff.ToString();
				else FTitle[0] = "";
				
				FParent[0] = Parent.ToInt32();
			}
		}
	}
	#region PluginInfo
	[PluginInfo(Name = "SetCursorPos", Category = "Windows", Tags = "", AutoEvaluate = true)]
	#endregion PluginInfo
	public class WindowsSetCursorPosNode : IPluginEvaluate
	{		
		[Input("Cursor Pos")]
		public ISpread<int> FCurPos;
		[Input("Set")]
		public ISpread<bool> FSet;
		
		[DllImport("C:\\Windows\\System32\\user32.dll")]
		public static extern bool SetCursorPos(int X, int Y);

		//called when data for any output pin is requested
		public void Evaluate(int SpreadMax)
		{
			if(FSet[0]) SetCursorPos(FCurPos[0],FCurPos[1]);
		}
	}
}