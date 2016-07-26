package biabdefs;
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
##  This is a user-extendable file. Not all BiaB chords 
##  are being translated yet. Neither are Style substitutions 
##  for MMA. Any contributions and add-ons are welcome!
##
####################################################################
# CVS:
# $Revision: 1.10 $
#
use Exporter;
use Switch;
@ISA = ('Exporter');
@EXPORT = ( 	'getChordRoot', 
		'getChordExt' ,
		'getMMAgroove',
		'getNoteDur',
		'getBarDur',
		'quantize',
		'getKey',
		'useWarnFileName');

##################### Style translation
# for every basic biab style a mma style is proposed here

#		MMA style	BIAB stlye
@mmaStyleRef = ('Swing',	# Jazz Swing
		'findsomething',# Country 12/8
		'Country',	# Country 4/4
		'BossaNova',	# Bossa Nova
		'findsomething',# Ethnic
		'findsomething',# Blues Shuffle
		'Blues',	# Blues Straight
		'Waltz',	# Waltz
		'PopBallad',	# Pop Ballad
		'Rock',		# should be Rock Shuffle 
		'Rock',		# lite Rock
		'Rock',		# medium Rock
		'Rock',		# Heavy Rock
		'Rock',		# Miami Rock
		'findsomething',# Milly Pop
		'findsomething',# Funk
		'JazzWaltz',	# Jazz Waltz
		'Rhumba',	# Rhumba
		'findsomething',# Cha Cha
		'findsomething',# Bouncy
		'findsomething',# Irish
		'findsomething',# Pop Ballad 12/8
		'findsomething',# Country12/8 old
		'findsomething');# Reggae
@timeNomRef = (	4,	# Jazz Swing
		12,	# Country 12/8
		4,	# Country 4/4
		4,	# Bossa Nova
		4,	# Ethnic
		4,	# Blues Shuffle
		4,	# Blues Straight
		3,	# Waltz
		4,	# Pop Ballad
		4,	# should be Rock Shuffle 
		4,	# lite Rock
		4,	# medium Rock
		4,	# Heavy Rock
		4,	# Miami Rock
		4,	# Milly Pop
		4,	# Funk
		3,	# Jazz Waltz
		4,	# Rhumba
		4,	# Cha Cha
		4,	# Bouncy
		4,	# Irish
		12,	# Pop Ballad 12/8
		12,	# Country12/8 old
		4);	# Reggae
@timeDenomRef = (4,	# Jazz Swing
		8,	# Country 12/8
		4,	# Country 4/4
		4,	# Bossa Nova
		4,	# Ethnic
		4,	# Blues Shuffle
		4,	# Blues Straight
		4,	# Waltz
		4,	# Pop Ballad
		4,	# should be Rock Shuffle 
		4,	# lite Rock
		4,	# medium Rock
		4,	# Heavy Rock
		4,	# Miami Rock
		4,	# Milly Pop
		4,	# Funk
		4,	# Jazz Waltz
		4,	# Rhumba
		4,	# Cha Cha
		4,	# Bouncy
		4,	# Irish
		8,	# Pop Ballad 12/8
		8,	# Country12/8 old
		4);	# Reggae
				
		
local $smallestNote;
$lastOffset =0;

