unit module Keiken::Controller::Commands;

use Keiken::Controller::Experience;
use Keiken::Command;

use Keiken::Storage::Database;
use Keiken::Storage::Cache;

use JSON::Fast;


my $handler = Keiken::Command.new(
    commands => {
        level => &level
    }
);

sub handle-command($trimmed-message, $message-obj) is export {
    $handler.handle-command($trimmed-message, $message-obj);

    CATCH {
        when X::Keiken::Command::InvalidCommand {
            $message-obj.channel.result.send-message(.message)
        }
    }
}

sub level($args-str is copy, $message) {
    state $handler = Keiken::Command.new(
        commands => {
            add => &add-level,
            rm => &rm-level,
            list => &list-levels,
            show => &show-level
        }
    );

    $message.channel.result.send('**Usage**: !level COMMAND [args]') unless $args-str;

    $handler.handle-command($args-str, $message);
}

sub show-level($args-str is copy, $message) {
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

sub add-level($args-str is copy, $message) {
    my $channel = await ($message.channel);

    my ($level, $role-id) = ~<<($args-str ~~ / (\d+) \s+ (\d+) /);

    unless $level and $role-id {
        $channel.send-message("**Usage**: `!add-level LEVEL ROLE-ID`");
        return;
    }

    my %level-role = $level => $role-id;

    my $level-role = to-json(%level-role);
    my $new-level-role = dbh.prepare(q:to/STATEMENT/);
           UPDATE paradoxum_keiken_configuration SET "level-roles" = "level-roles"|| ?;
        STATEMENT

    $new-level-role.execute($level-role);
    $channel.send-message("Level $level is now bound to <@&{$role-id}>.");
}

sub rm-level($args-str is copy, $message) {
    my $channel = await ($message.channel);

    my ($level) = ~<<($args-str ~~ / (\d+)/);

    unless $level {
        $channel.send-message("**Usage**: `!rm-level LEVEL`");
        return;
    }

    my $role-removal = dbh.prepare(q:to/STATEMENT/);
           UPDATE paradoxum_keiken_configuration SET "level-roles" = "level-roles" - ?;
        STATEMENT

    $role-removal.execute($level);
    $channel.send-message("Level $level has been unbound.");
}

sub list-levels($args-str, $message) {
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
