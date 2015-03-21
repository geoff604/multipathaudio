class net.onepixelout.audio.Choice
{
	// an integer indicating the weight of this choice, as compared to other
	// valid choices at the decision point.
	// a greater number means the choice is proportionally more likely.
	public var weight:Number;
	
	// the id of the segment to play if this choice is chosen
	public var segmentId:String;
	
	// an array of Condition instances. all conditions must be satisfied
	// for this choice to be valid.
	public var conditions:Array;
	
	public function Choice ()
	{
		conditions = new Array();
		weight = 1;
	}
}