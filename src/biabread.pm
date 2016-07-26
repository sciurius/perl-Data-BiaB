package biabread;
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
##   provides a class to read band-in-a-box file formats
##
# CVS:
# $Revision: 1.6 $
#

use Exporter;
use Switch;



@ISA = ('Exporter');
@EXPORT = ( 'readBIABfile','songTitle');

# I found different preambles before the style file name named a,b,c,d
$PRESTY = chr 66;
$PRESTYa = join('',chr 66,chr 8);
$PRESTYb = join('',chr 66,chr 9);
$PRESTYc = join('',chr 66,chr 10);
$PRESTYd = join('',chr 66,chr 11);
$PRESTYe = join('',chr 66,chr 12); #most usual
@STYarray=join('',chr 83,chr 84, chr 89);
@FFDarray=join('',chr 0, chr 255, chr 0 , chr 13);
@ABCarray=join('',chr 160, chr 176, chr 193); # A0 B0 C1
$foundMelody=0;
$foundChords=0;
$foundLyrics=0;


sub new {
  my $this = shift;
  my $BIABfile = shift;
  $WARNfile = shift;
  my $class= ref($this) || $this;
  my $self = {};
  bless $self, $class;
  print "biabread: born. file to read: $BIABfile \n";
  &readBIABfile($BIABfile);
  return $self;
 
}

sub title {$title;}
sub styleFile {$styleFile;}
sub basicStyle {$basicStyle;}
sub BPM { $BPM; }
sub key { $key; }
sub aChords { @aChords; }
sub aExts { @aExts; }
sub aMelodyWhen { @aMelodyWhen; }
sub aMelodyChannel { @aMelodyChannel; }
sub aMelodyMIDInum { @aMelodyMIDInum; }
sub aMelodyVelocity { @aMelodyVelocity; }
sub aMelodyDuration { @aMelodyDuration; }
sub foundChords { $foundChords; }
sub foundMelody { $foundMelody; }
sub foundLyrics { $foundLyrics; }

