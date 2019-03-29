unit module Keiken::Storage::Cache;
use Keiken::Configuration;

use Redis::Async;

my %defaults = config-with-defaults;
our $redis is export = Redis::Async.new("%defaults<redis-hostname>:%defaults<redis-port>");
