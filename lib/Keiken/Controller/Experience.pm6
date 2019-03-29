unit module Keiken::Controller::Experience;

use Keiken::Storage::Database;
use Keiken::Storage::Cache;

sub calculate-experience is export {
    (8..22).rand.Int;
}

sub grant-experience($channel, $message) is export {
    my $experience-points = calculate-experience();
    my $experience-timestamp = DateTime.now();

    my $experience-grant = dbh.prepare(qq:to/STATEMENT/);
        INSERT INTO paradoxum_keiken_users ("guild-id", "user-id", "experience-points", "last-updated") 
             VALUES (?, ?, ?, ?) 
        ON CONFLICT ("guild-id", "user-id")
          DO UPDATE
                SET "experience-points" = paradoxum_keiken_users."experience-points" + EXCLUDED."experience-points", "last-updated" = ?
              WHERE paradoxum_keiken_users."guild-id" = EXCLUDED."guild-id"
                AND paradoxum_keiken_users."user-id" = EXCLUDED."user-id";
          STATEMENT

    $experience-grant.execute($channel.guild-id, $message.author.id, $experience-points, $experience-timestamp, $experience-timestamp);
    say $message.author.username ~ " gained " ~ $experience-points ~ " experience points!";
}

sub get-user-xp($author-id, $guild-id) {
    my $experience = dbh.prepare(q:to/STATEMENT/);
        SELECT "experience-points"
          FROM paradoxum_keiken_users
         WHERE "user-id" = ?
           AND "guild-id" = ?;
     STATEMENT

    $experience.execute($author-id, $guild-id);
    my @xp = $experience.row();

    return @xp[0].isNaN ?? 0 !! @xp[0];
}

sub calculate-level($xp) is export {
    my $a = 10; my $b = 50; my $c = 100;
    my $level = (-$b + sqrt( $b² - 4*$a*$c + 4*$a*$xp ) ) / (2*$a);
    return $level.isNaN ?? 0 !! $level;
}

sub get-level-roles($message) {
    my $channel = await ($message.channel);
    my $level-roles =  dbh.prepare(q:to/STATEMENT/);
           SELECT "level-roles" FROM paradoxum_keiken_configuration WHERE "guild-id" = ?;
        STATEMENT

    my $result = $level-roles.execute($channel.guild-id);
    my @result = $level-roles.row();

    my %level-roles = from-json(@result[0]);
    return %level-roles;
}

sub grant-level-roles($guild, $message) is export {
    my %level-roles = get-level-roles($message);

    my $l = calculate-level(get-user-xp($message.author.id, $guild.id));
    say "{$message.author.username} needs level $l";
    for ^$l -> $level {
      say "$level is role ID $_" with %level-roles{$level};
      $guild.assign-role($message.author, $_) with %level-roles{$level};
    }
}

sub experience-cooldown($channel, $message) is export {
    $redis.setex($channel.guild-id ~ "-" ~ $message.author.id, 80, $message.channel-id);
}
