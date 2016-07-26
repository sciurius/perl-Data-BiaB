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
# $Revision: 1.5 $
#

use Exporter;
use Switch;
@ISA = ('Exporter');
@EXPORT = ( 	'getLilyNote',
		'getLilyKey',
		'getLilyExt',
		'getLilyNote',
		'getLilyNoteFromMMA');


################################################
## notes for Lilypond
@sharpNotesLily = ('c', 'cis', 'd', 'dis', 'e', 'f', 'fis', 'g', 'gis', 'a', 'ais', 'b');
@flatNotesLily = ('c', 'des', 'd', 'ees', 'e', 'f', 'ges', 'g', 'aes', 'a', 'bes', 'b');
$acc = 0;
####################################
sub getLilyNote{  #needs a MIDI note number
  print "lilydefs: acc=$acc\n";
  if ($acc>0) { return $sharpNotesLily[$_[0] % 12]; }
  else { return $flatNotesLily[$_[0] % 12]; }
}  

sub getLilyExt { # convert a mma compatible Extension to Lilypond
##################################################################
##  enter new definitions here
##

  $ext=$_[0];
  switch ($ext) {
    case 'm7b5' 	{ $ext = 'm7.5-';}
    case '7b9' 		{ $ext = '7.9-';}
    case '7b5' 		{ $ext = '7.5-';}
    case 'maj9#11' 	{ $ext = '7+.9.11+';}
    case '7#11' 	{ $ext = '7.11+';}
    else { 
      $ext =~ s/([b|#])([5|9|11|13])/\.$2$1/g;
      $ext =~ s/b/-/g;
      $ext =~ s/#/+/g;
      #print "lilydefs: $ext\n";
    }  
  }
  return $ext;
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
  if ($note =~ /^[g|d|a|e|h|fis]/) { $acc = 1; } # sharp
  else {$acc = -1; } # flat
  # and C?
  
  return ($note, $ext);
}  

return 1;
