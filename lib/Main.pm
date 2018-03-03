package Main;
use strict;
use warnings;

my $Platforms = {
  travisci => {
    file => '.travis.yml',
  },
};

my $Options = {};

$Options->{'travisci', 'pmbp'} = {
  set => sub {
    return unless $_[1];
    $_[0]->{git}->{submodules} = \0;
    $_[0]->{language} = 'perl';
    $_[0]->{perl} = {
      1       => [qw(5.26 5.14 5.8)],
      '5.8+'  => [qw(5.26 5.14 5.8)],
      '5.10+' => [qw(5.26 5.14 5.10)],
      '5.14+' => [qw(5.26 5.14)],
    }->{$_[1]} || die "Unknown |pmbp| value |$_[1]|";
    $_[0]->{before_install} = 'true';
    $_[0]->{install} = 'make test-deps';
    $_[0]->{script} = 'make test';
  },
};

$Options->{'travisci', 'notifications'} = {
  set => sub {
    return unless $_[1];
    die "Unknown |notificaions| value |$_[1]|" unless $_[1] eq 'suika';
    $_[0]->{notifications}->{email} = [qw(wakaba@suikawiki.org)];
    $_[0]->{notifications}->{irc}->{channels}
        = ['ircs://irc.suikawiki.org:6697#mechanize'];
    $_[0]->{notifications}->{irc}->{use_notice} = \1;
  },
};

$Options->{'travisci', 'merger'} = {
  set => sub {
    return unless $_[1];
    my $path = $_[2]->child ('config/travis-merger.txt');
    die "File |$path| not found" unless $path->is_file;
    $_[0]->{env}->{global}->{secure} = $path->slurp;
    push @{$_[0]->{jobs}->{include} ||= []},
        {stage => 'merge',
         before_install => "true",
         install => "true",
         script => 'curl -f https://gist.githubusercontent.com/wakaba/ab553f86cd017e0cb28c6dbb5364b009/raw/travis-merge-job.pl | perl'};
  },
};

sub generate ($$$) {
  my ($class, $input, $root_path) = @_;

  my $data = {};

  for my $platform (sort { $a cmp $b } keys %$input) {
    my $p_def = $Platforms->{$platform};
    die "Unknown platform |$platform|" unless defined $p_def;
    my $json = {};

    for my $opt (sort { $a cmp $b } keys %{$input->{$platform}}) {
      my $o_def = $Options->{$platform, $opt};
      die "Unknown option |$platform|, |$opt|" unless defined $o_def;
      my $o_param = $input->{$platform}->{$opt};
      $o_def->{set}->($json, $o_param, $root_path);
    } # $opt

    $data->{$p_def->{file}} = {json => $json};
  }

  for my $platform (sort { $a cmp $b } keys %$Platforms) {
    my $p_def = $Platforms->{$platform};
    $data->{$p_def->{file}} //= {remove => 1};
  }

  return $data;
} # generate

1;

=head1 LICENSE

Copyright 2018 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
