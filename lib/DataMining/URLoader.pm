package URLoader;

use strict;
use warnings;
use Carp;
require LWP::UserAgent;
use Moose;
use List::Util qw/reduce sum/;
use namespace::autoclean;

has 'client' => (
    is          =>  'ro',
    isa         =>  'LWP::UserAgent',
    writer      =>  '_client',
    init_arg    =>  undef,
);

has 'content' => (
    is          =>  'rw',
    isa         =>  'Str',
    writer      =>  '_content',
    init_arg    =>  undef,
);

has 'status' => (
    is          =>  'ro',
    isa         =>  'Int',
    writer      =>  '_status',
    init_arg    =>  undef,
);

has 'url' => (
    is          =>  'rw',
    isa         =>  'Str',
);

has 'regex' => (
    is          =>  'ro',
    isa         =>  'RegexpRef',
    writer      =>  '_regex',
    init_arg    =>  undef,
);

has 'words' => (
    is          =>  'rw',
    isa         =>  'ArrayRef',
    init_arg    =>  undef,
    default     =>  sub {
        return [
            'local',
            'coach',
            'manag',
            'startup',
            'real',
            'magazin',
            'compani',
            'citi',
            'design',
            'equal',
            'market',
            'singer',
            'tv',
            'locat',
            'februari',
            'episod',
            'leagu',
            'player',
            'club',
            'defend',
            'stadium',
            'bosniawhi',
            'nasa',
            'star',
            'travel',
            'play',
            'hide',
            'stuff',
            'trial',
            'digit',
            'tool',
            'english',
            'told',
            'won',
            'equal',
            'tech',
        ];
    },
);

has 'count' => (
    is          =>  'ro',
    isa         =>  'HashRef',
    writer      =>  '_count',
    init_arg    =>  undef,
    default     => sub { return {}; },
);

has 'polynomials' => (
    is          =>  'rw',
    isa         =>  'HashRef',
    default     =>  sub {
        return {
            business => { 
                constant    =>  -0.91,
                local       =>  -0.21,
                coach       =>  0.59,
                manag       =>  0.39,
                startup     =>  1.49,
                real        =>  -0.43,
                magazin     =>  -1.38,
                compani     =>  0.35,
                citi        =>  0.1,
                design      =>  0.13,
                equal       =>  -1.02,
                market      =>  0.62
            },
            entertainment => {
                constant    =>  -0.67,
                singer      =>  1.8,
                manag       =>  -0.57,
                tv          =>  0.39,
                locat       =>  -0.58,
                februari    =>  1.53,
                design      =>  -0.15,
                market      =>  -0.4,
                episod      =>  1.52,
            },
            football => {
                constant    =>  -6.05,
                leagu       =>  2.37,
                player      =>  0.78,
                club        =>  0.11,
                defend      =>  0.91,
                manag       =>  0.46,
                stadium     =>  0.91,
            },
            science => {
                constant    =>  -11.84,
                bosniawhi   =>  24.41,
                nasa        =>  0.18,
            },
            technology => {
                constant    =>  -1.43,
                club        =>  0.44,
                star        =>  0.07,
                coach       =>  -0.25,
                travel      =>  -1.49,
                play        =>  0.35,
                manag       =>  -0.74,
                hide        =>  -1,
                nasa        =>  0.76,
                stuff       =>  1.06,
                trial       =>  0.46,
                digit       =>  0.62,
                tool        =>  0.54,
            },
            travel => {
                constant    =>  -1.57,
                english     =>  0.4,
                local       =>  0.43,
                told        =>  -0.27,
                won         =>  0.05,
                travel      =>  0.91,
                hide        =>  2,
                tv          =>  -0.17,
                equal       =>  1.55,
                tech        =>  -0.39,
                tool        =>  -0.22,
            }
        };
    },
);

sub BUILD {
    my ($self) = @_;

    my $ua = LWP::UserAgent->new;
    $ua->agent("DataMining/0.1");

    $self->_client($ua);
    $self->load_words;
}

sub load_words {
    my ($self, $words) = @_;

    $self->words($words) if $words;
    croak 'Words must be set' if !$self->words;

    # SOME HACK!!!!
    $self->words->[0] = '(?:' . $self->words->[0] . ')';
    my $regex = reduce { $a . '|(?:' . $b . ')'; } @{$self->words};

    $self->_regex(qr/($regex)/);
}

sub do_request {
    my ($self, $url) = @_;

    $self->url($url) if $url;
    croak 'URL must be set' if !$self->url;
    my $request = HTTP::Request->new(GET => $self->url);

    my $res = $self->client->request($request);

    $self->_status($res->code);
    $self->_content($res->content);

    return $self;
}

sub count_words {
    my ($self) = @_;

    $self->do_request if !$self->content;
    croak 'The status must be ok' if $self->status != 200;

    my ($regex, $content) = ($self->regex, $self->content);

    while ( $content =~ m/$regex/g ) {
        $self->count->{$1}++;
    }


}

sub calculate_probabilities {
    my ($self) = @_;

    croak 'words has not been counted' if !scalar(keys %{$self->count});

    my ($sum,$var,%calculated_poly);

    for my $category ( keys %{ $self->polynomials } ) {
        $calculated_poly{$category} = $self->polynomials->{constant};

        for ( keys %{ $self->polynomials->{$category} } ) {
            $var = ($self->count->{$_})? $self->count->{$_} : 0;
            $calculated_poly{$category} += $self->polynomials->{$category}->{$_} * $var;
        }

        $sum += exp( $calculated_poly{$category} );
    }

    my %probs = map { ( $_ => exp( $calculated_poly{$_} )/$sum ) } keys %calculated_poly;

    return \%probs;
}

__PACKAGE__->meta->make_immutable;

1;