#############################################
sub getChordRoot {  
  my $nr=$_[0];
  ## converts the byte for chord root to a string
  @allRoots = ( '/','C','Db','D','Eb','E','F','Gb','G','Ab','A','Bb','B','C#','D#','F#','G#','A#');
  @allBassFlat = ('B','C','Db','D','Eb','E','F','Gb','G','Ab','A','Bb');
  @allBassSharp = ('B','C','C#','D','D#','E','F','F#','G','G#','A','A#');

  $root = $allRoots[$nr % 18];
  if ($nr>18) { 
    if ($root =~ /b/) {$bass=$allBassFlat[(int $nr / 18 + $nr % 18) % 12];} #flat slash
    else {$bass = $allBassSharp[(int $nr / 18 + $nr % 18) % 12];} #sharp slash
    $root = $root."/".$bass;
  }  
  return $root;
}  
sub getChordRootClean {
  $root = getChordRoot(shift);
  $root =~ s/m//;
  return $root;
}  
sub getKey {  
  my $nr=$_[0];
  &warning("bla");
  @allKeys = ( '/','C','Db','D','Eb','E','F','Gb','G','Ab','A','Bb','B','C#','D#','F#','G#','A#','Cm','Dbm','Dm','Ebm','Em','Fm','Gbm','Gm','Abm','Am','Bbm','Bm','C#m','D#m','F#m','G#m','A#m');
  return $allKeys[$nr];
}  
####################################
sub getChordExt {
  my $ext;
  switch($_[0]) {
    case (0 || '' || ' ') { $ext =""; }
    case 1 { $ext = ""; }
    case 2 { $ext = "maj"; }
    case 3 { $ext = "5b"; }
    case 4 { $ext = "aug"; }
    case 5 { $ext ="6"; }
    case 6 { $ext ="maj7"; }
    case 7 { $ext ="maj9"; }
    case 8 { $ext ="maj9#11"; }
    case 9 { $ext ="maj13#11"; }
    case 10 { $ext ="maj13"; }
    case 12 { $ext ="+"; }
    case 13 { $ext ="maj7#5"; }
    case 14 { $ext ="69"; }
    case 15 { $ext ="2"; }
    case 16 { $ext ="m"; }
    case 18 { $ext ="mMaj7"; }
    case 19 { $ext ="m7"; }
    case 20 { $ext ="m9"; }
    case 21 { $ext ="m11"; }
    case 22 { $ext ="m13"; }
    case 23 { $ext ="m6"; }
    case 24 { $ext ="m#5"; }
    case 25 { $ext ="m7#5"; }
    case 26 { $ext ="m69"; }
    case 32 { $ext ="m7b5"; }
    case 33 { $ext ="dim"; }
    case 40 { $ext ="5"; } #
    case 56 { $ext ="7+"; }   #brenzi
    case 57 { $ext ="+"; }
    case 64 { $ext ="7"; }
    case 65 { $ext ="13"; }
    case 66 { $ext ="7b13"; }
    case 67 { $ext ="7#11"; }
    case 70 { $ext ="9"; }
    case 73 { $ext ="9#11"; }
    case 74 { $ext ="13#11"; }
    case 76 { $ext ="7b9"; }
    case 77 { $ext ="13b9"; }
    case 79 { $ext ="7b9#11"; }
    case 82 { $ext ="7#9"; }
    case 83 { $ext ="13#9"; }
    case 84 { $ext ="7#9b13"; }
    case 85 { $ext ="9#11"; }
    case 88 { $ext ="7b5"; }
    case 89 { $ext ="13b5"; }
    case 91 { $ext ="9b5"; }
    case 93 { $ext ="7b5b9"; }
    case 96 { $ext ="7b5#9"; }
    case 99 { $ext ="7#5"; }
    case 103 { $ext ="9#5"; }
    case 105 { $ext ="7#5b9"; }
    case 109 { $ext ="7#5#9"; }
    case 113 { $ext ="7alt"; }
    case 128 { $ext ="7sus"; }
    case 129 { $ext ="13sus"; }
    case 134 { $ext ="11"; }
    case 140 { $ext ="7susb9"; }
    case 177 { $ext ="4"; }
    case 184 { $ext ="sus"; }
    else { $ext ="?($_[0])"; &warning("CRITICAL: don't know extension '".$_[0]."'");}
  }
  #print $_[0]." - ".$ext."\n";
  return $ext;
}  
sub getMMAgroove { # input: name of basic style nr.

  # to be extended
  $biabStyleNr = shift;
  $biabStyle = shift;
  
  $mmaStyle = $mmaStyleRef[$biabStyleNr-1];
  $timeNom = $timeNomRef[$biabStyleNr-1];
  $timeDenom = $timeDenomRef [$biabStyleNr-1];
  print "biabdefs: basic Style $biabStyleNr =>groove: $mmaStyle $timeNom/$timeDenom\n";
  
  # basic style might be overridden by user style. Append more stlyes!
  
  if ($biabStyle =~ /TENDERLY/) { $mmaStyle="Waltz"; $timeNom=3; $timeDenom=4; }
  if ($biabStyle =~ /LRBOSLOW/) { $mmaStyle="BossaNova"; $timeNom=4; $timeDenom=4; }
  if ($biabStyle =~ /JEAN/) { $mmaStyle="Waltz"; $timeNom=3; $timeDenom=4; }
  print "biabdefs: chosen style: $mmaStyle $timeNom/$timeDenom\n";
  #unless($mmaStyle) {
  #    print "Didn't find apropriate style";
  #    $mmaStyle="Swing"; $timeNom=4; $timeDenom=4; }
    
  return ($mmaStyle,$timeNom,$timeDenom);
}  





