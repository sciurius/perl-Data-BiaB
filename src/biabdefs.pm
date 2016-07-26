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
# $Id: biabdefs.pm 39 2007-09-08 13:03:45Z brenzi $
#
use Exporter;
use Switch;
@ISA = ('Exporter');
@EXPORT = ( 	'getChordRoot', 
		'getChordExt' ,
		'getMMAgroove',
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
  #&warning("bla");
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
    case 17 { $ext ="maug"; }
    case 18 { $ext ="mM7"; }  #bugfix Mauch
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
    case 34 { $ext ="m9b5"; }
    case 40 { $ext ="5"; } #
    case 56 { $ext ="7+"; }   #brenzi
    case 57 { $ext ="+"; }
    case 58 { $ext ="13+"; }
    case 64 { $ext ="7"; }
    case 65 { $ext ="13"; }
    case 66 { $ext ="7b13"; }
    case 67 { $ext ="7#11"; }
    case 70 { $ext ="9"; }
    case 70 { $ext ="9b13"; }
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
    case 146 { $ext ="7sus#9"; }
    case 163 { $ext ="7sus#5"; }
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
  print "biabdefs: basic Style $biabStyleNr =>groove: $mmaStyle $timeNom/$timeDenom\n" if ($debug);
  
  # basic style might be overridden by user style. Append more stlyes!
  
  if ($biabStyle =~ /TENDERLY/) { $mmaStyle="Waltz"; $timeNom=3; $timeDenom=4; }
  if ($biabStyle =~ /LRBOSLOW/) { $mmaStyle="BossaNova"; $timeNom=4; $timeDenom=4; }
  if ($biabStyle =~ /JEAN/) { $mmaStyle="Waltz"; $timeNom=3; $timeDenom=4; }
  print "biabdefs: chosen style: $mmaStyle $timeNom/$timeDenom\n" if ($debug);
  #unless($mmaStyle) {
  #    print "Didn't find apropriate style";
  #    $mmaStyle="Swing"; $timeNom=4; $timeDenom=4; }
    
  return ($mmaStyle,$timeNom,$timeDenom);
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
sub enableDebug {
  $debug=1;
}  
sub warning {
  open(WARN, ">>$WARNfile") or 
                  die " error: $WARNfile : $!\n";
  print WARN "biabdefs: ".shift()."\n";

  close WARN;
}  



return 1;
