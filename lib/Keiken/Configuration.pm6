unit module Keiken::Configuration;

my %defaults = database-hostname => %*ENV<PARADOXUM_DATABASE_HOST> || 'localhost',
               database-port => %*ENV<PARADOXUM_DATABASE_PORT> || 5432,
               database-name => %*ENV<PARADOXUM_DATABASE_NAME> || 'paradoxum',
               database-user => %*ENV<PARADOXUM_DATABASE_USER> || 'paradoxum',
               database-password => %*ENV<PARADOXUM_DATABASE_PASSWORD> || 'password',
               redis-hostname => %*ENV<PARADOXUM_REDIS_HOST> || 'localhost',
               redis-port => %*ENV<PARADOXUM_REDIS_PORT> || 6379,
               redis-password => %*ENV<PARADOXUM_REDIS_PASSWORD> || '',
;

sub config-with-defaults(%config=%()) is export {
    return %(
        |%defaults,
        |%config
    );
}
