unit module Keiken::Storage::Database;
use Keiken::Configuration;

use DBIish;

sub dbh is export {
    my %defaults = config-with-defaults;
    state $dbh //= DBIish.connect(
        'Pg', :host(%defaults<database-hostname>),
        :port(%defaults<database-port>),
        :database(%defaults<database-name>),
        :user(%defaults<database-user>),
        :password(%defaults<database-password>),
        :RaiseError,
    );
}
