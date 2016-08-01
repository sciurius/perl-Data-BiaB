use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Data::BiaB',
    AUTHOR              => 'Johan Vromans <jv@cpan.org>',
    VERSION_FROM        => 'lib/Data/BiaB.pm',
    ABSTRACT_FROM       => 'lib/Data/BiaB.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'Data::Hexify' => 0,
	'MIDI' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Data-BiaB-*' },
);