sub readBIABfile { #needs a filename
########################################################
## read biab file
  #my $this = shift;
  my $BIABfile = shift;
  
  open(INFILE,"< $BIABfile") or 
                  die "Datei $BIABfile konnte nicht geoeffnet werden: $!\n";

  binmode INFILE;

  # discard first byte
  $bytesread = read(*INFILE, $byte, 1);
  # length of title
  $bytesread = read(*INFILE, $byte, 1);
  $titleLen=ord $byte;
  print "biabread: title length: $titleLen \n";
  $bytesread = read(*INFILE, $bytes, $titleLen);
  $title=$bytes;
  print "biabread: title: ".$title."\n";

  #skip two bytes
  $bytesread = read(*INFILE, $bytes, 2);

  #read basic style
  $bytesread = read(*INFILE, $byte, 1);
  $basicStyle = ord $byte;
  print "biabread: basic style nr: $basicStyle \n";

  #read Key
  $bytesread = read(*INFILE, $byte, 1);
  $key = ord $byte;
  
  print "biabread: keyNr: $key \n";

  #read BPM
  $bytesread = read(*INFILE, $byte, 1);
  $BPM = ord $byte;
  print "biabread: BPM: $BPM \n";

  #read Style Map
  $i=0;
  until($i==256) {
    $bytesread = read(*INFILE, $byte, 1);
    if (ord $byte ==0) {
      $bytesread = read(*INFILE, $byte, 1);
      $i = $i + ord $byte;
    }
    else { $i++ } #forget about style changes....to be implemented later
  }    
  #print "biabread: StyleMap read \n";

  #read chord types
  $i=1;
  until ($i >= 1021) {
    $bytesread = read(*INFILE, $byte, 1); # 4*255 +1
    if (ord $byte ==0) {
      $bytesread = read(*INFILE, $byte, 1);
      $i = $i + ord $byte;
    }
    else {
      $aExts[$i]=ord $byte;
      $i++;
    }
  }
  #print "biabread: chordTypes read \n";

  #read chord names
  $i=1;
  until ($i >= 1022) {
    $bytesread = read(*INFILE, $byte, 1); # 4*255 +1
    if (ord $byte ==0) {
      $bytesread = read(*INFILE, $byte, 1);
      $i = $i + ord $byte;
    }
    else {
      $aChords[$i]=ord $byte;
      $i++;
    }
  }
  #print "biabread: chordNames read \n";
  $foundChords = 1;
  
  #read number of bars used
  $bytesread = read(*INFILE, $byte, 1); #start bar
  $bytesread = read(*INFILE, $byte, 1); $numberOfBars= ord $byte;
  $bytesread = read(*INFILE, $byte, 1); $numberOfRepeats=ord $byte;

  # for further computing, the file is read into an array
  
  $bytesread = read(*INFILE, $byte, 99999); 
  #print "$bytesread \n";

  if ($byte =~ /@STYarray/) {
  
    #print "biabread: anz Zeichen vor STY: ".length($`)."\n";
    @preStyle = split('',$`);
    
    ## style file names may only be 8 characters long 
    if (($byte =~ /$PRESTYa(.{1,8})\.STY/) || ($byte =~ /$PRESTYb(.{1,8})\.STY/) || ($byte =~ /$PRESTYc(.{1,8})\.STY/) || ($byte =~ /$PRESTYd(.{1,8})\.STY/) || ($byte =~ /$PRESTYe(.{1,8})\.STY/)) { #not sure if this always works => thats why I use the if
      #print "biabread: PRESTY found!\n";
      $styleFile = $+;
    } 
    else {
      &warning("MINOR WARNING: presty not found. Style file name may be ugly");
      $styleFile = join('',@preStyle[$#preStyle-9..$#preStyle-1]);
    }  
    print "biabread: Style File: ---$styleFile--- \n";
  }  else { &warning("WARNING: 'STY' not found => using basic style"); $styleFile="unknown";}
  if ($byte =~ /@FFDarray/) {
      #print "biabread: anz Zeichen vor FFD: ".length($`)."\n";
      @rest=split('',$');

      #read note count
      #$bytesread = read(*INFILE, $byte, 1);

      $noteCount = (ord $rest[0]) + 256* (ord $rest[1]);
      print "biabread: noteCount $noteCount \n";
  } else { &warning("WARNING: 'FFD' not found => don't know number of notes (guessing 999)"); $noteCount = 999;}
  if ($byte =~ /@ABCarray/) {
        #print "biabread: anz Zeichen vor A0 B0 C1: ".length($`)."\n";
  
        @rest=split('',$');
	$maxNotes=int length($')/12;
	#print "biabread: anz Zeichen verbleibend:$maxNotes\n";
	@melody = ();
        # hier beginnen die noten
        for($i=0; $i<$noteCount; $i++) {
	  if ($i >= $maxNotes) { last; }
          $b=12*$i;
          $aMelodyWhen[$i] = ord($rest[$b]) + 256 * ord($rest[$b+1])+ 256*256* ord($rest[$b+2]) + 256*256*256* ord($rest[$b+3]);
          $aMelodyChannel[$i] = ord($rest[$b+4]);
          $aMelodyMIDInum[$i] = ord($rest[$b+5]);
          $aMelodyVelocity[$i] = ord($rest[$b+6]);
          $aMelodyDuration[$i] = ord($rest[$b+8]) + 256* ord($rest[$b+9])	+ 256*256* ord($rest[$b+10]) + 256*256*256*ord($rest[$b+11]);
          #print "Note: at $aMelodyWhen[$i] MIDInum $aMelodyMIDInum[$i]\n"
        }
	$foundMelody = 1;
  } else { &warning("WARNING: 'A0 B0 C1' not found => no melody");}
    
  close INFILE;

}
sub warning {
  open(WARN, ">>$WARNfile") or 
                  die " error: $WARNfile : $!\n";
  print WARN "biabread: ".shift()."\n";

  close WARN;
}  

return 1;
