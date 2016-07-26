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
# $Revision: 1.20 $
# 

use biabdefs;
use lilydefs;
use melodyNote;
use File::Basename;

@songTimeStrs = ('foo','4/4','3/4','12/8');

$melodyDebug=0;
$trackTrip =0; #per-triplet counter
$trackTripDur =0; #dur of tracked triplet note
$allowTriplets=1;
$currentNote=-1;
$lastNoteProcessed=0;
$lilyTargetVersion = "2.2.4"; 
$useConvertLy = 0; #causes trouble, when version stays the same (convert-ly bug)

local $barDur;
sub new {
  my $this = shift;
  #parameters
  ($LILYfile, $WARNfile, $title, $biabFileName, $biabStyleFile, $BPM, $key, $majmin, $style, $timeNom, $timeDenom, $version, $template, $hasMelody, $debug) = @_;
    
  my $class= ref($this) || $this;
  my $self = {};
  bless $self, $class;

  print "lilywrite: born. file to write: $LILYfile in $timeNom/$timeDenom\n" if ($debug);
  print "Using template: $template\n" if ($debug);
  
    
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
sub putMelodyChannel {  
  my $this = shift;
  @aMelodyChannel = @_;
}
sub putMelody {  
  my $this = shift;
  @aMelody = @_;
}

###############################
sub writeLily {

#################
# if (`which convert-ly`) {
#   open(LILY, "| convert-ly --from $lilyTargetVersion - >$LILYfile") or
#     die " error opening autoconversion pipe : $!\n";
# } else {
#   open(LILY, ">$LILYfile") or
#     die " error: $LILYfile : $!\n";
# } 
# open(TMPL, "<$template") or die " error: $template : $!\n";
#############
  open(LILY, ">$LILYfile") or
    die " error: $LILYfile : $!\n";
  open(TMPL, "<$template") or die " error: $template : $!\n";



#  print LILY '
#\\version "'.$lilyTargetVersion.'" 
#\\header{
#	title="'.$title.'"
#	tagline="Converted from Band in a Box file:'.$biabFileName.' with biabconverter V.'.$version.'"
#}';
#  print LILY "
#\\score{
#	<<
#		\\new ChordNames \\chords {\\override ChordName #'font-size = #6
#		
#
#\t";
  $chords = "";
  $notes  = "";

  $barCount=1;
  
  ($barDur,$barRefDur,$smallestNote,$smallestTriplet) = getBarDur($timeNom,$timeDenom);
  $myAtom=$smallestNote; #test fixing div by zero bug
  if ($smallestTriplet<$smallestNote) { $smallestAbsolute = $smallestTriplet;}
  else {$smallestAbsolute = $smallestNote;}
    
  $barDurStr = &getNoteDur($barDur,$timeNom,$timeDenom);
  print "lilywrite: barDur $barDur, smallestNote $smallestNote, smallestTriplet $smallestTriplet\n" if ($debug);
  
  if (defined $aMelody[0]) {
     # find beginning time of melody
   print "firstOnset:".$aMelody[0]->onset."\n" if ($debug);
   $firstOnset = $aMelody[0]->onset;
  } else {$firstOnset=$barDur * 2;$lastOnset=$firstOnset;}
  
  $preMeasuresFull = int $firstOnset / $barDur; # to be fixed for jigs
    #two measures count in
  $preMeasures= $preMeasuresFull -2;

  $preRests = $firstOnset % $barDur;
  print "Melody begins after $preMeasures Measures and $preRests \n" if ($debug);
  if ($firstOnset>99999) {print "lilywrite: there seems to e a problem with the melody!\n"; 
  		&warning("CRITICAL: lilywrite: there seems to e a problem with the melody!");
		$hasMelody=0;}

    #shift chords if there's a lead-in
  for($i=$preMeasures;$i<0;$i++){
    #print LILY "r1 ";
    $chords .= "r1 ";
  }
  my $count=0;
  for($i=0;$i<@aChords; $i++) {
    # print LILY $aChords[$i]." ";
    $chords .= $aChords[$i] . " ";
    
      # this is just for beauty of output
    $count = $count + $aChordDurs[$i];
    if ($count >= 4) { $chords .= "\n"; $count = 0;}  #print LILY "\n\t"; $count = 0;
      
  }
  
  #print LILY "}\n";
  ############## now the notes ##########
  $timeStr = "$timeNom/$timeDenom";
  
  #print LILY "\\notes {
  #    \\time $timeStr
  #    \\clef treble
  #    \\key $key \\$majmin
  #    << {";
  #    # todo here !

  ###############################################################################
  ## now, write notes
  ##########
  
 if ($hasMelody) {
  for ($i=0; $i<$preMeasures; $i++) {$notes .= "r$barDurStr |\n";} #print LILY "r$barDurStr |\n\t";}
 
  #create a rest
  $preRestNote = new melodyNote(($preMeasuresFull) * $barDur, $preRests,0,0,144,1,$preRests);
  
  #now begins the melody;
  $barCount=$barCount+$preMeasures;
  
  #$inbarCount = $preRests;
  
  print "melody--debug\n" if ($debug); 
  
  
    #to be modified for 6/8 ???
    $swingLevel=6; # where no [2 1] triplets will be allowed
    @unitDur=(	$barRefDur, 
    		 $barRefDur*3/4, 
		  $barRefDur*2/3, 
		$barRefDur/2, 
    		 $barRefDur*3/8, 
		  $barRefDur*2/6, 
		$barRefDur/4, 
    		 $barRefDur*3/16, 
		  $barRefDur*2/12,
		$barRefDur/8, 
    		 $barRefDur*3/32, 
		  $barRefDur*2/24,
		$barRefDur/16, 
    		 $barRefDur*3/64, 
		  $barRefDur*2/48, 
		$barRefDur/32, 
    		 $barRefDur*3/128, 
		  $barRefDur*2/96
		);
    @allowTriplets = (	1, 
    			 0, 
			  0, 
			1, 
    			 0, 
			  0, 
			1, 
    			 0, 
			  0, 
			1, 
    			 0, 
			  0, 
			1, 
    			 0, 
			  0, 
			1, 
    			 0, 
			  0, 
			);
    @check3patterns = (	0, 
    			 1, 
			  0, 
			0, 
    			 1, 
			  0, 
			0, 
    			 1, 
			  0, 
			0, 
    			 1, 
			  0, 
			0, 
    			 1, 
			  0, 
			0, 
    			 1, 
			  0, 
			);

  if ($timeNom == 4) {$barStartLevel = 0;}
  if ($timeNom == 3) {$barStartLevel = 1;}
   
  #for($i=0; $i<@aMelody; $i++) {
  #  $tmp=$aMelody[$i];print $i.$tmp->info;
  #}   
  #start recursive melody notation
  $restNote=$preRestNote;
  $barCount=1;
  while ((defined &watchNextNote) and ($lastNoteProcessed==0))
  {
    $restNote = &newNotationUnit($barStartLevel,$restNote);
    $notes .= "| % barNr $barCount\n";
    #print LILY "| % barNr $barCount\n\t";
    print "lilywrite: measure $barCount complete||||||||||||||||||||||||||||||\n" if ($debug);
    $barCount++;
  }  

  $numOfLines = int $barCount / 4 +1;
  print "number of lines: $numOfLines \n" if ($debug);
#  print LILY "}";
  if ($timeNom == 4) {
     ###########
     #$notes = "<< {\n$notes }\n\\new Voice {  % the following lines are a hack to get 4 Measures per line";
     ##########
     chomp($notes);
     $notes =~ s/\n/\n    /mg;
     $notes = "<<\n  {\n    $notes\n  }\n  \\new Voice { % hack to get 4 Measures per line";  

     #strech first line if there's a lead-in (i.e. 5 measures on first line)
     for($i=$preMeasures;$i<0;$i++){
    	  $notes .= "\\hideNotes c8 c c c c c c c | ";
	  #Alternative von Matthias
	  #$notes .= "s1 \\noBreak ";
     }

     $notes .= "\n\\repeat unfold $numOfLines { \\hideNotes c8 c c c c c c c |
	 c8 c c c c c c c |
	 c8 c c c c c c c |
	 c8 c c c c c c c | \\break }
} >>";

 
 
#Alternative Matthias
#     $notes .= "\n    \\repeat unfold $numOfLines {
#       s1 \\noBreak s1 \\noBreak s1 \\noBreak s1 \\break
#     }
#   }
# >>";   
  }
 } #end of if ($hasMelody)     
  %args = (
	   TARGET_VERSION => $lilyTargetVersion,
 	   TITLE          => $title,
 	   BIAB_FILE_NAME => basename($biabFileName),
 	   BIAB_CONVERTER => $version,
 	   TIME           => $timeStr,
 	   KEY            => $key . " \\" . $majmin,
            CHORDS         => $chords,
            NOTES          => $notes,
            LYRICS         => ""
  );
  while (<TMPL>) {
    while (($pre,$arg,$post) = /(.*?)\<\{(\s*\w+\s*)\}\>(.*)/s) {
       print LILY $pre;
       die "Template argument $arg not defined.\n" unless defined $args{$arg};
       chomp($val = $args{$arg});
       $val =~ s/\n/\n$pre/mg;
       print LILY $val;
       $_ = $post;
    }
    print LILY $_;
       
  }
  
  close LILY;
  ### causes problems if converting from 2.4 to 2.4 (empty file)
  if ($useConvertLy) {
    if (`which convert-ly`) {
     !system("convert-ly $LILYfile > $LILYfile.new && mv $LILYfile.new $LILYfile") or
       die " error running autoconversion : $!\n";
    }
  }  

  print "lilywrite: wrote $LILYfile\n";
}

