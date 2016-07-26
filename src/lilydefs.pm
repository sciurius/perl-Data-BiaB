package lilydefs;
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
##  are being translated yet. Any contributions and add-ons are welcome!
##
####################################################################
# CVS:
# $Revision: 1.12 $
#

use Exporter;

$octOffset=0;
@ISA = ('Exporter');
@EXPORT = ( 	'getLilyNote',
		'getLilyKey',
		'getLilyExt',
		'getLilyNote',
		'getLilyNoteFromMMA',
		'getBarDur',
		'getNoteDur');


################################################
## notes for Lilypond
@sharpNotesLily = ('c', 'cis', 'd', 'dis', 'e', 'f', 'fis', 'g', 'gis', 'a', 'ais', 'b');
@flatNotesLily = ('c', 'des', 'd', 'ees', 'e', 'f', 'ges', 'g', 'aes', 'a', 'bes', 'b');
$acc = 0;
####################################
sub getLilyNote{  #needs a MIDI note number
  #print "lilydefs: acc=$acc\n";  
  
  if ($acc>0) { $thisStr = $sharpNotesLily[$_[0] % 12]; }
  else { $thisStr = $flatNotesLily[$_[0] % 12]; }

  my $thisOct = int ($_[0] / 12);
  my $thisOctRel = $thisOct - 4 + $octOffset;
    do {
      if ($thisOctRel<0) { $thisStr = $thisStr.","; $thisOctRel++; }
      if ($thisOctRel>0) { $thisStr = $thisStr."'"; $thisOctRel--; }
    } until ($thisOctRel==0);

  return $thisStr;
}  



sub getLilyNoteFromMMA { # convert a mma compatible note to Lily
  $note = $_[0];
  $note =~ s/([^\W0-9_])/\l$1/g; #lowercase
  $note =~ s/m//;   
  $note =~ s/([^\/])(b)/$1es/g;
  $note =~ s/([^\/])(#)/$1is/g;
  return $note;
}  

sub getLilyKey { 
  $note = &getLilyNoteFromMMA($_[0]);
  if ($_[0] =~ /m/) { $ext = 'minor';}
  else { $ext = 'major'; }
  #$acc is not returned, but saved globally
  if ($note =~ /^(g|d|a|e|b|fis)$/) { $acc = 1; } # sharp
  else {$acc = -1; } # flat
  # and C?
  print "lilyDefs: evaluating key:$note , using acc=$acc\n" if ($debug);
  return ($note, $ext);
}  



sub getLilyExt { # convert a mma compatible Extension to Lilypond
##################################################################
##  enter new definitions here
##  switch statement was too buggy, so I'm using if/elsif

  $ext=$_[0];
  if ($ext eq 'm7b5') 		{ $ext = 'm7.5-';}
  elsif ($ext eq '7b9')		{ $ext = '7.9-';}
  elsif ($ext eq '7b5')		{ $ext = '7.5-';}
  elsif ($ext eq 'maj9#11')	{ $ext = '7+.9.11+';}
  elsif ($ext eq '7#11') 	{ $ext = '7.11+';}
  elsif ($ext eq '69') 		{ $ext = '6.9';}
  elsif ($ext eq '13')		{ $ext = '11.13';} 
  elsif ($ext eq '+')		{ $ext = '5+';} 
  elsif ($ext eq 'mMaj7')		{ $ext = 'm7+';} 
  else { 
      $ext =~ s/([b|#])([5|9|11|13])/\.$2$1/g;
      $ext =~ s/b/-/g;
      $ext =~ s/#/+/g;
      #print "lilydefs: $ext\n";
  }  
  
  return $ext;
}
sub getBarDur {
  $nom=shift;
  $denom=shift;

  if (($nom == 3) and ($denom == 4)) { $barDur = 360; $barRefDur = 480; $smallestNote = $barRefDur/8;}
  if (($nom == 4) and ($denom == 4)) { $barDur = 480; $barRefDur = 480; $smallestNote = $barRefDur/8;}
  if (($nom == 6) and ($denom == 8)) { $barDur = 320; $barRefDur = 480; $smallestNote = $barRefDur/8;} #todo
  
  if ($aQuant) {$smallestNote = $barRefDur/$aQuant;}  #command line override
  $smallestTriplet = $smallestNote*2/3; 
  if (defined $aQuantTrip) {
    if ($aQuantTrip <= 1) { $smallestTriplet = 99*$barRefDur;}
    else {$smallestTriplet = $barRefDur/$aQuantTrip*2/3;}  #command line override
  }  
  print "lilydefs: $nom/$denom , barDur=$barDur\n" if ($debug);
  print "lilydefs: smallestNote = $smallestNote\n" if ($debug);
  
  # define forbidden single-note durations (they can't be written 
  # as one note; like a quarter plus a 16th -> no possible notation) 
  @forbiddenDurations = (600,540,510,495,300,270,255,150,135,75);
  $forbiddenDurRegexp="[".join("|",@forbiddenDurations)."]";
  
  $durTrip2=$barRefDur/3;
  $durTrip4=$barRefDur/6;
  $durTrip8=$barRefDur/12;
  $durTrip16=$barRefDur/24;
  
  
  
  return ($barDur, $barRefDur, $smallestNote, $smallestTriplet);
}  
sub overrideSmallestNote {
  $aQuant = shift();
}
sub overrideSmallestTriplet {
  $aQuantTrip = shift();
}
######################################
##   
sub getNoteDur { # needs MIDI duration plus tempoStyle  
  $midiDur 	= shift; 
  $timeNom 	= shift; 
  $timeDenom	= shift;
  my $isTrip = 0;
  #print "getNoteDur $midiDur in $barDur (refDur: $barRefDur), \n";
  if ($midiDur == 0) { return "invalid";} #this should never happen!!!
  unless ($barDur) {($barDur, @egal) = &getBarDur($timeNom,$timeDenom); }
  #smallest note 1/32
  #$midiDur = $barDur/32*&round( $midiDur /$barDur*32);
  #if ($midiDur==0) {return "invalid";}
  
  $lg = log($barRefDur/$midiDur)/log(2);

  $lgRest = $lg - int $lg; #Nachkommastellen
  

  #print "biabdefs:getNoteDur:". $lg. "+".$lgRest."\n";
  if ($lgRest == 0) { $noteDur = 2**$lg; }
  if (($lgRest > 0) and ($lgRest <= 0.2)) { $noteDur = 2**(int $lg + 1)."..";}  #double dotted 
  if (($lgRest > 0.2) and ($lgRest <= 0.56)) { $noteDur = 2**(int $lg + 1).".";}  #dotted
  #if (($lgRest > 0.56) and ($lgRest <= 0.7)) { $noteDur = 2**(int $lg);}  #triplet (lilywrite should know this already)
  #if ($lgRest > 0.7) { $noteDur = "invalid";}  
  if ($lgRest > 0.56) { $noteDur = "invalid";} 
  #print $noteDur."\n";	
  return ($noteDur);    
}

return 1;
