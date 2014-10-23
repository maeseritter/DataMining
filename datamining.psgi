use strict;
use warnings;

use DataMining;

my $app = DataMining->apply_default_middlewares(DataMining->psgi_app);
$app;

