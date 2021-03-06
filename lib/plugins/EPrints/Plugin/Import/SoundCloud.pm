package EPrints::Plugin::Import::SoundCloud;

use EPrints::Plugin::Import::TextFile;

use strict;

our @ISA = qw/ EPrints::Plugin::Import::TextFile /;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new( %params );

	$self->{name} = "SoundCloud";
	$self->{visible} = "staff";
	$self->{produce} = [ 'dataobj/eprint', 'list/eprint' ];
    $self->{license_map} = $self->param( "license_map" ) || {};

	my $rc = EPrints::Utils::require_if_exists( "WebService::Soundcloud" );
	unless( $rc ) 
	{
		$self->{visible} = "";
		$self->{error} = "Failed to load required module WebService::Soundcloud";
	}

	return $self;
}

sub input_text_fh
{
	my( $plugin, %opts ) = @_;

	$plugin->{client_id} = $opts{client_id};
	unless( EPrints::Utils::is_set( $plugin->{client_id} ) )
	{
		$plugin->error( "Client ID required, use --arg client_id=12345" );
		return;
	}
	$plugin->{update} = $opts{update};

        my $repo = $plugin->{repository};

	my $sc = WebService::Soundcloud->new( $plugin->{client_id}, "", { debug => $opts{debug} } );

	my @scids;
	my $fh = $opts{fh};
	while( my $scid = <$fh> )
	{
		chomp $scid;
		$scid =~ s/^\s+//;
		$scid =~ s/\s+$//;
		next unless length($scid);

		if( $scid !~ /^\d+$/ )
		{
			$scid = "https://soundcloud.com/$scid" unless $scid =~ /^http/;
			my $user = $sc->get_object( '/resolve', { client_id => $plugin->{client_id}, url => $scid } );
			unless( defined $user && defined $user->{id} )
			{
				$plugin->warning( "Could not resolve user $scid, check user exists and Client ID correct" );
				next;
			}
			$scid = $user->{id};
		}

		push @scids, $scid;
	}

	my @ids;
	foreach my $scid ( @scids )
	{
		my $tracks = $sc->get_list( '/tracks', { client_id => $plugin->{client_id}, user_id => $scid } );
		foreach my $track ( @$tracks )
		{
			my $epdata = $plugin->convert_input( $track );
			next unless( defined $epdata );

			my $dataobj = $plugin->epdata_to_dataobj( $opts{dataset}, $epdata );
			if( defined $dataobj )
			{
				push @ids, $dataobj->get_id;
			}
		}
	}

	return EPrints::List->new( 
		dataset => $opts{dataset}, 
		session => $repo,
		ids=>\@ids );
}

sub convert_input
{
	my( $plugin, $data ) = @_;

	my $epdata = {};

	return unless defined $data->{sharing} && $data->{sharing} eq "public";

	my $repo = $plugin->{repository};
	my $list = $repo->dataset( "eprint" )->search(
		filters => [
			{ meta_fields => [ "source" ], value => $data->{uri}, match => "EQ" },
		],
	);
	if( $list->count == 1 )
	{
		unless( $plugin->{update} )
		{
			$plugin->warning( $data->{permalink_url} . " already exists in repository, skipping" );
			return;
		}
		$epdata->{eprintid} = ($list->slice( 0, 1 ))[0]->get_id;
	}
	elsif( $list->count > 0 )
	{
		$plugin->warning( $data->{permalink_url} . " has multiple copies in repository, skipping" );
		return;
	}

	$epdata->{type} = "audio";
	push @{ $epdata->{corp_creators} },  $data->{user}->{username};

	my %MAP = (
		uri => "source",
		title => "title",
		description => "abstract",
		permalink_url => "official_url",
		genre => "keywords",
		tag_list => "keywords",
	);
	while ( my( $src, $dest ) = each %MAP )
	{
		next unless EPrints::Utils::is_set( $data->{$src} );
		defined $epdata->{$dest} ? $epdata->{$dest} .= " " . $data->{$src} : $epdata->{$dest} = $data->{$src};
		$epdata->{date_type} = "published" if $dest eq "date";
	}

	if( EPrints::Utils::is_set( $data->{release_year} ) )
	{
		$epdata->{date} = sprintf( "%04d-%02d-%02d", $data->{release_year}, $data->{release_month} || 0, $data->{release_day} || 0 );
	}
	elsif( EPrints::Utils::is_set( $data->{created_at} ) )
	{
		$data->{created_at} =~ m|^([0-9]{4})/([0-9]{2})/([0-9]{2})|;
		$epdata->{date} = sprintf( "%04d-%02d-%02d", $1, $2, $3 );
	}

	if( $data->{downloadable} || $data->{streamable} )
	{
		# add client id parameter to stream url
		my $url = URI->new( $data->{downloadable} ? $data->{download_url} : $data->{stream_url} );
		$url->query_form( { client_id => $plugin->{client_id} } );

		my $license = $plugin->{license_map}->{$data->{license}} || $data->{license};
		my $document = {
			eprintid => defined $epdata->{eprintid} ? $epdata->{eprintid} : undef,
			main => sprintf( "%s.%s", $data->{permalink}, $data->{downloadable} ? $data->{original_format} : "mp3" ), # stream is 128kbs mp3
			format => "audio",
			security => "public",
			license => defined $license ? $license : undef,
		};
		push @{ $document->{files} }, {
			filename => $document->{main},
			url => "$url",
		};
		push @{ $epdata->{documents} }, $document;
	}

	my $artwork_url = $data->{artwork_url};
	if( defined $artwork_url )
	{
		$artwork_url =~ s/large/crop/;
		my $document = {
			eprintid => defined $epdata->{eprintid} ? $epdata->{eprintid} : undef,
			main => "cover.jpg",
			format => "image",
			security => "public",
			content => "coverimage",
		};
		push @{ $document->{files} }, {
			filename => $document->{main},
			url => $artwork_url,
		};
		push @{ $epdata->{documents} }, $document;
	}

	return $epdata;
}

1;