######################################
##   
sub getNoteDur { # needs MIDI duration plus tempoStyle  
  $midiDur 	= shift; 
  $timeNom 	= shift; 
  $timeDenom	= shift;
  my $isTrip = 0;
  #print "getNoteDur $midiDur in $barDur, \n";
  unless ($barDur) {$barDur = &getBarDur($timeNom,$timeDenom); }
  #smallest note 1/32
  #$midiDur = $barDur/32*&round( $midiDur /$barDur*32);
  #if ($midiDur==0) {return "invalid";}
 
  
  
  $lg = log($barRefDur/$midiDur)/log(2);

  $lgRest = $lg - int $lg; #Nachkommastellen
  

  #print "biabdefs:getNoteDur:". $lg. "+".$lgRest."\n";
  if ($lgRest == 0) { $noteDur = 2**$lg; }
  if (($lgRest > 0) and ($lgRest <= 0.2)) { $noteDur = 2**(int $lg + 1)."..";}  #double dotted 
  if (($lgRest > 0.2) and ($lgRest <= 0.56)) { $noteDur = 2**(int $lg + 1).".";}  #dotted
  if (($lgRest > 0.56) and ($lgRest <= 0.7)) { $noteDur = 2**(int $lg);}  #triplet (lilywrite should know this already)
  if ($lgRest > 0.7) { $noteDur = "invalid";}  
  	 
  #print $noteDur."\n";	
  return ($noteDur);    
}

sub getBarDur {
  $nom=shift;
  $denom=shift;

  if (($nom == 3) and ($denom == 4)) { $barDur = 360; $barRefDur = 480; $smallestNote = $barRefDur/8;}
  if (($nom == 4) and ($denom == 4)) { $barDur = 480; $barRefDur = 480; $smallestNote = $barRefDur/8;}
  if (($nom == 6) and ($denom == 8)) { $barDur = 320; $barRefDur = 480; $smallestNote = $barRefDur/8;} #todo
  print "biabdefs: $nom/$denom , barDur=$barDur\n";
  print "biabdefs: smallestNote = $smallestNote\n";
  
  # define forbidden single-note durations (they can't be written 
  # as one note; like a quarter plus a 16th -> no possible notation) 
  @forbiddenDurations = (600,540,510,495,300,270,255,150,135,75);
  $forbiddenDurRegexp="[".join("|",@forbiddenDurations)."]";
  
  $durTrip2=$barRefDur/3;
  $durTrip4=$barRefDur/6;
  $durTrip8=$barRefDur/12;
  $durTrip16=$barRefDur/24;
  
  
  
  return $barDur;
}  

