import net.onepixelout.audio.*;
import mx.utils.Delegate;

class net.onepixelout.audio.MultiPathParser
{				
	private var _segments:Array;
	private var _decisionPoints:Array;
	
	private var _populated:Boolean = false;
	
	private var _filename:String;
	
	public function MultiPathParser (filename:String)
	{
		_filename = filename;
		_segments = new Array();
		_decisionPoints = new Array();
	}
	
	public function run (doneCallback:Function):Void
	{
		if (!_populated)
		{
			var myXML:XML = new XML();
			myXML.ignoreWhite=true;			
			myXML.onLoad = Delegate.create(this, function(success) 
			{
				if (success) 
				{
					var nodes = myXML.firstChild.childNodes;
					for (var i=0; i<nodes.length; i++)
					{
						if (nodes[i].nodeName == "segment")
						{
							_addSegment(nodes[i].childNodes);
						}
						else if (nodes[i].nodeName == "branch")
						{
							_addDecisionPoint(nodes[i].childNodes);						
						}
					}			
					_populated = true;	
					_simulate (doneCallback);
				}
			});
			myXML.load(_filename);
			
			return;
		}
		_resetPlayData();
		_simulate (doneCallback);
	}
	
	private function _resetPlayData():Void
	{
		for (var i=0;i<_segments.length;i++)
		{
			_segments[i].playcount = 0;
		}
	}
	
	private function _addSegment (segXML:Array):Void
	{
		var newSegment = new Segment();
				
		for (var j=0; j<segXML.length;j++)
		{							
			if (segXML[j].nodeName == "audio")
			{
				newSegment.filename = segXML[j].firstChild.nodeValue;
			}
			else if (segXML[j].nodeName == "id")
			{
				newSegment.id = segXML[j].firstChild.nodeValue;
			}							
		}
		_segments[_segments.length] = newSegment;
	}
	
	private function _addDecisionPoint (branchXML:Array):Void
	{		
		var newDecisionPoint = new Array();	
		
		for (var j=0; j<branchXML.length;j++)
		{
			var choiceXML = branchXML[j].childNodes;			
			var newChoice = new Choice ();
										
			for (var k=0;k<choiceXML.length;k++)
			{
				if (choiceXML[k].nodeName == "weight")
				{
					newChoice.weight = parseInt(choiceXML[k].firstChild.nodeValue);
				}
				else if (choiceXML[k].nodeName == "id")
				{
					newChoice.segmentId = choiceXML[k].firstChild.nodeValue;
				}
				else if (choiceXML[k].nodeName == "condition")
				{
					var newCondition = new Condition;									
					var conditionXML = choiceXML[k].childNodes;
					
					for (var m=0;m<conditionXML.length;m++)
					{
						if (conditionXML[m].nodeName == "id")
						{
							newCondition.segmentId = conditionXML[m].firstChild.nodeValue;
						}
						else if (conditionXML[m].nodeName == "min")
						{
							newCondition.min = parseInt(conditionXML[m].firstChild.nodeValue);
						}
						else if (conditionXML[m].nodeName == "max")
						{
							newCondition.max = parseInt(conditionXML[m].firstChild.nodeValue);
						}
					}
					
					newChoice.conditions[newChoice.conditions.length] = newCondition;
				}
			}
			newDecisionPoint[newDecisionPoint.length] = newChoice;
		}
		var newIndex = _decisionPoints.length;
		_decisionPoints[newIndex] = newDecisionPoint;
		var lastSegment = _segments.length - 1;
		if (lastSegment >= 0)
		{
			_segments[lastSegment].nextDecision = newIndex;
		}
	}
	
	private function _getSegmentIndexWithId (id:String):Number
	{
		for (var i=0;i<_segments.length;i++)
		{
			if (_segments[i].id == id)
			{
				return i;
			}
		}
		return undefined;
	}
	
	private function _getSegmentWithId (id:String):Segment
	{
		var index:Number = _getSegmentIndexWithId( id);
		
		if (index != undefined)
		{
			return _segments[index];
		}
		return undefined;
	}
	
	private function _simulate (doneFunction:Function):Void
	{
		var currentSegmentIndex:Number = 0;
		var totalPlayCount:Number = 0;
		var maxPlayCount:Number = 500;
		
		var filenameList:String = "";
		var first:Boolean = true;
		
		while (totalPlayCount < maxPlayCount && currentSegmentIndex >= 0 && currentSegmentIndex < _segments.length)
		{
			totalPlayCount++;
			
			var currSegment:Segment = _segments[currentSegmentIndex];
			
			if (currSegment.filename != undefined)
			{
				if (first)
				{
					filenameList = currSegment.filename;
					first = false;
				}
				else
				{
					filenameList += "," + currSegment.filename;
				}
			}
			currSegment.playcount++;
			
			if (currSegment.nextDecision == -1)
			{
				currentSegmentIndex++;
			}
			else
			{
				currentSegmentIndex = _decideNextSegment(currSegment.nextDecision);
			}
		}
		
		doneFunction (filenameList);
	}
	
	// returns the index of the next segment to play, or -1 if none
	private function _decideNextSegment(decisionIndex:Number):Number
	{
		var choices = _decisionPoints[decisionIndex];
		
		var validChoices = _filterInvalidChoices(choices);
		
		var segmentId = _pickWeightedChoice (validChoices);
		
		return _getSegmentIndexWithId(segmentId);
	}
	
	private static function _randRange(min:Number, max:Number):Number
	{
    	var randomNum:Number = Math.floor(Math.random() * (max - min + 1)) + min;
    	return randomNum;
	}
	
	// returns the segment id of the chosen choice or undefined if there are no choices
	private function _pickWeightedChoice (choices:Array):String
	{
		var totalWeight:Number = 0;
		for (var i=0;i<choices.length;i++)
		{
			totalWeight += choices[i].weight;
		}
		if (totalWeight == 0)
		{
			return undefined;
		}
		
		var chosenVal:Number = _randRange(0, totalWeight-1);
		
		var count:Number = 0;
		var remainingInCurrent:Number = choices[0].weight;
		var choiceIndex:Number = 0;
		while (count < chosenVal)
		{			
			remainingInCurrent--;
			count++;
			
			if (remainingInCurrent <= 0)
			{
				choiceIndex++;
				remainingInCurrent = choices[choiceIndex].weight;
			}
		}
		
		return choices[choiceIndex].segmentId;
	}
	
	private function _filterInvalidChoices(choices:Array):Array
	{
		var newChoices = new Array();
		
		for (var i=0; i<choices.length;i++)
		{
			if (_choiceIsValid(choices[i]))
			{
				newChoices[newChoices.length] = choices[i];
			}
		}
		return newChoices;
	}
	
	private function _choiceIsValid(choice:Choice):Boolean
	{
		for (var i=0;i<choice.conditions.length;i++)
		{
			if (!_conditionIsValid(choice.conditions[i]))
			{
				return false;
			}
		}
		return true;
	}
	
	private function _conditionIsValid(condition:Condition):Boolean
	{
		var segment:Segment = _getSegmentWithId(condition.segmentId);
		if (segment == undefined)
		{
			return false;
		}
		return (condition.min <= segment.playcount && (condition.max == -1 || segment.playcount <= condition.max));
	}
}