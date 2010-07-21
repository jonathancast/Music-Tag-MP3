package Music::Tag::MP3;
use strict;
use warnings;

our $VERSION = 0.32;

# Copyright (c) 2007 Edward Allen III. Some rights reserved.

#
# You may distribute under the terms of either the GNU General Public
# License or the Artistic License, as specified in the README file.
#

=pod

=for changes stop

=head1 NAME

Music::Tag::MP3 - Plugin module for Music::Tag to get information from id3 tags

=for readme stop

=head1 SYNOPSIS

	use Music::Tag

	my $info = Music::Tag->new($filename, { quiet => 1 }, "MP3");
	$info->get_info();
   
	print "Artist is ", $info->artist;

=for readme continue

=head1 DESCRIPTION

Music::Tag::MP3 is used to read id3 tag information. It uses MP3::Tag to read id3v2 and id3 tags from mp3 files. As such, it's limitations are the same as MP3::Tag. It does not write id3v2.4 tags, causing it to have some trouble with unicode.

=begin readme

=head1 INSTALLATION

To install this module type the following:

   perl Makefile.PL
   make
   make test
   make install

=head1 DEPENDENCIES

This module requires these other modules and libraries:

   Muisc::Tag
   MP3::Tag
   MP3::Info

Do not install an older version of MP3::Tag. 

=head1 NOTE ON ID3v2.4 TAGS

There seems to be a bug with MP3::Tag::ID3v2 0.9709. To use ID3v2.4 tags,
download MP3::Tag from CPAN and apply the following patch:

   patches/MP3-Tag-0.9709.ID3v2.4.patch

To do this change directory to the MP3::Tag download directory and type

   patch -p1 < ../Music-Tag-MP3/patches/MP3-Tag-0.9709.ID3v2.4.patch

Then install as normal

   perl Makefile.PL
   make && make test
   make install

=head1 NOTE ON GAPLESS INFO

This is used for a yet-to-be-maybe-someday released ipod library.  It collects
the required gapless info.  There is a patch to MP3-Info that should be applied
ONLY if you are interested in experimenting with this.  

=head1 TEST FILES

Are based on the sample file for Audio::M4P.  For testing only.
   
=end readme

=for readme stop

=head1 REQUIRED DATA VALUES

No values are required (except filename, which is usually provided on object creation).

=head1 SET DATA VALUES


=cut

use MP3::Tag;
use MP3::Info;
use base qw(Music::Tag::Generic);

sub default_options {
    { apic_cover => 1, };
}

sub _decode_uni {
    my $in = shift;
	my $c = unpack( "U", substr( $in, 0, 1 ) );
    if ( ($c) && ($c == 255 )) {
		$in = decode("UTF-16LE", $in); 
		#$in =~ s/^[^A-Za-z0-9]*//;
		#$in =~ s/ \/ //g;
    }
    return $in;
}

sub mp3 {
	my $self = shift;
	unless ((exists $self->{'_mp3'}) && (ref $self->{'_mp3'})) {
		if ($self->info->filename) {
			$self->{'_mp3'} = MP3::Tag->new($self->info->filename);
		}
		else {
			return undef;
		}
	}
	return $self->{'_mp3'};
}

sub _auto_methods_map {
    return  {
		bitrate => { method => 'bitrate_kbps', decode_uni => 0, inspect => 0, readonly => 1},
		duration => { method => 'total_millisecs_int', decode_uni => 0, inspect => 0, readonly => 1},
		frequency => { method => 'frequency_Hz', decode_uni => 0, inspect => 0, readonly => 1},
		stereo => { method => 'is_stereo', decode_uni => 0, inspect => 0, readonly => 1},
		bytes => { method => 'size_bytes', decode_uni => 0, inspect => 0, readonly => 1},
		frames => { method => 'frames', decode_uni => 0, inspect => 0, readonly => 1},
		'framesize' => { method => 'frame_len', decode_uni => 0, inspect => 0, readonly => 1},
		vbr => { method => 'is_vbr', decode_uni => 0, inspect => 0, readonly => 1},
		title  => {method => 'title', decode_uni => 1, inspect => 1},
		artist  => {method => 'artist', decode_uni => 1, inspect => 1},
		album  => {method => 'album', decode_uni => 1, inspect => 1},
		comment  => {method => 'comment', decode_uni => 1, inspect => 1},
		year  => {method => 'year', decode_uni => 1, inspect => 1},
		genre  => {method => 'genre', decode_uni => 1, inspect => 1}, 
		tracknum  => {method => 'track', decode_uni => 0, inspect => 0}, 
		composer  => {method => 'composer', decode_uni => 0, inspect => 0, readonly => 1} ,
		performer  => {method => 'performer', decode_uni => 1, inspect => 0, readonly => 1}, 
	};
}

