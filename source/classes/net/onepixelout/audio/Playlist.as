import net.onepixelout.audio.Track;

class net.onepixelout.audio.Playlist
{
	private var _tracks:Array;
	private var _currentTrackIndex:Number;
	public var length:Number;
	static private var _cyclingEnabled:Boolean = true;
	
	private var _totalDuration:Number; // total play time in milliseconds.
	
	public function Playlist(enableCycling:Boolean)
	{
		_tracks = new Array();
		_currentTrackIndex = 0;
		this.length = 0;
		_totalDuration = 0;
		
		if(enableCycling != undefined) _cyclingEnabled = enableCycling;
	}
	
	// Gets the total play time of all of the tracks in the playlist,
	// in ms.
	public function getTotalDuration():Number
	{
		if (_totalDuration == 0)
		{
			for (var i=0; i<_tracks.length; i++)
			{
				var track:Track = _tracks[i];
				if (track.isFullyLoaded())
				{
					_totalDuration += track.getSound().duration;
				}			
			}
		}
		return _totalDuration;
	}
	
	// Gets the total elapsed time in ms from the beginning of the playlist
	// to the playhead position in the current track.
	public function getElapsedTime():Number
	{
		var elapsedTime:Number = 0;
		for (var i=0; i<_currentTrackIndex; i++)
		{
			var track:Track = _tracks[i];
			if (track.isFullyLoaded())
			{
				elapsedTime += track.getSound().duration;
			}			
		}
		elapsedTime += _tracks[_currentTrackIndex].getSound().position;
		return elapsedTime;
	}
	
	// Given a position in ms relative to the beginning of the entire playlist,
	// find the right track and start, returning the current sound object.
	public function start(position:Number):Sound
	{
		var trackNumber:Number;
		var remainingDuration:Number = position;
		for (trackNumber = 0; trackNumber < _tracks.length; trackNumber++)
		{
			var trackSound:Sound = _tracks[trackNumber].getSound();
			if (trackSound.duration > remainingDuration)
			{
				setCurrentIndex (trackNumber);
				trackSound.start(Math.floor(remainingDuration / 1000));
				return trackSound;
			}
			remainingDuration -= trackSound.duration;
		}
		return undefined;
	}
	
	public function loadFromList(trackList:String, titleList:String, artistList:String):Void
	{
		var trackArray:Array = trackList.split(",");

		if(titleList == undefined) titleList = "";
		if(artistList == undefined) artistList = "";
		var titleArray:Array = (titleList.length == 0) ? new Array() : titleList.split(",");
		var artistArray:Array = (artistList.length == 0) ? new Array() : artistList.split(",");
		
		var newTrack:Track;
		
		for(var i:Number = 0;i < trackArray.length;i++)
		{
			newTrack = new Track(trackArray[i]);
			if(i < titleArray.length) {
				newTrack.setTitle(titleArray[i]);
				//newTrack.setArtist("");
			}
			if(i < artistArray.length) newTrack.setArtist(artistArray[i]);
			this.addTrack(newTrack);
		}
	}
	
	public function loadFromXML(listXML:XML):Void
	{
		var tracks:Array = listXML.firstChild.childNodes;
		for(var i:Number = 0;i < tracks.length;i++)
		{
			addTrack(new Track(_getNodeValue(tracks[i], "src"), _getNodeValue(tracks[i], "title"), _getNodeValue(tracks[i], "artist")));
		}
	}
	
	private function _getNodeValue(root:XMLNode, nodeName:String):String
	{
		nodeName = nodeName.toLowerCase();
		for(var i:Number = 0;root.childNodes.length;i++)
		{
			if(root.childNodes[i].nodeName.toLowerCase() == nodeName)
			{
				return root.childNodes[i].firstChild.nodeValue;
			}
		}
		return null;
	}
	
	public function getTrackCount():Number
	{
		return _tracks.length;
	}
	
	public function getTrackAt(position:Number):Track
	{
		return _tracks[position];
	}
	
	public function getCurrent():Track
	{
		return _tracks[_currentTrackIndex];
	}
	
	public function getCurrentIndex():Number
	{
		return _currentTrackIndex;
	}
	
	public function setCurrentIndex(currentTrackIndex:Number):Void
	{
		_currentTrackIndex = currentTrackIndex;
	}
	
	public function hasNext():Boolean
	{
		return (_currentTrackIndex < length-1);
	}
	
	public function next():Track
	{
		if(this.hasNext()) return _tracks[++_currentTrackIndex];
		else if(_cyclingEnabled)
		{
			_currentTrackIndex = 0;
			return _tracks[0];
		}
		else return null;
	}

	public function hasPrevious():Boolean
	{
		return (_currentTrackIndex > 0);
	}

	public function previous():Track
	{
		if(this.hasPrevious()) return _tracks[--_currentTrackIndex];
		else if(_cyclingEnabled)
		{
			_currentTrackIndex = length-1;
			return _tracks[_currentTrackIndex];
		}
		else return null;
	}
	
	public function getAtPosition(position:Number):Track
	{
		if(position >= 0 && position < length) {
			_currentTrackIndex = position;
			return _tracks[position];
		}
		else return null;
	}
	
	public function addTrack(track:Track):Void
	{
		_tracks.push(track);
		length = _tracks.length;
	}
	
	public function removeAt(position:Number):Void
	{
		_tracks.splice(position, 1);
		length = _tracks.length;
	}
}