#########################################
# a notation brick
# returns a note representing the rest of the 
# last note in this unit that didn't fit including quantization offset

sub newNotationUnit {
  my $level = shift();
  #my $quantOffset = shift();
  my $note = shift();
  #my $allowSameLevelForward= shift();
  #my $nextNote = &watchNextNote;

  print "lilyWrite:NotationUnit(l:$level,n:$currentNote)".$note->info if ($debug);
  
  unless (defined $unitDur[$level]) {
    # we ran too far, get next without output
    print "lilyWrite: level ran too deep! This should never happen. Errors are probable!!! returning with next note.\n";
    return &getNextNote($note->fullDur);
  }
    #check for rests
  if ($note->quantizedDuration($smallestAbsolute) < $smallestAbsolute) {
          
    $nextNote=&watchNextNote;
    #$diff=$nextNote->onset-$note->onset-$note->duration;
    $diff=$nextNote->quantizedOnset($smallestAbsolute)-$note->quantizedOnset($smallestAbsolute)-$note->quantizedDuration($smallestAbsolute);
    print "lilyWrite: left dur:".$note->duration. " / durToNext: ".$diff."\n" if ($debug);
    if ($diff>=$smallestAbsolute) {
      
      $note = new melodyNote(	$note->onset,
				$diff,
				0,
				0,
				$note->channel,
				1,
				$diff); #is a rest
       print "lilyWrite: rests are left, made a rest:".$note->info if ($debug);			
    }
    else {
      #print "lilyWrite: getting next note\n" if ($debug);
      # respect quantization offset
      #$quantOff=$note->quantizedOnset-$note->onset;
      $note = &getNextNote($note->duration);
      print "lilyWrget:NotationUnit(l:$level,n:$currentNote)".$note->info if ($debug);
  
    }        
  } 
  
    


  $note = &fillBadRests($note, $level);

  my $qDur = $note->quantizedDuration($smallestNote);
  my $qDurErr = abs $qDur - $note->duration;
  my $qDurTrip = $note->quantizedDuration($smallestTriplet);
  my $qDurTripErr = abs $qDurTrip - $note->duration;
  print "lilyWrite:qDur:$qDur (err: $qDurErr) qDurTrip:$qDurTrip (err $qDurTripErr) /unitDur:".$unitDur[$level]."\n" if ($debug);
  
    # full unit?
  if ($qDur >= $unitDur[$level]) {
    return &writePartUnit($note, $unitDur[$level]); 
  }

    # 7/8 unit? (double dotted note?) => left out
  #place code here if wanted
    
    # 3/4 unit? (dotted note)
  if (($level%3 == 0) and
      ($qDur >= $unitDur[$level]*3/4)  ) { #and       (($qDurErr < $qDurTripErr) or (!$allowTriplets[$level]))
    $note = &writePartUnit($note, $unitDur[$level]*3/4); 
    return &newNotationUnit($level+6,$note);
  }
    # 2/3 unit? ( time3/4 half ) 
  if (($check3patterns[$level]) and
      ($qDur >= $unitDur[$level]*2/3)) {
    $note = &writePartUnit($note, $unitDur[$level]*2/3);  
    return &newNotationUnit($level+5,$note);
  }    
    # >=1/2 unit? 
  if (!($check3patterns[$level]) and
      ($qDur >= $unitDur[$level]/2) and 
      (($qDurErr < $qDurTripErr) or (!$allowTriplets[$level]))){
    $note = &writePartUnit($note, $unitDur[$level]/2);  
    return &newNotationUnit($level+3,$note);
  }    
    #  
  if (!($check3patterns[$level]) and (($qDurErr < $qDurTripErr) or (!$allowTriplets[$level])) and 
      ($qDur > $unitDur[$level]/3) ){
    #$note = &writePartUnit($note, $unitDur[$level]/2);  
    $note = &newNotationUnit($level+3,$note);
    return &newNotationUnit($level+3,$note);
  }    
    # 1/3 unit? 
  if (($check3patterns[$level]) and
      ($qDur >= $unitDur[$level]/3)) {
    $note = &writePartUnit($note, $unitDur[$level]/3);  
    return &newNotationUnit($level+2,$note);
  }  
    # check for triplets, if allowed
  if ($allowTriplets[$level]) {
      # get a preview of next notes
    @next2=&watchNext2Notes;  
    $next2[0]=&fillBadRests($next2[0], $level);
    $next2[1]=&fillBadRests($next2[1], $level);
    #$next2[1]=&fillBadRests($next2[1], $level);
    
    print "lilyWrite: mynextNotes1 ".$next2[0]->info if ($debug);
    print "lilyWrite: mynextNotes2 ".$next2[1]->info if ($debug);
    print "lilyWrite: Tripletcheck: this:".$qDurTrip." - next:".$next2[0]->quantizedFullDur($smallestTriplet)." - next:".$next2[1]->quantizedDuration($smallestTriplet)."\n" if ($debug);
      # check for three equal triplet notes [1 1 x]
    if (($qDurTrip/$unitDur[$level] == 1/3 ) and
        ($next2[0]->quantizedFullDur($smallestTriplet)/$unitDur[$level] == 1/3 )) {
      print "lilyWrite: triplet found [1 1 1]\n" if ($debug);	
      #print LILY "\\times 2/3 {";
      $notes .= "\\times 2/3 {";
      $note = &writePartUnit($note, $unitDur[$level]/3,1);  
      $note = &getNextNote($note->fullDur);
      $note = &writePartUnit($note, $unitDur[$level]/3,1); 
      $note = &getNextNote($note->fullDur);
      if ($note->quantizedDuration($smallestAbsolute) >= $unitDur[$level]/3+$smallestAbsolute)
        { $slur=1; } else { $slur=0;}
      $note = &writePartUnit($note, $unitDur[$level]/3,1); 
      #print LILY "}";
      $notes .= "}";
      return $note
    }
      # check for long-short [2 1] (to be confused with swing feel at level 6)
    if (($qDurTrip/$unitDur[$level] == 2/3 ) and #($level !=6) and
        ($next2[0]->quantizedFullDur($smallestTriplet)/$unitDur[$level] >= 1/3 )) {
     unless ($level == $swingLevel) {	
      print "lilyWrite: triplet found [2 1]\n" if ($debug);	
      #print LILY "\\times 2/3 {";
      $notes .= "\\times 2/3 {";
      $note = &writePartUnit($note, $unitDur[$level]*2/3,1);  
      $note = &getNextNote($note->fullDur);
      if ($note->quantizedDuration($smallestAbsolute) >= $unitDur[$level]/3+$smallestAbsolute)
        { $slur=1; } else { $slur=0;}
      $note = &writePartUnit($note, $unitDur[$level]/3,1); 
      #print LILY "}";
      $notes .= "}";
      return $note
     }
     else {
        print "swing protect\n" if ($debug);
          #write swing feel quarters as equal quarters 
       	$note = &writePartUnit($note, $unitDur[$level]/2); 
	$note = &getNextNote($note->fullDur);
	return &writePartUnit($note, $unitDur[$level]/2); 
     }	
    }       
      # check for [1 2]
    if (($qDurTrip/$unitDur[$level] == 1/3 ) and #(0) and
        ($next2[0]->quantizedFullDur($smallestTriplet)/$unitDur[$level] >= 2/3 )) {
      print "lilyWrite: triplet found [1 2]\n" if ($debug);	
      #print LILY "\\times 2/3 {";
      $notes .= "\\times 2/3 {";
      $note = &writePartUnit($note, $unitDur[$level]/3,1);  
      $note = &getNextNote($note->fullDur);
      if ($note->quantizedDuration($smallestAbsolute) >= $unitDur[$level]*2/3+$smallestAbsolute)
        { $slur=1; } else { $slur=0;}
      $note = &writePartUnit($note, $unitDur[$level]*2/3,1); 
      #print LILY "}";
      $notes .= "}";
      return $note
    
    }       
  } 
    # is it 3/8?  (dotted in next even unit) ?
  if (!($check3patterns[$level]) and 
      ($qDur > $unitDur[$level]/3) ){
    #$note = &writePartUnit($note, $unitDur[$level]/2);  
    $note = &newNotationUnit($level+3,$note);
    return &newNotationUnit($level+3,$note);
  }    
  
    # check if note could only be a triplet in this level, but wasn't 
    # (possible if smallestTriplet<smallestNote)
    
  if ( (($unitDur[$level]==3*$smallestTriplet) or 
        ((defined $unitDur[$level-3]) and ($unitDur[$level-3]==3*$smallestTriplet))) and
      ($smallestTriplet < $smallestNote) and
      ($note->quantizedDuration($smallestTriplet) <= $smallestTriplet)) {
    # we would run too far, get next without output
    print "lilyWrite: level would run too deep! returning with next note.\n";
    if ($lastNoteProcessed) {
    	#fake note
    	$note = new melodyNote(	$note->onset,$unitDur[$level],0, 0, $note->channel, 1, $diff); #is a rest
	return &newNotationUnit($level,$note);} 
    $note = &getNextNote($note->fullDur);
    return &newNotationUnit($level,$note); #stay on this level (suboptimal)
  }

    # note is shorter than 1/2 and not 1/3 unit
  if ($allowTriplets[$level]) {  #means: if even level
    print "filling 1/4 - 3/4\n" if ($debug);  
    $note = &newNotationUnit($level+6,$note); #fill first quarter
    return &newNotationUnit($level+1,$note); #fill rest
  } else {
    print "filling 1/3 -2/3\n" if ($debug);  
    $note = &newNotationUnit($level+5,$note); #fill first third
    return &newNotationUnit($level+2,$note); #fill rest
  }  
}  
    
   
   
   

