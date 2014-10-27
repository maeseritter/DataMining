package URLoader;

use strict;
use warnings;
use Carp;
require LWP::UserAgent;
use Moose;
use List::Util qw/reduce/;
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
    required    =>  1,
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
            }
        };
    };
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
    my ($self, $url);

    $self->url($url) if $url;
    croak 'URL must be set' if !$self->url;
    my $request = HTTP::Request->new(GET => $self->url);

    my $res = $self->_client->request($request);

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

__PACKAGE__->meta->make_immutable;

1;