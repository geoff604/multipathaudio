class net.onepixelout.audio.Condition
{
	// the id of the segment to check the number of plays of.
	public var segmentId:String;
	
	// the minimum number of times the checked segment has been played for the 
	// condition to be true.
	public var min:Number;
	
	// the maximum number of times the checked segment has been played for the 
	// condition to be true. -1 for no max.
	public var max:Number;
	
	public function Condition ()
	{
		min = 0;
		max = -1;
	}
}