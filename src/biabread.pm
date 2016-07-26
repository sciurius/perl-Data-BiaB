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
# $Id: biabread.pm 36 2007-01-10 21:16:01Z brenzi $
#

use Exporter;
use Switch;
use melodyNote;


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
#$foundMelody=0;
#$foundChords=0;
#$foundLyrics=0;


sub new {
  my ($class, $BIABfile, $WARN, $deb) = @_;
  $debug=$deb; #global!
  $WARNfile=$WARN; #global!
  #my $this = shift();
  #my $BIABfile = shift();
  #$WARNfile = shift();
  #$debug=shift();
  #my $styleMap = NULL;
  #my $class= ref($this) || $this;
  
  my $self = {
  	"BIABfile"	=> $BIABfile,
	"WARNfile"	=> $WARNfile,
	"title"		=> undef,
	"styleFile"	=> undef,
	"basicStyle"	=> undef,
	"BPM"		=> undef,
	"key"		=> undef,
	"aChords"	=> undef,
	"aStyleMap"	=> undef,
	"aExts"		=> undef,
	"aMelody"	=> undef,
#	"aMelodyWhen"	=> (),
#	"aMelodyChannel"=> (),
#	"aMelodyMIDInum"=> (),
#	"aMelodyVelocity"=> (),
#	"aMeldoyDuration"=> (),
	"foundChords"	=> 0,
	"foundMelody"	=> 0,
	"foundLyrics"	=> 0};
  bless $self, $class;
  print "biabread: born. file to read: $BIABfile \n" if ($debug);
  #&readBIABfile($BIABfile);
  $this=$self;
  &readBIABfile($this,$BIABfile);
  return $self;
 
}

sub title {my $this = shift();return $this->{title};}
sub styleFile {my $this = shift();return $this->{styleFile};}
sub basicStyle {my $this = shift();return $this->{basicStyle};}
sub BPM { my $this = shift();return $this->{BPM}; }
sub key {my $this = shift();return $this->{key}; }
sub aChords { my $this = shift();$tmp=$this->{aChords};return @$tmp; }
sub aStyleMap { my $this = shift();$tmp=$this->{aStyleMap}; return @$tmp; }
sub aExts {my $this = shift();$tmp=$this->{aExts};return @$tmp; }
sub aMelody { my $this = shift();$tmp= $this->{aMelody};return @$tmp; }
#sub aMelodyWhen {my $this = shift();return @this->{aMelodyWhen}; }
#sub aMelodyChannel {my $this = shift();return @this->{aMelodyChannel}; }
#sub aMelodyMIDInum {my $this = shift();return @this->{aMelodyMIDInum}; }
#sub aMelodyVelocity { my $this = shift();return @this->{aMelodyVelocity}; }
#sub aMelodyDuration { my $this = shift();return @this->{aMelodyDuration}; }
sub foundChords { my $this = shift();return $this->{foundChords}; }
sub foundMelody { my $this = shift();return $this->{foundMelody}; }
sub foundLyrics { my $this = shift();return $this->{foundLyrics}; }

