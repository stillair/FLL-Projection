#region usings
using System;
using System.ComponentModel.Composition;

using VVVV.PluginInterfaces.V1;
using VVVV.PluginInterfaces.V2;
using VVVV.Utils.VColor;
using VVVV.Utils.VMath;

using VVVV.Core.Logging;
#endregion usings

namespace mp.essentials.Nodes.Values
{
	#region PluginInfo
	[PluginInfo(Name = "StepperSelect", Category = "Value", Help = "Basic template with one value in/out", Tags = "")]
	#endregion PluginInfo
	public class ValueStepperSelect : IPluginEvaluate
	{
		#region fields & pins
		[Input("Select", DefaultValue = 1.0)]
		ISpread<double> FSelect;
		[Input("Input", DefaultValue = 1.0)]
		ISpread<double> FInput;
		[Input("Default", DefaultValue = 1.0)]
		ISpread<double> FDefault;

		[Output("Output")]
		ISpread<double> FOutput;

		[Import()]
		ILogger FLogger;
		#endregion fields & pins

		//called when data for any output pin is requested
		public void Evaluate(int SpreadMax)
		{
			FOutput.SliceCount = FSelect.SliceCount;
			int j = 0;
			
			for (int i=0; i<FSelect.SliceCount; i++)
			{
				if(FSelect[i]>0)
				{
					FOutput[i] = FInput[j];
					j+=1;
				}
				else FOutput[i] = FDefault[i]; 
			}
			

			//FLogger.Log(LogType.Debug, "hi tty!");
		}
	}
}
