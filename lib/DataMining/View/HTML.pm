package DataMining::View::HTML;
use Moose;
use namespace::autoclean;

extends 'Catalyst::View::TT';

__PACKAGE__->config(
    TEMPLATE_EXTENSION => '.tt',
    render_die => 1,
);

=head1 NAME

DataMining::View::HTML - TT View for DataMining

=head1 DESCRIPTION

TT View for DataMining.

=head1 SEE ALSO

L<DataMining>

=head1 AUTHOR

Juan Negretti,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