sub _id3v2_frame_map {
    return {
		discnum => [{ frame => 'TPOS' , description => ''}],
		label =>   [{ frame => 'TPUB' , description => ''}],
		sortname => [{ frame => 'XSOP', description => ''},
					 { frame => 'TPE1', description => ''}],
        mb_trackid => [{frame => 'TXXX', description => 'MusicBrainz Track Id'},
					   { frame => 'UFID', field => '_Data', description => ''}],
        asin => [{frame => 'TXXX', description => 'ASIN'} ],
        sortname => [{frame => 'TXXX', description => 'Sortname'} ],
        albumartist_sortname => [{frame => 'TXXX', description => 'MusicBrainz Album Artist Sortname'} ,
							 	 {frame => 'TXXX', description => 'ALBUMARTISTSORT'} ],
        albumartist => [{frame => 'TXXX', description => 'MusicBrainz Album Artist'} ] ,
        countrycode => [{frame => 'TXXX', description => 'MusicBrainz Album Release Country'} ],
        mb_artistid => [{frame => 'TXXX', description => 'MusicBrainz Artist Id'} ],
        mb_albumid => [{frame => 'TXXX', description => 'MusicBrainz Album Id'} ],
        album_type => [{frame => 'TXXX', description => 'MusicBrainz Album Status'} ],
        artist_type => [{frame => 'TXXX', description => 'MusicBrainz Artist Type'} ],
        mip_puid => [{frame => 'TXXX', description => 'MusicIP PUID'} ],
        artist_start => [{frame => 'TXXX', description => 'Artist Begins'} ],
        artist_end => [{frame => 'TXXX', description => 'Artist Ends'} ],
        ean => [{frame => 'TXXX', description => 'EAN/UPC'} ],
        mip_puid => [{frame => 'TXXX', description => 'MusicMagic Data'} ],
        mip_fingerprint => [{frame => 'TXXX', description => 'MusicMagic Fingerprint'} ],
	};
}

