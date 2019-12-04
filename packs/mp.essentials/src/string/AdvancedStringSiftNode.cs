#region usings
using System;
using System.ComponentModel.Composition;
using md.stdl.String;
using mp.essentials;
using VVVV.PluginInterfaces.V1;
using VVVV.PluginInterfaces.V2;
using VVVV.Utils.VColor;
using VVVV.Utils.VMath;

using VVVV.Core.Logging;
#endregion usings

namespace mp.essentials.Nodes.Strings
{
	[PluginInfo(
        Name = "Sift",
        Category = "String",
        Version = "Advanced",
        Author = "microdee"
        )]
	public class AdvancedStringSiftNode : IPluginEvaluate
	{
		#region fields & pins
		[Input("Input")]
		public ISpread<ISpread<string>> FInput;
		[Input("Filter")]
		public ISpread<ISpread<string>> FFilter;
		[Input("Contains")]
		public ISpread<bool> FContains;
	    [Input("Comparison Mode", DefaultEnumEntry = "InvariantCulture")]
	    public ISpread<StringComparison> FCompMode;
	    [Input("Ignore Diacritics")]
	    public ISpread<bool> FIgnoreDiac;

        [Output("Input Index")]
		public ISpread<ISpread<int>> FInIndex;
		[Output("Input Absolute Index")]
		public ISpread<ISpread<int>> FInAbsIndex;
		[Output("Filter Index")]
		public ISpread<ISpread<int>> FFilterIndex;

		[Import()]
		public ILogger FLogger;
		#endregion fields & pins

		//called when data for any output pin is requested
		public void Evaluate(int SpreadMax)
		{
			FInIndex.SliceCount = FInput.SliceCount;
			FInAbsIndex.SliceCount = FInput.SliceCount;
			FFilterIndex.SliceCount = FInput.SliceCount;
			int ii = 0;
			for (int i = 0; i < FInput.SliceCount; i++)
			{
				FInIndex[i].SliceCount = 0;
				FInAbsIndex[i].SliceCount = 0;
				FFilterIndex[i].SliceCount = 0;
				for(int j=0; j<FInput[i].SliceCount; j++)
				{
					for(int k=0; k<FFilter[i].SliceCount; k++)
					{
						bool valid = false;
					    if (FIgnoreDiac[i]) valid = FContains[0]
					            ? FInput[i][j].RemoveDiacritics().Contains(FFilter[i][k].RemoveDiacritics(), FCompMode[i])
					            : FInput[i][j].RemoveDiacritics().Equals(FFilter[i][k].RemoveDiacritics(), FCompMode[i]);
					    else valid = FContains[0]
					            ? FInput[i][j].Contains(FFilter[i][k], FCompMode[i])
					            : FInput[i][j].Equals(FFilter[i][k], FCompMode[i]);


                        if (valid)
						{
							FInIndex[i].Add(j);
							FInAbsIndex[i].Add(ii);
							FFilterIndex[i].Add(k);
						}
					}
					ii++;
				}
			}

			//FLogger.Log(LogType.Debug, "Logging to Renderer (TTY)");
		}
	}
}
