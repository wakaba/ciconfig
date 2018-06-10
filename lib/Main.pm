package Main;
use strict;
use warnings;

my $Platforms = {
  travisci => {
    file => '.travis.yml',
    set => sub {
      push @{$_[0]->{jobs}->{include} ||= []}, {stage => 'test'};
    },
  },
  circleci => {
    file => 'circle.yml', # 1.0
    set => sub { },
  },
};

my $Options = {};

$Options->{'travisci', 'pmbp'} = {
  set => sub {
    return unless $_[1];
    $_[0]->{git}->{submodules} = \0;
    $_[0]->{language} = 'perl';
    $_[0]->{perl} = {
      latest  => [qw(5.26)],
      1       => [qw(5.26 5.14 5.8)],
      '5.8+'  => [qw(5.26 5.14 5.8)],
      '5.12+' => [qw(5.26 5.14 5.12)],
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

$Options->{'circleci', 'heroku'} = {
  set => sub {
    return unless $_[1];
    push @{$_[0]->{dependencies}->{override} ||= []},
        'git config --global user.email "temp@circleci.test"',
        'git config --global user.name "CircleCI"';

    $_[0]->{deployment}->{master}->{branch} = 'master';
    push @{$_[0]->{deployment}->{master}->{commands} ||= []},
        'git checkout --orphan herokucommit && git commit -m "Heroku base commit"',
        'make create-commit-for-heroku',
        'git push git@heroku.com:$HEROKU_APP_NAME.git +`git rev-parse HEAD`:refs/heads/master';
  },
};

$Options->{'circleci', 'pmbp'} = {
  set => sub {
    return unless $_[1];
    push @{$_[0]->{dependencies}->{override} ||= []}, 'make test-deps';
    push @{$_[0]->{test}->{override} ||= []}, 'make test';
  },
};

$Options->{'circleci', 'required_docker_images'} = {
  set => sub {
    return unless ref $_[1] eq 'ARRAY' and @{$_[1] or []};
    push @{$_[0]->{machine}->{services} ||= []}, 'docker';
    unshift @{$_[0]->{dependencies}->{override} ||= []},
        'docker info',
        {
          (join ' && ', map {
            "docker pull $_"
          } @{$_[1]}) => {
            background => 1,
          },
        };
  }, # set
}; # required_docker_images

$Options->{'circleci', 'docker-build'} = {
  set => sub {
    return unless $_[1];
    my $defs = ref $_[1] eq 'ARRAY' ? $_[1] : [$_[1]];
    push @{$_[0]->{machine}->{services} ||= []}, 'docker';
    push @{$_[0]->{dependencies}->{override} ||= []}, 'docker info';
    my $host = '';
    for my $def (@$defs) {
      $def = ref $def ? $def : {name => $def};
      die "No |name|" unless defined $def->{name};
      $def->{path} = '.' unless defined $def->{path};
      $def->{branch} = 'master' unless defined $def->{branch};
      push @{$_[0]->{dependencies}->{override} ||= []},
          'docker build -t ' . $def->{name} . ' ' . $def->{path};
      $_[0]->{deployment}->{$def->{branch}}->{branch} = $def->{branch};
      if ($def->{name} =~ m{^([^/]+)/([^/]+)/([^/]+)$} and
          not $1 eq $host) {
        push @{$_[0]->{deployment}->{$def->{branch}}->{commands} ||= []},
            'docker login -e $DOCKER_EMAIL -u $DOCKER_USER -p $DOCKER_PASS '.$1;
        $host = $1;
      }
      push @{$_[0]->{deployment}->{$def->{branch}}->{commands} ||= []},
          'docker push ' . $def->{name} . ' && ' .
          'curl -sSLf $BWALL_URL'.(defined $def->{bwall_suffix} ? '.' . $def->{bwall_suffix} : $def->{branch} eq 'master' ? '' : '.' . $def->{branch}).' -X POST';
    } # $def
  },
};

$Options->{'circleci', 'build'} = {
  set => sub {
    push @{$_[0]->{dependencies}->{override} ||= []}, @{$_[1]};
  },
};

$Options->{'circleci', 'tests'} = {
  set => sub {
    push @{$_[0]->{test}->{override} ||= []}, @{$_[1]};
  },
};

$Options->{'circleci', 'deploy'} = {
  set => sub {
    $_[0]->{deployment}->{master}->{branch} = 'master';
    push @{$_[0]->{deployment}->{master}->{commands} ||= []}, @{$_[1]};
  },
};

$Options->{'circleci', 'merger'} = {
  set => sub {
    return unless $_[1];
    for my $branch (qw(staging nightly)) {
      $_[0]->{deployment}->{$branch}->{branch} = $branch;
      push @{$_[0]->{deployment}->{$branch}->{commands} ||= []},
          'git rev-parse HEAD > head.txt',
          'curl -f -s -S --request POST --header "Authorization:token $GITHUB_ACCESS_TOKEN" --header "Content-Type:application/json" --data-binary "{\"base\":\"master\",\"head\":\"`cat head.txt`\",\"commit_message\":\"auto-merge $CIRCLE_BRANCH into master\"}" "https://api.github.com/repos/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/merges"';
    } # $branch
  },
};

$Options->{'circleci', 'gaa'} = {
  set => sub {
    # XXX
  },
};

sub generate ($$$) {
  my ($class, $input, $root_path) = @_;

  my $data = {};

  for my $platform (sort { $a cmp $b } keys %$input) {
    my $p_def = $Platforms->{$platform};
    die "Unknown platform |$platform|" unless defined $p_def;
    my $json = {};

    $p_def->{set}->($json);

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
    $data->{$p_def->{file}} ||= {remove => 1};
  }

  return $data;
} # generate

1;

=head1 LICENSE

Copyright 2018 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