sub get_tag {
    my $self     = shift;
    return unless ( $self->mp3 );
    $self->mp3->config( id3v2_mergepadding => 0 );
	$self->mp3->config( autoinfo => "ID3v2", "ID3v1");
    return unless $self->mp3;


    $self->info->datamethods('filetype');
    $self->info->datamethods('mip_fingerprint');
    $self->info->filetype('mp3');

    $self->mp3->get_tags;
=over 4

=item mp3 file info added:

   Currently this includes bitrate, duration, frequency, stereo, bytes, codec, frames, vbr, 
=cut


    if ( $self->mp3->mpeg_version() ) {
        $self->info->codec(   "MPEG Version "
                            . $self->mp3->mpeg_version()
                            . " Layer "
                            . $self->mp3->mpeg_layer() );
    }



=item auto tag info added:

title, artist, album, track, comment, year, genre, track, totaltracks, disc, totaldiscs, composer, and performer

=cut

	my $mt_to_mp3 = $self->_auto_methods_map(); 
#	eval {
		while (my ($mt,$mp3) = each %{$mt_to_mp3}) {
			my $method = $mp3->{method};
			$self->info->$mt($self->mp3->$method);
#			$self->info->$mt( $mp3->{decode} ? 
#				_decode_uni($self->mp3->$method) : 
#				$self->mp3->$method);

#			if (($mp3->{inspect}) && (exists $self->mp3->{ID3v2})) {
#				if ( ! $self->mp3->$method eq $self->mp3->{ID3v2}->$method) {
#					$self->info->changed(1);
#					$self->status("ID3v2 tag does not match auto generated for field ".$mp3->{method});
#				}
#			}
		}
#	};
#    warn $@ if $@;

=pod

=item id3v2 tag info added:

label, releasedate, lyrics (using USLT), encoder (using TFLT),  and picture (using apic). 

=item The following information is gathered from the ID3v2 tag using custom tags

TXXX[ASIN] asin
TXXX[Sortname] sortname
TXXX[MusicBrainz Album Artist Sortname] albumartist_sortname
TXXX[MusicBrainz Album Artist] albumartist
TXXX[ALBUMARTISTSORT] albumartist
TXXX[MusicBrainz Album Release Country] countrycode
TXXX[MusicBrainz Artist Id] mb_artistid
TXXX[MusicBrainz Album Id] mb_albumid
TXXX[MusicBrainz Album Status] album_type
TXXX[MusicBrainz Artist Type] artist_type
TXXX[MusicIP PUID] mip_puid
TXXX[Artist Begins] artist_start
TXXX[Artist Ends] artist_end
TXXX[EAN/UPC] ean
TXXX[MusicMagic Data] mip_puid
TXXX[MusicMagic Fingerprint] mip_fingerprint

=cut

	my $frame_map = $self->_id3v2_frame_map();

    if ( exists $self->mp3->{ID3v2} ) {
		while (my ($mt, $mp3d) = each %{$frame_map}) {
			foreach my $mp3 (@{$mp3d}) {
				my $t = $self->mp3->{ID3v2}->frame_select( $mp3->{frame}, $mp3->{description}, [''] );
				if (ref $t) {
				}
				if ((ref $t) && (exists $mp3->{field})) {
					$self->info->$mt($t->{$mp3->{field}});	
					last;
				}
				elsif($t) {
					$self->info->$mt($t);
					last;
				}
			}
		}
		
        my $day = $self->mp3->{ID3v2}->get_frame('TDAT') || "";
        if ( ( $day =~ /(\d\d)(\d\d)/ ) && ( $self->info->year ) ) {
			my $releasedate = $self->info->year . "-" . $1 . "-" . $2 ;
			my $time = $self->mp3->{ID3v2}->get_frame('TIME') || "";
			if ($time =~ /(\d\d)(\d\d)/) {
				$releasedate .= " ". $1 . ":" . $2;
			}
            $self->info->releasetime($releasedate); 
        }

        my $lyrics = $self->mp3->{ID3v2}->get_frame('USLT');
        if ( ref $lyrics ) {
            $self->info->lyrics( $lyrics->{Text} );
        }
        if ( $self->mp3->{ID3v2}->get_frame('TENC') ) {
            $self->info->encoded_by( $self->mp3->{ID3v2}->get_frame('TENC') );
        }

        if ( ref $self->mp3->{ID3v2}->get_frame('USER') ) {
            if ( $self->mp3->{ID3v2}->get_frame('USER')->{Language} eq "Cop" ) {
                $self->status("Emusic mistagged file found");
                $self->info->encoded_by('emusic');
            }
        }

        if (    ( not $self->options->{ignore_apic} )
             && ( $self->mp3->{ID3v2}->frame_select('APIC','','Cover (front)') ) 
		     && ( not $self->info->picture_exists)) {
            $self->info->picture( $self->mp3->{ID3v2}->get_frame('APIC', '', 'Cover (front)') );
        }

		if ($self->info->comment =~ /^Amazon.com/i) {
			$self->info->encoded_by('Amazon.com');
		}
		if ($self->info->comment =~ /^cdbaby.com/i) {
			$self->info->encoded_by('cdbaby.com');
		}

    }

=pod

=item Some data in the LAME header is obtained from MP3::Info (requires MP3::Info 1.2.3)

pregap
postgap

=cut

   $self->{mp3info} = MP3::Info::get_mp3info($self->info->filename);
   if ($self->{mp3info}->{LAME}) {
	   $self->info->pregap($self->{mp3info}->{LAME}->{start_delay});
	   $self->info->postgap($self->{mp3info}->{LAME}->{end_padding});
	   if ($self->{mp3info}->{LAME}->{encoder_version}) {
	       $self->info->encoder($self->{mp3info}->{LAME}->{encoder_version});
	   }
    }

    return $self;
}