sub quantize { 
  #quantization to $smallestNote (note & rest need to be calculated together ???)
  # only notes with single-note-printable durations may be returned for qDur!
  my $dur = shift;
  my $durToNext = shift;
  my $inbarCount = shift;
  my $isTrip = 0;
  my $trackTrip = shift;
  my $trackTripDur= shift;
  $dur = $dur + $lastOffset;
  $durToNext = $durToNext + $lastOffset;
  $qDurToNext = $smallestNote* &round($durToNext/$smallestNote);
  $qDur = $smallestNote* (int($dur/$smallestNote)+1);

  #always finish triplets
 if (0) { #no triplet support for release 0.3 
 #if ($trackTrip > 0) { 
   $qDur = $trackTripDur; 
   $qDurToNext = $trackTripDur; 
   $isTrip=1;
   print "biabdefs: filling triplet!\n";
 #}
 #else {
  if ($qDurToNext == 0) { $qDurToNext=$smallestNote; }
  if ($qDur>$qDurToNext) { $qDur=$qDurToNext;}
  if ($qDur == 0 ) { $qDur=$smallestNote; }

  # respect triplets => this is heavy shit!
  #$quantOffs=$qDur-$dur;
  $quantOffs=$qDurToNext-$durToNext;  #test
  $quantOffsToNext=$qDurToNext-$durToNext;
  #check dur
  if ( (abs($quantOffs)>abs($barRefDur/3-$dur)) and
  	 ($nom==4) and ($inbarCount - $trackTrip*$durTrip2 % 240 == 0) )
    			{ $qDur = $barRefDur/3; $isTrip=1; $trackTripDur=$barRefDur/3;
			  $qDurToNext = $qDur; #just a quick hack!
			} #1/2 triplet
  elsif ( (abs($quantOffs)>abs($barRefDur/6-$dur)) and
  	($inbarCount - $trackTrip*$durTrip4 % 120 == 0) )
    			{ $qDur = $barRefDur/6; $isTrip=1; $trackTripDur=$barRefDur/6;
			  $qDurToNext = $qDur; #just a quick hack!
			} #1/4 triplet
  elsif ( (abs($quantOffs)>abs($barRefDur/12-$dur)) and 
  	($smallestNote >= $barRefDur/8) and
	($inbarCount - $trackTrip*$durTrip8 % 60 == 0) )  
    			{ $qDur = $barRefDur/12; $isTrip=1; $trackTripDur=$barRefDur/12;
			  $qDurToNext = $qDur; #just a quick hack!
			} #1/8 triplet
  elsif ( (abs($quantOffs)>abs($barRefDur/24-$dur)) and 
  	($smallestNote >= $barRefDur/16) and
	($inbarCount - $trackTrip*$durTrip8 % 30 == 0) )
    			{ $qDur = $barRefDur/24; $isTrip=1; $trackTripDur=$barRefDur/24;
			  $qDurToNext = $qDur; #just a quick hack!
			} #1/16 triplet
  # check durToNext
#  if ( (abs($quantOffs)>abs($barRefDur/3-$durToNext)) and
#  	( (($nom==4) and ($inbarCount - $trackTrip*$durTrip2 % 240 == 0)) or
#	  (($nom==3) and ($inbarCount - $trackTrip*$durTrip2 == 0))) )
#    { $qDurToNext = $barRefDur/3; } #1/2 triplet
#  elsif ( (abs($quantOffs)>abs($barRefDur/6-$durToNext)) and
#  	($inbarCount - $trackTrip*$durTrip4 % 120 == 0) )
#    { $qDurToNext = $barRefDur/6; } #1/4 triplet
#  elsif ( (abs($quantOffs)>abs($barRefDur/12-$durToNext)) and 
#  	($smallestNote >= $barRefDur/8) and
#	($inbarCount - $trackTrip*$durTrip8 % 60 == 0) )  
#    { $qDurToNext = $barRefDur/12; } #1/8 triplet
#  elsif ( (abs($quantOffs)>abs($barRefDur/24-$durToNext)) and 
#  	($smallestNote >= $barRefDur/16) and
#	($inbarCount - $trackTrip*$durTrip8 % 30 == 0) )
#    { $qDurToNext = $barRefDur/24; } #1/16 triplet
 }    
    
    
  #if (abs($quantOffsToNext)>abs($barRefDur/3-$durToNext)) { $qDurToNext = $barRefDur/3; } #1/2 triplet
  #elsif (abs($quantOffsToNext)>abs($barRefDur/6-$durToNext)) { $qDurToNext = $barRefDur/6; } #1/4 triplet
  #elsif ((abs($quantOffsToNext)>abs($barRefDur/12-$durToNext)) and ($smallestNote >= $barRefDur/8)) { $qDurToNext = $barRefDur/12; } #1/8 triplet
  #elsif ((abs($quantOffsToNext)>abs($barRefDur/24-$durToNext)) and ($smallestNote >= $barRefDur/16)){ $qDurToNext = $barRefDur/24; } #1/16 triplet
  
  ## check that qDur is single-note-printable
  #if ($qDur =~ /^$forbiddenDurRegexp$/ ) {
  #  print "biabdefs: correcting a forbidden duration\n";
  #  $qDur = $qDur+&sgn($dur-$qDur)*$smallestNote;
  #}
  
  #test
  #if ($qDurToNext<$barDur/4) { $qDur=$qDurToNext;}
  $lastOffset = $durToNext - $qDurToNext;
  #print "biabdefs: quantize: dur=$dur/$durToNext => $qDur/$qDurToNext newOffset = $lastOffset\n";
  return ($qDur, $qDurToNext, $isTrip,$trackTripDur);
  
}
sub round {
  $number = shift;
  return int ($number + .5) * ($number <=> 0);
}  
sub sgn { # signum-function 
  $number = shift;
  return $number/abs($number);

}
sub useWarnFileName {
  # this function is only needed to pass the value to this module. Other ways?
  $WARNfile = shift;
}  
sub warning {
  open(WARN, ">>$WARNfile") or 
                  die " error: $WARNfile : $!\n";
  print WARN "biabdefs: ".shift()."\n";

  close WARN;
}  



return 1;
