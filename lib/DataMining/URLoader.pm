package URLoader;

use strict;
use warnings;
use Carp;
require LWP::UserAgent;
use moose;
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
    writer      =>  '_status'
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
);

sub BUILD {
    my ($self) = @_;

    my $ua = LWP::UserAgent->new;
    $ua->agent("DataMining/0.1");

    $self->_client($ua);
}

sub load_words {
    my ($self, $words) = @_;

    $self->words($words) if $words;
    croak 'Words must be set' if !$self->words;

    # SOME HACK!!!!
    $self->words->[0] = '(' . $self->words->[0] . ')';
    my $regex = reduce { $a . '|(' . $b . ')'; } @{$self->words};

    $self->regex(qr/$regex/);
}

sub load {
    my ($self, $url);

    $self->url($url) if $url;
    croak 'URL must be set' if !$self->url;
    my $request = HTTP::Request->new(GET => $self->url);

    my $res = $self->_client->request($req);

    $self->_status($res->code);
    $self->_content($res->content);

    return $self;
}

sub count {
    my ($self) = @_;


}