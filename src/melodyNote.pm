###################################################################
#
#         Band-In-A-Box File Converter
#           ----------------------------
#             Alain Brenzikofer 
#               brenzi@student.ethz.ch
#     
# 	a quick hack to parse Band in a box files.
# 	based on the Delphi coded "BIABTools" of Alf Warnock
#	It doesn't work with all files yet!!!!!!
#
#	License: GPL
#
# 	all user-customizeable values are located in 
# 	biabdefs.pm, lilydefs.pm and mmadefs.pm
# 	they are still incomplete! Please submit any new findings! 
# 	
####################################################################
## $Id: melodyNote.pm 36 2007-01-10 21:16:01Z brenzi $
####################### melodyNote class ###################
package melodyNote;
  #my $onset;
  #my $duration;
  #my $MIDIpitch;
  #my $velocity;
  #my $channel;
  #my $isaRest;
  
  sub new {
    my ($class, $onset, $duration, $MIDIpitch, $velocity, $channel, $isaRest, $fullDur) = @_;
    unless (defined $isaRest) {$isaRest =0;}
    unless (defined $fullDur) {$fullDur= -1;}
   
    my $note = {
    	"onset"		=> $onset,
	"duration"	=> $duration,
	"MIDIpitch"	=> $MIDIpitch,
	"velocity"	=> $velocity,
	"channel"	=> $channel,
	"isaRest"	=> $isaRest,
	"fullDur"	=> $fullDur
    };
    bless $note, $class;
    return $note	 
  }
  sub onset { my $this = shift();return $this->{onset}; }
  sub duration { my $this = shift();return $this->{duration}; }
  sub MIDIpitch { my $this = shift();return $this->{MIDIpitch}; }
  sub velocity { my $this = shift();return $this->{velocity}; }
  sub channel { my $this = shift();return $this->{channel}; }
  sub isaRest { my $this = shift();return $this->{isaRest}; } 
  sub fullDur { my $this = shift();return $this->{fullDur}; } 
  sub quantizedOnset {
    my $this = shift();
    my $atom = shift();
    return $atom*(int ($this->{onset}/$atom + .5) * ($this->{onset}/$atom <=> 0));
  }  
  sub quantizedDuration {
    
    my $this = shift();
    my $atom = shift();
      # respect quant offset at note onset
    my $off = $this->quantizedOnset($atom) - $this->{onset};
    my $dur = $this->{duration}-$off;
      
    return $atom*(int ($dur/$atom + .5) * ($dur/$atom <=> 0));
  }  
  sub quantizedFullDur {
    my $this = shift();
    my $atom = shift();
    return $atom*(int ($this->{fullDur}/$atom + .5) * ($this->{fullDur}/$atom <=> 0));
  }  
  sub addToDur {
    my $this = shift();
    my $summand = shift();
    $this->{duration} = $this->{duration}+$summand;
  }  
  sub addToOnset {
    my $this = shift();
    my $summand = shift();
    $this->{onset} = $this->{onset}+$summand;
  }  
  sub info {
    my $this = shift();
    return "melodyNote: onset ".$this->{onset}." \t/ dur ".$this->{duration}." \t/ MIDIpitch ".$this->{MIDIpitch}." / vel ".$this->{velocity}." / MIDIch ".$this->{channel}." / isaRest ".$this->{isaRest}." / fullDur ".$this->{fullDur}."\n";
  }  

return 1;
