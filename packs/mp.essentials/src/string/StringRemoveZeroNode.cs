#region usings
using System;
using System.ComponentModel.Composition;

using VVVV.PluginInterfaces.V1;
using VVVV.PluginInterfaces.V2;
using VVVV.Utils.VColor;
using VVVV.Utils.VMath;

using VVVV.Core.Logging;
#endregion usings

namespace mp.essentials.Nodes.Strings
{
	[PluginInfo(
        Name = "RemoveZero",
        Category = "String",
        Author = "microdee"
        )]
	public class StringRemoveZeroNode : IPluginEvaluate
	{
		#region fields & pins
		[Input("Input", DefaultString = "1.0000000")]
		public ISpread<string> FInput;

		[Output("Output")]
		public ISpread<string> FOutput;

		[Import()]
		public ILogger FLogger;
		#endregion fields & pins

		//called when data for any output pin is requested
		public void Evaluate(int SpreadMax)
		{
			FOutput.SliceCount = SpreadMax;

			for(int i = 0; i < SpreadMax; i++)
			{
				if(FInput[i].Contains(".")) FOutput[i] = FInput[i].TrimEnd('0').TrimEnd('.');
				else FOutput[i] = FInput[i];
			}
			//FLogger.Log(LogType.Debug, "Logging to Renderer (TTY)");
		}
	}
}
