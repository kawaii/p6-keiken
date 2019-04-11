#!perl6
use Keiken::Configuration;
use Keiken::Controller::Commands;
use Keiken::Controller::Experience;
use Keiken::Storage::Cache;
use Keiken::Storage::Database;

use API::Discord;

sub preflight-checks {
    dbh;
}

sub MAIN($discord-token) {
    preflight-checks;

    my $discord = API::Discord.new(:token($discord-token));

    $discord.connect;
    await $discord.ready;

    react {
        whenever $discord.messages -> $message {
            my $channel = await $message.channel;
            my $guild = await $channel.guild;

            my $c = $message.content;

            my $redis-key = $channel.guild-id ~ "-" ~ $message.author.id;

            if $c ~~ s/ ^ "!" // {
                my $response = handle-command($c, payload => $message);
                $message.channel.result.send($response) if $response;
                next;
            }

            unless $message.author.is-bot or $redis.exists($redis-key) {
                experience-cooldown($channel, $message);
                grant-experience($channel, $message);
                grant-level-roles($guild, $message);
            }
        }

    }
}
