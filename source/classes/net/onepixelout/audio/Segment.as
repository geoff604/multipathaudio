class net.onepixelout.audio.Segment
{
	// the audio filename to play for this segment
	public var filename:String;
	
	// the unique identifier for this segment
	public var id:String;
	
	// If after playing this segment, if we should execute a decision point,
	// nextDecision should contain the array index of the Decision Point.
	// -1 if the next thing to play is the next segment, not a decision point.
	public var nextDecision:Number; 
	
	// updated while playing. Indicates how many times this segment has been
	// played so far
	public var playcount:Number;
	
	public function Segment ()
	{
		nextDecision = -1;
		playcount = 0;
	}
}