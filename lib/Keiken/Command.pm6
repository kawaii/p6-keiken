unit class Keiken::Command;
class X::Keiken::Command::InvalidCommand is Exception {
    has $.message;
};

has %.commands;

method handle-command($str, $message) {
    my ($command, $args) = ~<<($str ~~ / ^ (\S+) [\s+ (.*)]? $ /);

    if !$command and %.commands{<DEFAULT>} {
        %.commands{<DEFAULT>}($args // '', $message);
    }
    elsif %.commands{$command} -> $sub {
        $sub($args // '', $message);
    }
    else {
        X::Keiken::Command::InvalidCommand.new(:message("Invalid command: $command")).throw;
    }
}