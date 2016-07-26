package mmawrite;
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
#####################################################################
##
##  This file provides a class for writing MMA files
##
#####################################################################
# 
# $Id: mmawrite.pm 36 2007-01-10 21:16:01Z brenzi $




##
## provides functions to read BIAB file format
##


sub new {
  my $this = shift;
  #parameters
  ($MMAfile, $title, $biabFileName, $biabStyleFile, $BPM, $key, $groove, $timeNom, $timeDenom,$version,$debug) = @_;
    
  my $class= ref($this) || $this;
  my $self = {};
  bless $self, $class;

  print "mmawrite: born. file to write: $MMAfile \n" if ($debug);
  #&writeMMA;
  
  return $self;
}

sub putChordNames {
  my $this = shift;
  $num=@_;
  @aChords = @_;
  #print "mmawrite: $num,$aChords[0] - $aChords[1]\n" if ($debug);
}
sub putStyleMap {
  my $this = shift;
  $num=@_;
  @aStyleMap = @_;
  
}
#################################
sub writeMMA {
  open(MMA, ">$MMAfile") or 
                    die " error: $MMAfile : $!\n"; 

  print MMA "// $title - BIAB style file $biabStyleFile. Key: $key. \n";
  print MMA "// This file has been converted from $biabFileName using biabconverter.pl V$version\n";
  print MMA "Tempo ".$BPM."\n";
  print MMA "Groove $groove \n\n";

  $beatsPerBar=$timeNom; # todo for 6/8
  
  for(my $i=1;$i<@aChords; $i=$i+4) {
    if ($aStyleMap[int $i/4]) {print MMA "// subStyle".$aStyleMap[int $i/4]."\n";}
    print MMA ((int $i/4)+1)."\t".join(' ',@aChords[$i..$i+$beatsPerBar-1])."\n";
  }
  close MMA;
  print "mmawrite: wrote file: $MMAfile\n";
}
 
return 1;