#################################
# look for unnecessary rests (at certain level only)
sub fillBadRests {
  my ($note, $level) =@_;
  if (($level>1) and ($note->quantizedFullDur($smallestNote) == $unitDur[$level] ) and
      ($note->quantizedDuration($smallestNote) > $unitDur[$level]/4 )) { 
    print "found unnecessary rest in note ".$note->info if ($debug);
    $note->{duration} = $note->{fullDur};
    #$note->{duration} = $unitDur[$level];
  }
  return $note;
}  

###########################################################
# note fills unit
sub writePartUnit {  
  my ($note,$myUnitDur,$isTriple) = @_;
  unless (defined $isTriple) { 
    $strech=1;
    $myAtom=$smallestNote;
  } else {
    $strech=3/2;
    $myAtom=$smallestTriplet;
  }  
  
        print "lilyWrite: filling unit ($myUnitDur)\n" if ($debug);
	
	if ($note->quantizedDuration($myAtom) >= $myUnitDur+$smallestNote)
	  { $slur=1; } else { $slur=0;}
  	&writeNote($note->MIDIpitch, $myUnitDur*$strech,$slur,$note->isaRest);
	  # create new note with what's left from this note
	$restNote = new melodyNote(	$note->quantizedOnset($myAtom)+$myUnitDur,
					$note->quantizedDuration($myAtom)-$myUnitDur,
					$note->MIDIpitch,
					$note->velocity,
					$note->channel,
					$note->isaRest,
					$note->fullDur-$myUnitDur
					);
          # and return it
	#print "lilyWrite: rest: ".$restNote->info if ($debug);
	return $restNote;
}



