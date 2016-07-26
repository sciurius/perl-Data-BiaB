package lilywrite;
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
##
##   provides a class to write Lilypond file format
##
#  todo: triplet rests not supported!
#
# CVS:
# $Revision: 1.8 $
# 

use biabdefs;
use lilydefs;

@songTimeStrs = ('foo','4/4','3/4','12/8');
$octOffset=0;
$melodyDebug=0;
$trackTrip =0; #per-triplet counter
$trackTripDur =0; #dur of tracked triplet note
local $barDur;
sub new {
  my $this = shift;
  #parameters
  ($LILYfile, $WARNfile, $title, $biabFileName, $biabStyleFile, $BPM, $key, $majmin, $style, $timeNom, $timeDenom, $version) = @_;
    
  my $class= ref($this) || $this;
  my $self = {};
  bless $self, $class;

  print "lilywrite: born. file to write: $LILYfile in $timeNom/$timeDenom\n";
  
  
    
  return $self;
}

sub putChordNames {
  my $this = shift;
  @aChords = @_;
}
sub putChordDurs {
  my $this = shift;
  @aChordDurs = @_;
}

sub putMelodyWhen {
  my $this = shift;
  @aMelodyWhen = @_;
}
sub putMelodyMIDInum {  
  my $this = shift;
  @aMelodyMIDInum = @_;

}
sub putMelodyDuration {  
  my $this = shift;
  @aMelodyDuration = @_;
}

