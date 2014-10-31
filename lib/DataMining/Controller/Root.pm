package DataMining::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config(namespace => '');

=encoding utf-8

=head1 NAME

DataMining::Controller::Root - Root Controller for DataMining

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=head2 index

The root page (/)

=cut

sub index :Path :Args(0) :GET {
    my ( $self, $c ) = @_;

    $c->load_error_msgs;
    $c->stash->{template} = 'index.tt';


    # Hello World
    # $c->response->body( $c->welcome_message );
}

sub execute :Path :Args(0) :POST {
    my ( $self, $c ) = @_;

    $c->form( url => [qw/NOT_BLANK HTTP_URL/] );

    if ( $c->form->has_error ) {
            $c->response->redirect($c->uri_for($self->action_for('index'),
                {mid => $c->set_error_msg('Must supply a valid URL')}));
    }

    my $model = $c->model('URLoader');

    $model->do_request($c->req->params->{url});

    if ( $model->status != 200 ) {
            $c->response->redirect($c->uri_for($self->action_for('list'),
                {mid => $c->set_status_msg('URL responded status ' . $model->status)}));
    }

    $model->count_words;

    my $probabilities = $model->calculate_probabilities;
    my $sorted;

    for ( sort { $probabilities->{$a} <=> $probabilities->{$b} } keys %{$probabilities} ) {
        push @{$sorted}, { name => $_, value => $probabilities->{$_} };
    }

    $c->stash->{categories} = $sorted;
    $c->stash->{template} = 'index.tt';
}

=head2 default

Standard 404 error page

=cut

sub default :Path {
    my ( $self, $c ) = @_;
    $c->response->body( 'Page not found' );
    $c->response->status(404);
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {}

=head1 AUTHOR

Juan Negretti,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