sub writeNote {
  $MIDIpitch=shift();
  $dur=shift();
  $slur=shift();
  $isaRest=shift();
  
  if ($isaRest) {
    #print LILY "r".&getNoteDur($dur,$timeNom,$timeDenom)." ";
    $notes .= "r".&getNoteDur($dur,$timeNom,$timeDenom) . " ";
    print "lilyWrite: wrote: r".&getNoteDur($dur,$timeNom,$timeDenom)." rrrrrrr($dur)rrrrrrrrrrrrrrr\n" if ($debug);
  }
  else {
    if ($slur == 1 ) { $endStr="~ "; }
    else { $endStr =" "; }
    
    #print LILY getLilyNote($MIDIpitch).&getNoteDur($dur,$timeNom,$timeDenom).$endStr;
    $notes .= getLilyNote($MIDIpitch).&getNoteDur($dur,$timeNom,$timeDenom).$endStr;
    print "lilyWrite: wrote: ".getLilyNote($MIDIpitch).&getNoteDur($dur,$timeNom,$timeDenom).$endStr." *******($dur)****************\n" if ($debug);
  }  
}
sub getNextNote {
  my $offset = shift();
  $currentNote++; #global var
  my $note = $aMelody[$currentNote];
  
  unless ((defined $note) and ($note->channel>0)) { 
      print "last note processed. lastOnset: $lastOnset\n" if ($debug);
      $note=new melodyNote($lastOnset, $barDur,0,0,144,1);
      $lastNoteProcessed=1;
  }

  $lastOnset=$note->onset;
    #check if note is valid
  #while (($note->channel != 144 ) and ($note->channel != 147 ))  { 
  #  &warning("Channel Problem, note $currentNote, channel ".$note->channel); 
  #  print "lilyWrite: note $currentNote has invalid channel; ".$note->info if ($debug);
  #  $currentNote++; #global var
  #  $note = $aMelody[$currentNote];
  #  unless (defined $note) { 
  #    print "last note processed\n" if ($debug);
  #    $note=new melodyNote($lastOnset, $barDur,0,0,144,1);
  #    $lastNoteProcessed=1;
  #  }
  #} 
  print "lilyWrite:getNextNote: Nr $currentNote RawData: ".$note->info if ($debug);

    # check if note is on a "rest helper channel"
  if (($note->channel == 176 ) or ($note->channel == 179 ))  {
    $note->{isaRest} = 1;
    $next=&watchNextNote;
    $note->{duration} = $next->onset-$note->onset;
  }  
    # compensate quantization offset
  $note->addToDur($offset); 
  $note->addToOnset(-$offset);
  
    #return if called from watchNextNote
  if (defined $saveCurrentNote) { return $note;}  
  #print "I've NOT been called by watchNextNote \n";
    #check following rests  
  my $nextNote = &watchNextNote;
  my $diff=$nextNote->quantizedOnset($smallestNote)-$note->quantizedOnset($smallestNote)-$note->quantizedDuration($smallestNote);
  print "lilyWrite:getNextNote: quant.offset: $offset / new quant.rest: $diff\n" if ($debug);
    #check if note overlasts the onset of following note
  if ($diff<0) { $note->addToDur($diff); }

  my $fullDur= $nextNote->onset($smallestNote)-$note->onset($smallestNote);
  $note->{fullDur} = $fullDur;
  
    # enlarge note if necessary and possible or skip if too small
  if ($note->quantizedDuration($smallestAbsolute) < $smallestAbsolute) 
  {
     if ($fullDur >= $smallestNote)
     {
       $note->addToDur($smallestNote-$note->duration);  
     }
     #elsif ($fullDur >0) {
     #    #give it a chance
     #  print "lilyWrite: giving short note $currentNote, (".$note->duration.") a chance -> ".($smallestNote/2)."\n" if ($debug);
     #  $note->{duration} = $smallestNote/2;
     #  $note->{fulldur} = $smallestNote/2;
     #}
     else { 	print "lilyWrite: SKIPPING note $currentNote, it's too short: offset: $offset ".$note->info if ($debug);
     		unless ($lastNoteProcessed) {$note = &getNextNote($offset+$fullDur); } #skip note  
		  else {
		    print "LilyWrite: - $myAtom - ".$note->info."\n";
		    $note = new melodyNote($note->quantizedOnset($myAtom),$barDur,$note->MIDIpitch,$note->velocity,$note->channel,	1,$barDur);
		    #$note->addToDur($barDur); 
		    print "lilyWrite: expanded last Note to get finished: ".$note->info if($debug)
		  }
	  }	  
  }
  
  return $note;
} 
sub watchNextNote {
  
  local $saveCurrentNote=$currentNote; #must be local to be readable in  getNextNote
  #print "calling get from watch\n";
  my $nextNote=&getNextNote(0);
  $currentNote = $saveCurrentNote;
  return $nextNote;

}  
sub watchNext2Notes {
  
  local $saveCurrentNote=$currentNote; #must be local to be readable in  getNextNote
  #print "calling get from watch2\n";
  $nextNotes[0]=&getNextNote(0);
  unless ($lastNoteProcessed) {  $nextNotes[1]=&getNextNote(0);}
  unless ($lastNoteProcessed) {  $nextNotes[2]=&getNextNote(0);}
  
  $currentNote = $saveCurrentNote;
    
  $nextNotes[0]->{fullDur} = $nextNotes[1]->onset($smallestNote)-$nextNotes[0]->onset($smallestNote);
  $nextNotes[1]->{fullDur} = $nextNotes[2]->onset($smallestNote)-$nextNotes[1]->onset($smallestNote);
  return @nextNotes;

}  

  
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