sub readBIABfile { #needs a filename
########################################################
## read biab file
  my $this = shift;
  my $BIABfile = shift;
  
  open(INFILE,"< $BIABfile") or 
                  die "Datei $BIABfile konnte nicht geoeffnet werden: $!\n";

  binmode INFILE;
  # discard first byte
  $bytesread = read(*INFILE, $byte, 1);
  # length of title
  $bytesread = read(*INFILE, $byte, 1);
  $titleLen=ord $byte;
  print "biabread: title length: $titleLen \n" if ($debug);
  $bytesread = read(*INFILE, $bytes, $titleLen);
  $this->{title}=$bytes;
  print "biabread: title: ".$this->{title}."\n" if ($debug);

  #skip two bytes
  $bytesread = read(*INFILE, $bytes, 2);

  #read basic style
  $bytesread = read(*INFILE, $byte, 1);
  $this->{basicStyle} = ord $byte;
  print "biabread: basic style nr: ".$this->{basicStyle}." \n" if ($debug);

  #read Key
  $bytesread = read(*INFILE, $byte, 1);
  $this->{key} = ord $byte;
  
  print "biabread: keyNr: ".$this->{key}." \n" if ($debug);

  #read BPM
  $bytesread = read(*INFILE, $byte, 1);
  $this->{BPM} = ord $byte;
  print "biabread: BPM: ".$this->{BPM}." \n" if ($debug);

  #read Style Map
  #$bytesread = read(*INFILE, $byte, 256);
  #print $byte;
  $i=0;
  until($i>=256) {
    $bytesread = read(*INFILE, $byte, 1);
    if (ord $byte ==0) {
      $bytesread = read(*INFILE, $byte, 1);
      
      if (ord($byte)==0) {print "biabread: File (stylemap) has unknown format! no output\n"; 
  		&warning("ERROR: biabread: File (stylemap) has unknown format! no output");
		return;}
      $i = $i + ord $byte;
      #print "add ".ord($byte)."\n";
    }
    else { 
      print "biabread: stylemap entry at $i: ".ord($byte)."\n" if ($debug); 
      if ($i==0) {print "biabread: File (stylemap) has unknown format! no output\n"; 
  		&warning("ERROR: biabread: File (stylemap) has unknown format! no output");
		return;}
      $this->{aStyleMap}[$i-1] = ord $byte; 
      $i++;
    } 
  }    
  if ($i>256) {print "biabread: File (stylemap) has unknown format! no output\n"; 
  		&warning("ERROR: biabread: File (stylemap) has unknown format! no output");
		return;}
  print "biabread: StyleMap read \n" if ($debug);

  #read chord types
  $i=1;
  until ($i >= 1021) {
    $bytesread = read(*INFILE, $byte, 1); # 4*255 +1
    if (ord $byte ==0) {
      $bytesread = read(*INFILE, $byte, 1);
      $i = $i + ord $byte;
    }
    else {
      $this->{aExts}[$i]=ord $byte;
      $i++;
    }
  }
  #print "biabread: chordTypes read \n" if ($debug);

  #read chord names
  $i=1;
  until ($i >= 1022) {
    $bytesread = read(*INFILE, $byte, 1); # 4*255 +1
    if (ord $byte ==0) {
      $bytesread = read(*INFILE, $byte, 1);
      $i = $i + ord $byte;
    }
    else {
      $this->{aChords}[$i]=ord $byte;
      $i++;
    }
  }
  #print "biabread: chordNames read \n" if ($debug);
  $this->{foundChords} = 1;
  
  #read number of bars used
  $bytesread = read(*INFILE, $byte, 1); #start bar
  $bytesread = read(*INFILE, $byte, 1); $numberOfBars= ord $byte;
  $bytesread = read(*INFILE, $byte, 1); $numberOfRepeats=ord $byte;

  # for further computing, the file is read into an array
  
  $bytesread = read(*INFILE, $byte, 99999); 
  #print "$bytesread \n" if ($debug);

  if ($byte =~ /@STYarray/) {
  
    #print "biabread: anz Zeichen vor STY: ".length($`)."\n" if ($debug);
    @preStyle = split('',$`);
    
    ## style file names may only be 8 characters long 
    if (($byte =~ /$PRESTYa(.{1,8})\.STY/) || ($byte =~ /$PRESTYb(.{1,8})\.STY/) || ($byte =~ /$PRESTYc(.{1,8})\.STY/) || ($byte =~ /$PRESTYd(.{1,8})\.STY/) || ($byte =~ /$PRESTYe(.{1,8})\.STY/)) { #not sure if this always works => thats why I use the if
      #print "biabread: PRESTY found!\n" if ($debug);
      $this->{styleFile} = $+;
    } 
    else {
      &warning("MINOR WARNING: presty not found. Style file name may be ugly");
      $this->{styleFile} = join('',@preStyle[$#preStyle-9..$#preStyle-1]);
    }  
    print "biabread: Style File: ---".$this->{styleFile}."--- \n" if ($debug);
  }  else { &warning("WARNING: 'STY' not found => using basic style"); $this->{styleFile}="unknown";}
  if ($byte =~ /@FFDarray/) {
      #print "biabread: anz Zeichen vor FFD: ".length($`)."\n" if ($debug);
      @rest=split('',$');

      #read note count
      #$bytesread = read(*INFILE, $byte, 1);

      $noteCount = (ord $rest[0]) + 256* (ord $rest[1]);
      print "biabread: noteCount $noteCount \n" if ($debug);
  } else { &warning("WARNING: 'FFD' not found => don't know number of notes (guessing 999)"); $noteCount = 999;}
  if ($byte =~ /@ABCarray/) {
        #print "biabread: anz Zeichen vor A0 B0 C1: ".length($`)."\n" if ($debug);
  
        @rest=split('',$');
	$maxNotes=int length($')/12;
	#print "biabread: anz Zeichen verbleibend:$maxNotes\n" if ($debug);
	#@this->{aMelody} = ();
        # hier beginnen die noten
        for($i=0; $i<$noteCount; $i++) {
	  if ($i >= $maxNotes) { last; }
          $b=12*$i;
          $onset = ord($rest[$b]) + 256 * ord($rest[$b+1])+ 256*256* ord($rest[$b+2]) + 256*256*256* ord($rest[$b+3]);
          $channel = ord($rest[$b+4]);
          $MIDIpitch = ord($rest[$b+5]);
          $velocity = ord($rest[$b+6]);
          $duration = ord($rest[$b+8]) + 256* ord($rest[$b+9])	+ 256*256* ord($rest[$b+10]) + 256*256*256*ord($rest[$b+11]);
          #print "Note: at $aMelodyWhen[$i] MIDInum $aMelodyMIDInum[$i]\n"
	  $this->{aMelody}[$i]= new melodyNote($onset,$duration,$MIDIpitch,$velocity,$channel);
        }
	$this->{foundMelody} = 1;
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