###############################
sub writeLily {
  open(LILY, ">$LILYfile") or 
                  die " error: $LILYfile : $!\n";

  print LILY '
\\version "2.2.4"
\\header{
	title="'.$title.'"
	tagline="Converted from the Band in a Box file:'.$biabFileName.' with biabconverter V.'.$version.'"
}';
  print LILY "
\\score{
	<<
		\\new ChordNames \\chords {\\override ChordName #'font-size = #6
		\\set chordNameSeparator = \\markup {  }  % no separator!

\t";

  my $count=0;
  for($i=0;$i<@aChords; $i++) {
    print LILY $aChords[$i]." ";
    
    # this is just for beauty of output
    $count = $count + $aChordDurs[$i];
    if ($count >= 4) { print LILY "\n\t"; $count = 0;}
  }
  
  print LILY "}\n";
  ############## now the notes ##########
  $timeStr = "$timeNom/$timeDenom";
  
  print LILY "\\notes {
      \\time $timeStr
      \\clef treble
      \\key $key \\$majmin
      << {";
      # todo here !

  ###############################################################################
  ## now, write notes
  ##########
  
  $inbarCount=0; #in MIDI
  $barCount=1;
  
  $barDur = &getBarDur($timeNom,$timeDenom);
  $barDurStr = &getNoteDur($barDur,$timeNom,$timeDenom);
  print "lilywrite: barDur $barDur\n";
  #  find beginning time of melody
  ($preRests,$foo) = quantize($aMelodyWhen[0],$aMelodyWhen[0]);
  
  $preMeasures = int $preRests / $barDur; # to be fixed for jigs
  #two measures count in
  $preMeasures= $preMeasures -2;


  $preRests = $preRests % $barDur;
  
  if ($preRests == 0 ) {$preRestStr =" ";}
    else {($preRestStr,$isTrip) = &getNoteDur($preRests,$timeNom,$timeDenom);}
  if ($melodyDebug) { print "Melody begins after $preMeasures Measures and $preRestStr \n";}
  for ($i=0; $i<$preMeasures; $i++) {print LILY "r$barDurStr |\n\t";}
  if ($preRests >0) {print LILY "r$preRestStr ";}
  #now begins the melody;
  $barCount=$barCount+$preMeasures;
  
  $inbarCount = $preRests;
  
  if ($melodyDebug) { print "melody--debug\n"; }
  for($i=0; $i<@aMelodyWhen; $i++) {
    if ($aMelodyMIDInum[$i] == 0 ) {next;} #security
    my $thisWhen=$aMelodyWhen[$i];
    if ($i==@aMelodyWhen-1) {$nextWhen=$thisWhen+$aMelodyDuration[$i];}
    else {$nextWhen=$aMelodyWhen[$i+1];}
    my $thisDur = $aMelodyDuration[$i];
    my $thisDurToNext = $nextWhen-$thisWhen;
    my $tmpToNext=$thisDurToNext;
    my $thisStr = getLilyNote($aMelodyMIDInum[$i]);
    my $thisOct = int ($aMelodyMIDInum[$i] / 12);
    
    my $thisOctRel = $thisOct - 4 + $octOffset;
    do {
      if ($thisOctRel<0) { $thisStr = $thisStr.","; $thisOctRel++; }
      if ($thisOctRel>0) { $thisStr = $thisStr."'"; $thisOctRel--; }
    } until ($thisOctRel==0);
      
    ($thisDur, $thisDurToNext, $isTrip,$trackTripDur) = &quantize($thisDur, $thisDurToNext,$inbarCount,$trackTrip,$trackTripDur);
    if ($isTrip) { 
      if ($trackTrip == 0) {
    	print LILY '\times 2/3 {';
	print "lilywrite: starting triplet\n";
      }
      $trackTrip++;
    }
    if ($trackTrip > 3) {
      print LILY '}';		#fails if triplet is last note of melody
      print "lilywrite: ending triplet\n";
      $trackTrip=0;$trackTripDur=0;
    }  
    
      	 
    if ($thisDurToNext == 0 ) { &warning("MEDIUM invalidNote: Nr $i"); next;} #security
    
    
    if ($melodyDebug) {  print "note nr ".($i+1)." ---$thisStr---MIDIdur:$aMelodyDuration[$i]/$tmpToNext--thisDur/toNext:$thisDur/$thisDurToNext----MIDIpitch:$aMelodyMIDInum[$i]----\n";}

    unless ($thisDurToNext <= 64*$barDur) { next; } #security

    while ($thisDurToNext > 0) {
      if ($melodyDebug) { print "inbarCount=$inbarCount - write $thisStr - $thisDurToNext\n";}
      if ($inbarCount + $thisDur > $barDur) {
        #print "filling, but checking halfmeasure first\n";
        if (($inbarCount < $barDur/2 ) 
        and (($inbarCount + $thisDur > $barDur/2) and ($timeNom % 2 == 0)) #if we will cross the middle in even time
        and !(($inbarCount ==0) and ($thisDur >= $barDur))) {
          #first fill first half
  	    if ($melodyDebug) { print "filling first half";}
  	  $nextDur = $thisDur - ($barDur/2 - $inbarCount);
          $thisDur = $thisDur - $nextDur;
          $thisDurToNext = $thisDurToNext - $thisDur;
          print LILY $thisStr.&getNoteDur($thisDur,$timeNom,$timeDenom)."~ "; 
          $thisDur = $nextDur;
          $inbarCount = $barDur/2;
          next;
        }
          if ($melodyDebug) { print "filling bar nr $barCount, because $inbarCount + $thisDur > $barDur **************\n";}
        $nextDur = $thisDur - ($barDur - $inbarCount);
        $thisDur = $thisDur - $nextDur;
        $thisDurToNext = $thisDurToNext - $thisDur;
        print LILY $thisStr.&getNoteDur($thisDur,$timeNom,$timeDenom)."~| % BarNr $barCount\n\t"; #barcheck
          if ($melodyDebug) { print "filling bar nr $barCount, because $inbarCount + $thisDur > $barDur\n";}
        $thisDur = $nextDur;
        $inbarCount = 0;
        $barCount++;
        next;
      }
      # is a part of the note left?
      if ($thisDur > 0) {
        if (($inbarCount < $barDur/2 ) # if we are in first half of measure
        and (($inbarCount + $thisDur > $barDur/2) and ($timeNom % 2 == 0)) #if we will cross the middle in even time
        and !(($inbarCount ==0) and (($thisDur >= $barDur) or ($thisDur == 3/4*$barDur)))) { #if it's not a full note measure or a dotted half at bbeginning of measure
          #first fill first half
  	    if ($melodyDebug) { print "filling first half\n";}
  	  $nextDur = $thisDur - ($barDur/2 - $inbarCount);
          $thisDur = $thisDur - $nextDur;
          $thisDurToNext = $thisDurToNext - $thisDur;
          print LILY $thisStr.&getNoteDur($thisDur,$timeNom,$timeDenom)." ";
	  unless ($nextDur == 0) { print LILY "~ ";} 
          $thisDur = $nextDur;
          $inbarCount = $barDur/2;
          next;
        }
        print LILY $thisStr.&getNoteDur($thisDur,$timeNom,$timeDenom)." ";
        $inbarCount = $inbarCount + $thisDur;
        $thisDurToNext = $thisDurToNext - $thisDur;
          if ($melodyDebug) { print "wrote $thisDur,$thisStr - new inbarCount $inbarCount\n";}
        if ($inbarCount == $barDur) {
          print LILY "| % BarNr $barCount\n\t"; #barcheck
            if ($melodyDebug) { print "bar $barCount end ************************************\n";  }
 	  $inbarCount=0;
	  $barCount++;
        }	
      } else {
        $thisDurToNext = 0;  #security
      }  
      #what is possibly left can be but rests
      $thisStr = "r";
      $thisDur = $thisDurToNext; #what is left is rests
  
    }  
  }      
  
  
  $numOfLines = int $barCount / 4 +1;
  print "number of lines: $numOfLines \n";
  print LILY "}";
  if ($timeNom == 4) {print LILY "	
       \\new Voice {  
       \\repeat unfold $numOfLines { \\hideNotes c8 c c c c c c c |
	 c8 c c c c c c c |
	 c8 c c c c c c c |
	 c8 c c c c c c c | \\break }
      }";
  }    
  print LILY "
      >>
    }
  >>
}
";
  
  close LILY;
  print "wrote $LILYfile\n";
}

#########################################

sub round {
  $number = shift;
  return int ($number + .5) * ($number <=> 0);
} 
 
sub warning {
  open(WARN, ">>$WARNfile") or 
                  die " error: $WARNfile : $!\n";
  print WARN "lilywrite: ".shift()."\n";

  close WARN;
}  


return 1;