sub calculate_gapless {
	my $self = shift;
	my $file = shift;
	my $gap = {};
	require MP3::Info;
    require Math::Int64;
	$MP3::Info::get_framelengths = 1;
	my $info = MP3::Info::get_mp3info($file);
	if (($info) && ($info->{LAME}->{end_padding}))  {
		$gap->{gaplesstrackflag} = 1;
		$gap->{pregap} = $info->{LAME}->{start_delay};
		$gap->{postgap} = $info->{LAME}->{end_padding};
		$gap->{samplecount} = $info->{FRAME_SIZE} * scalar($info->{FRAME_LENGTHS}) - $gap->{pregap} - $gap->{postgap};
		my $finaleight = 0;
		for (my $n = 1; $n <= 8; $n++) {
			$finaleight += $info->{FRAME_LENGTHS}->[-1 * $n];
		}
		$gap->{gaplessdata} = Math::Int64::uint64($info->{SIZE}) - Math::Int64::uint64($finaleight);
	}
	return $gap;
}

sub strip_tag {
    my $self = shift;
    $self->status("Stripping current tags");
    if ( exists $self->mp3->{ID3v2} ) {
        $self->mp3->{ID3v2}->remove_tag;
        $self->mp3->{ID3v2}->write_tag;
    }
    if ( exists $self->mp3->{ID3v1} ) {
        $self->mp3->{ID3v1}->remove_tag;
    }
    return $self;
}

sub set_tag {
    my $self     = shift;
    my $filename = $self->info->filename;
    $self->status("Updating MP3");

	my $mt_to_mp3 = $self->_auto_methods_map(); 
	while (my ($mt,$mp3) = each %{$mt_to_mp3}) {
		my $method = $mp3->{method}.'_set';
		next if ((exists $mp3->{readonly}) && ($mp3->{readonly}));
		$self->mp3->$method($self->info->$mt, 1);
	}

    my $id3v1;
    my $id3v2;
    if ( $self->mp3->{ID3v2} ) {
        $id3v2 = $self->mp3->{ID3v2};
    }
    else {
        $id3v2 = $self->mp3->new_tag("ID3v2");
    }
    if ( $self->mp3->{ID3v1} ) {
        $id3v1 = $self->mp3->{ID3v1};
    }
    else {
        $id3v1 = $self->mp3->new_tag("ID3v1");
    }

    $self->status("Writing ID3v2 Tag");
<<<<<<< HEAD

	my $frame_map = $self->_id3v2_frame_map();

	while (my ($mt, $mp3d) = each %{$frame_map}) {
		my $mp3 = $mp3d->[0];
		next if ((exists $mp3->{readonly}) && ($mp3->{readonly}));
		if ($self->info->$mt) {
			my $val = $self->info->$mt;
			if ((not ref $val) && (exists $mp3->{field}) && ($mp3->{field})) {
				$val = { $mp3->{field} => $self->info->$mt };
			}
			else {
				$id3v2->frame_select( $mp3->{frame}, $mp3->{description}, [''], $val );
			}
		}
	}
=======
    ($self->info->title) && $id3v2->title( $self->info->title );
    ($self->info->artist) && $id3v2->artist( $self->info->artist );
    ($self->info->album) && $id3v2->album( $self->info->album );
    ($self->info->year) && $id3v2->year( $self->info->year );
    ($self->info->track) && $id3v2->track( $self->info->tracknum );
    ($self->info->genre) && $id3v2->genre( $self->info->genre );
	if ($self->info->disc) {
		$id3v2->remove_frame('TPOS');
		$id3v2->add_frame( 'TPOS', 0, $self->info->disc );
	}
	if ($self->info->label) {
		$id3v2->remove_frame('TPUB');
		$id3v2->add_frame( 'TPUB', 0, $self->info->label );
	}
#	if ($self->info->url) {
#		$id3v2->remove_frame('WCOM');
#		$id3v2->add_frame( 'WCOM', 0, _url_encode( $self->info->url ) );
#	}
>>>>>>> 542b70edaa97f88e4ef99c33432136bda5d2fd56

	if ($self->info->lyrics) {
		$id3v2->remove_frame('USLT');
		$id3v2->add_frame( 'USLT', 0, "ENG", "Lyrics", $self->info->lyrics );
	}
    if ( $self->info->encoded_by ) {
        $id3v2->remove_frame('TENC');
        $id3v2->add_frame( 'TENC', 0, $self->info->encoded_by );
    }
					
    if (($self->info->releasedate) && ( $self->info->releasetime =~ /(\d\d\d\d)-?(\d\d)?-?(\d\d)? ?(\d\d)?:?(\d\d)?/ )) {
		my $day = sprintf("%02d%02d", $2 || 0, $3 || 0);
		my $time = sprintf("%02d%02d", $4 || 0, $5 || 0);
        $id3v2->remove_frame('TDAT');
        $id3v2->add_frame( 'TDAT', 0, $day );
        $id3v2->remove_frame('TIME');
        $id3v2->add_frame( 'TIME', 0, $time );
    }
    if (! $self->options->{ignore_apic} ) {
        $id3v2->remove_frame('APIC');
        if ( ( $self->options->{apic_cover} ) && ( $self->info->picture ) ) {
            $self->status("Saving Cover to APIC frame");
            $id3v2->add_frame( 'APIC', _apic_encode( $self->info->picture ) );
        }
    }
    eval { $id3v2->write_tag(); };
    eval { $id3v1->write_tag(); };
    return $self;
}

