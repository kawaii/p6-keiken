unit module Keiken::Controller::Commands;

use Keiken::Controller::Experience;

use Keiken::Storage::Database;
use Keiken::Storage::Cache;

use JSON::Fast;
use Command::Despatch;

my $commands = Command::Despatch.new(
        command-table => {
            level => {
                list => &list-levels,
                add => &add-level,
                rm => &rm-level,
            }
        }
);

sub handle-command($str, $payload) is export {
    return $commands.run($str, payload => $payload);
}

sub show-level($args-str is copy) {
    my $message = self.payload;
    my $channel = await ($message.channel);

    my $author-id;
    my $response-str = '<@%d> %s %d experience points. %s are level %d.';
    my @response-fmt-args;

    if ($args-str ~~ / '<@' '!'? <(\d+)> '>' /) {
        $author-id = $/;
        @response-fmt-args = Nil, 'has', Nil, 'They', Nil;
    }
    else {
        $author-id = $message.author.id;
        @response-fmt-args = Nil, ', you have', Nil, 'You', Nil;
    }

    @response-fmt-args[0] = $author-id;

    my $result = dbh.prepare(q:to/STATEMENT/);
           SELECT "experience-points" FROM paradoxum_keiken_users WHERE "user-id" = ? AND "guild-id" = ?;
        STATEMENT

    my $rank = $result.execute($author-id, $channel.guild-id);
    my @rank = $result.row();

    my $level = calculate-level(@rank[0]);

    @response-fmt-args[2] = @rank[0];
    @response-fmt-args[4] = $level;

    $channel.send-message(sprintf $response-str, @response-fmt-args);
}

sub add-level($args) {
    my ($level, $role-id) = ~<<($args ~~ / (\d+) \s+ (\d+) /);

    unless $level and $role-id {
        return "**Usage**: `!add-level LEVEL ROLE-ID`";
    }

    my %level-role = $level => $role-id;

    my $level-role = to-json(%level-role);
    my $new-level-role = dbh.prepare(q:to/STATEMENT/);
           UPDATE paradoxum_keiken_configuration SET "level-roles" = "level-roles"|| ?;
        STATEMENT

    $new-level-role.execute($level-role);
    return "Level $level is now bound to <@&{$role-id}>.";
}

sub rm-level($args-str is copy) {
    my ($level) = ~<<($args-str ~~ / (\d+)/);

    unless $level {
        return "**Usage**: `!rm-level LEVEL`";
    }

    my $role-removal = dbh.prepare(q:to/STATEMENT/);
           UPDATE paradoxum_keiken_configuration SET "level-roles" = "level-roles" - ?;
        STATEMENT

    $role-removal.execute($level);
    return "Level $level has been unbound.";
}

sub list-levels($args-str) {
    my $channel = await ($message.channel);

    my $level-roles = dbh.prepare(q:to/STATEMENT/);
           SELECT "level-roles" FROM paradoxum_keiken_configuration WHERE "guild-id" = ?;
        STATEMENT

    my $result = $level-roles.execute($channel.guild-id);
    my @result = $level-roles.row();
    my %result = from-json(@result[0]);

    if %result {
        $channel.send-message(@result[0]);
    } else { $channel.send-message("There are currently no levels bound."); }
}