sub close {
    my $self = shift;
	if ($self->mp3) {
		$self->mp3->close();
		$self->mp3->{ID3v2} = undef;
		$self->mp3->{ID3v1} = undef;
		$self->{'_mp3'}          = undef;
	}
}

sub _apic_encode {
    my $code = shift;
    return ( 0, $code->{"MIME type"}, $code->{"Picture Type"} || 'Cover (front)', $code->{"Description"}, $code->{_Data} );
}

sub _url_encode {
    my $url = shift;
    return ($url);
}

=back

=head1 METHODS

=over 4

=item default_options

Returns the default options for the plugin.  

=item set_tag

Save object back to ID3v2.3 and ID3v1 tag.

=item get_tag

Load information from ID3v2 and ID3v1 tags.

=item strip_tag

Remove the tag from the file.

=item close

Close the file and destroy the MP3::Tag object.

=item mp3

Returns the MP3::Tag object

=item calculate_gapless

Calculate gapless playback information.  Requires patched version of MP3::Info and Math::Int64 to work.

=back

=head1 OPTIONS

=over 4

=item apic_cover

Set to false to disable writing picture to tag.  True by default.

=item ignore_apic

Ignore embeded picture.

=back

=head1 BUGS

ID3v2.4 is not read reliablly and can't be writen.  Apic cover is unreliable in older versions of MP3::Tag.  

=head1 CHANGES

=for changes continue

=over 4

=item Release Name: 0.32

=over 4

=item *

Changed to TXXX:ALBUMARTISTSORT from TXXX:MusicBrainz Album Artist Sortname (will still read both).  This is to partially address 54571.

=back

=item Release Name: 0.31

=over 4

=item *

Added support for EAN/UPC TXXX tag, and for reading and writing Music Magic fingerprints and data (puid).

=back

=item Release Name: 0.30

=over 4

=item * 

Documentation Changes

=back

=item Release Name: 0.29

=over 4

=item * 

Kwalitee fixes

=item *

Added Music::Info patch and explanation about gapless data

=back

=begin changes

=item Release Name: 0.28

=over 4

=item *

Split from Music::Tag

=back

=end changes

=back

=for changes stop

=head1 SEE ALSO INCLUDED


=head1 SEE ALSO

L<MP3::Tag>, L<MP3::Info>, L<Music::Tag>

=for readme continue

=head1 AUTHOR 

Edward Allen III <ealleniii _at_ cpan _dot_ org>

=head1 COPYRIGHT

Copyright (c) 2007,2008 Edward Allen III. Some rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either:

a) the GNU General Public License as published by the Free
Software Foundation; either version 1, or (at your option) any
later version, or

b) the "Artistic License" which comes with Perl.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either
the GNU General Public License or the Artistic License for more details.

You should have received a copy of the Artistic License with this
Kit, in the file named "Artistic".  If not, I'll be glad to provide one.

You should also have received a copy of the GNU General Public License
along with this program in the file named "Copying". If not, write to the
Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
Boston, MA 02110-1301, USA or visit their web page on the Internet at
http://www.gnu.org/copyleft/gpl.html.


=cut


1;

# vim: tabstop=4
