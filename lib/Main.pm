package Main;
use strict;
use warnings;

sub shellquote ($) {
  my $s = shift;
  $s =~ s/([\\'])/\\$1/g;
  return "'$s'";
} # shellquote

sub install_awscli_command () {
  return join "\n",
        "(((sudo apt-cache search python-dev | grep ^python-dev) || ".
           "sudo apt-get update) && ".
         "sudo apt-get install -y python-dev) || ".
        "(sudo apt-get update && sudo apt-get install -y python-dev)",
        "sudo pip install awscli --upgrade || sudo pip3 install awscli --upgrade",
        "aws --version";
} # install_awscli_command

sub new_job () {
  return {
    machine => {"image" => "ubuntu-2004:202008-01"},
  };
} # new_job

sub circle_step ($;%) {
  my ($in, %args) = @_;

  if (ref $in eq 'HASH') {
    if (defined $in->{command}) {
      if (ref $in->{command} eq 'ARRAY') {
        $in->{command} = join "\n", @{$in->{command}};
      }
    } elsif (defined delete $in->{awscli}) {
      $in->{command} = install_awscli_command ();
    } else {
      keys %$in; # reset
      my $command = each %$in;
      $in = {%{$in->{$command}}, command => $command};
    }
  } else {
    $in = {command => $in};
  }

  my $command = $in->{command};
  for ($args{branch}, $in->{branch}) {
    $command = join "\n",
        q{if [ "${CIRCLE_BRANCH}" == }.(shellquote $_).q{ ]; then},
        q{true},
        $command,
        q{fi}
        if defined $_;
  }

  my $type = $args{deploy} ? 'deploy' : 'run';
  if (exists $in->{parallel} and not $in->{parallel} and
      not $type eq 'deploy') {
    $command = join "\n",
        q{if [ "${CIRCLE_NODE_INDEX}" == "0" ]; then},
        q{true},
        $command,
        q{fi};
  }
  
  my $v = {command => $command};
  $v->{background} = \1 if $in->{background};
  $v->{no_output_timeout} = $in->{timeout} . 's'
      if $in->{timeout};

  return {$type => $v};
} # circle_step

my $Platforms = {
  travisci => {
    file => '.travis.yml',
    set => sub {
      my $json = $_[0];
      #unshift @{$json->{jobs}->{include} ||= []}, {stage => 'test'};

      if (delete $json->{_empty}) {
        for (qw(before_install install script)) {
          die "Both |empty| and non-empty rules are specified"
              if defined $json->{$_};
        }

        $json->{git}->{submodules} = \0;
        $json->{before_install} = 'true';
        $json->{install} = 'true';
        $json->{script} = 'true';
      }
    },
  },
  circleci => {
    file => '.circleci/config.yml',
    set => sub {
      my $json = $_[0];
      $json->{version} = 2;
      $json->{workflows}->{version} = 2;
      $json->{jobs} ||= {};
      if (delete $json->{_empty}) {
        for (qw(_build _test _deploy _deploy_jobs)) {
          die "Both |empty| and non-empty rules are specified"
              if defined $json->{$_};
        }
      } else {

        my $split_jobs = defined $json->{_build_generated_files};
        my $loads = [];
        push @$loads, 'checkout';
        if ($split_jobs) {
          push @$loads, {"attach_workspace" => {"at" => "./"}};
          if (@{$json->{_build_generated_images} or []}) {
            for (@{$json->{_build_generated_images} or []}) {
              my $name = $_;
              $name =~ s{:}{/}g;
              push @$loads,
                  {"run" => {"command" => "docker load -i .ciconfigtemp/dockerimages/$name.tar"}};
            }
          }
        }
        # $loads
        my $stores = [];
        if ($split_jobs) {
          if (@{$json->{_build_generated_images} or []}) {
            for (@{$json->{_build_generated_images} or []}) {
              my $name = $_;
              $name =~ s{:}{/}g;
              my $dir = $name;
              $dir =~ s{[^/]+$}{};
              push @$stores,
                  {run => {command => 'mkdir -p .ciconfigtemp/dockerimages/'.$dir}};
              push @$stores,
                  {"run" => {"command" => "docker save -o .ciconfigtemp/dockerimages/$name.tar $_"}};
            }
          }
          push @$stores,
              {"persist_to_workspace" => {
                "root" => "./",
                "paths" => ['.ciconfigtemp', @{$json->{_build_generated_files}}],
              }};
        }
        # $stores

        my @build_job_name = qw(build);
        my @job_name = @build_job_name;
        if ($split_jobs) {
          push @job_name, map { 'test-' . $_ } sort { $a cmp $b } keys %{$json->{_test_jobs}};
          push @job_name, 'test' if defined $json->{_test};
        }
        for my $job_name (@job_name) {
          $json->{jobs}->{$job_name} = new_job;
          $json->{jobs}->{$job_name}->{environment}->{CIRCLE_ARTIFACTS} = '/tmp/circle-artifacts/' . $job_name;
          $json->{jobs}->{$job_name}->{steps} = [
            @$loads,
            circle_step ('mkdir -p $CIRCLE_ARTIFACTS'),
          ];
        }
        $json->{jobs}->{build}->{steps} = [
          'checkout',
          circle_step ('mkdir -p $CIRCLE_ARTIFACTS'),
        ];
        if (defined $json->{_build}) {
          push @{$json->{jobs}->{build}->{steps}}, map {
            circle_step ($_);
          } @{delete $json->{_build}};
        }
        if (defined $json->{_test}) {
          push @{$json->{jobs}->{$split_jobs ? 'test' : 'build'}->{steps}}, map {
            circle_step ($_);
          } @{$json->{_test}};
        }
        for (sort { $a cmp $b } keys %{$json->{_test_jobs}}) {
          my $job_name = 'test-' . $_;
          push @{$json->{jobs}->{$job_name}->{steps}}, map {
            circle_step ($_);
          } @{$json->{_test_preps} or []}, @{$json->{_test_jobs}->{$_}};
        }
        delete $json->{_test_preps};
        for my $job_name (@job_name) {
          push @{$json->{jobs}->{$job_name}->{steps}},
              {store_artifacts => {
                path => '/tmp/circle-artifacts/' . $job_name,
              }};
        }
        push @{$json->{jobs}->{build}->{steps}}, @$stores;
        if (keys %{$json->{_deploy} or {}}) {
          for my $branch (sort { $a cmp $b } keys %{$json->{_deploy} or {}}) {
            push @{$json->{jobs}->{$split_jobs ? 'test' : 'build'}->{steps}}, map {
              circle_step ($_, deploy => 1, branch => $branch);
            } @{$json->{_deploy}->{$branch}};
          }
          delete $json->{_deploy};
        }
        
        $json->{workflows}->{build}->{jobs} = ['build'];
        for my $job_name (@job_name) {
          next if $job_name eq 'build';
          push @{$json->{workflows}->{build}->{jobs}},
              {$job_name => {requires => ['build']}};
          if ($json->{_parallel}) {
            $json->{jobs}->{$job_name}->{parallelism} = $json->{_parallel};
          }
        }
        if (not $split_jobs and $json->{_parallel}) {
          $json->{jobs}->{build}->{parallelism} = $json->{_parallel};
        }
        delete $json->{_parallel};

        ## Deploy steps executed after build job
        for my $branch_name (sort { $a cmp $b } keys %{$json->{_deploy_jobs} or {}}) {
          my $job_name = 'deploy_' . $branch_name;
          $json->{jobs}->{$job_name} = new_job;
          push @{$json->{jobs}->{$job_name}->{steps}}, @$loads;
          push @{$json->{jobs}->{$job_name}->{steps}},
              map {
                circle_step ($_, deploy => 1);
              } @{$json->{_deploy_jobs}->{$branch_name}};
          push @{$json->{workflows}->{build}->{jobs}}, {$job_name => {
            requires => \@job_name,
            filters => {branches => {only => [$branch_name]}},
            context => ['deploy-context'],
          }};
        }
        for my $branch_name (sort { $a cmp $b } keys %{$json->{_early_deploy_jobs} or {}}) {
          my $job_name = 'early_deploy_' . $branch_name;
          $json->{jobs}->{$job_name} = new_job;
          push @{$json->{jobs}->{$job_name}->{steps}}, @$loads;
          push @{$json->{jobs}->{$job_name}->{steps}},
              map {
                circle_step ($_, deploy => 1);
              } @{$json->{_early_deploy_jobs}->{$branch_name}};
          unshift @{$json->{workflows}->{build}->{jobs}}, {$job_name => {
            requires => \@build_job_name,
            filters => {branches => {only => [$branch_name]}},
            context => ['deploy-context'],
          }};
        }
        delete $json->{_early_deploy_jobs};
        delete $json->{_deploy_jobs};
        delete $json->{_test_jobs};
        delete $json->{_test};

        delete $json->{_build_generated_files};
        delete $json->{_build_generated_images};
      }
    },
  },
  circleci1 => { # obsolete
    file => 'circle.yml',
    set => sub {
    },
  },
};

my $Options = {};

$Options->{'travisci', 'empty'} = {
  set => sub {
    return unless $_[1];
    $_[0]->{_empty} = 1;
  },
};

$Options->{'travisci', 'pmbp'} = {
  set => sub {
    return unless $_[1];
    $_[0]->{git}->{submodules} = \0;
    $_[0]->{language} = 'perl';
    $_[0]->{perl} = {
      latest  => [qw(5.32)],
      1       => [qw(5.32 5.14 5.8)],
      '5.8+'  => [qw(5.32 5.14 5.8)],
      '5.12+' => [qw(5.32 5.14 5.12)],
      '5.10+' => [qw(5.32 5.14 5.10)],
      '5.14+' => [qw(5.32 5.14)],
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
        {stage => 'test'},
        {stage => 'merge',
         before_install => "true",
         install => "true",
         script => 'curl -f https://gist.githubusercontent.com/wakaba/ab553f86cd017e0cb28c6dbb5364b009/raw/travis-merge-job.pl | perl'};
  },
};

$Options->{'circleci', 'heroku'} = {
  set => sub {
    return unless $_[1];
    my $has_bg = !! $_[0]->{_build_generated_files};
    
    push @{$has_bg ? $_[0]->{_deploy_jobs}->{master} ||= [] : $_[0]->{_build} ||= []}, join "\n",
        'git config --global user.email "temp@circleci.test"',
        'git config --global user.name "CircleCI"';
    
    my $def = ref $_[1] eq 'HASH' ? $_[1] : {};
    push @{$_[0]->{$has_bg ? '_deploy_jobs' : '_deploy'}->{'master'} ||= []},
        'git checkout --orphan herokucommit && git commit -m "Heroku base commit"',
        @{ref $def->{prepare} eq 'ARRAY' ? $def->{prepare} : []},
        'make '.($has_bg ? 'create-commit-for-heroku-circleci' : 'create-commit-for-heroku'),
        'git push git@heroku.com:'.($def->{app_name} || '$HEROKU_APP_NAME').'.git +`git rev-parse HEAD`:refs/heads/master',
        @{ref $def->{pushed} eq 'ARRAY' ? $def->{pushed} : []},
    ;
  },
};

$Options->{'circleci', 'pmbp'} = {
  set => sub {
    return unless $_[1];
    my $json = $_[0];
    push @{$json->{_build} ||= []}, 'make test-deps';
    if (defined $json->{_build_generated_files}) {
      push @{$json->{_test_jobs}->{pmbp} ||= []}, 'make test';
    } else {
      push @{$json->{_test} ||= []}, 'make test';
    }
  },
};

$Options->{'circleci', 'build_generated_files'} = {
  set => sub {
    return unless $_[1] and ref $_[1] eq 'ARRAY';
    push @{$_[0]->{_build_generated_files} ||= []}, @{$_[1]};
  },
};

$Options->{'circleci', 'build_generated_pmbp'} = {
  set => sub {
    return unless $_[1];
    push @{$_[0]->{_build_generated_files} ||= []},
        qw(deps local perl prove plackup lserver local-server rev);
  },
};

$Options->{'circleci', 'required_docker_images'} = {
  set => sub {
    return unless ref $_[1] eq 'ARRAY' and @{$_[1] or []};
    my $preps = [
        'docker info',
        {
          (join ' && ', map {
            "docker pull $_"
          } @{$_[1]}) => {
            background => 1,
          },
        },
    ];
    unshift @{$_[0]->{_build} ||= []}, @$preps;
    unshift @{$_[0]->{_test_preps} ||= []}, @$preps;
  }, # set
}; # required_docker_images

$Options->{'circleci', 'docker-build'} = {
  set => sub {
    return unless $_[1];
    my $defs = ref $_[1] eq 'ARRAY' ? $_[1] : [$_[1]];
    push @{$_[0]->{_build} ||= []}, 'docker info';
    my $has_bg = !! $_[0]->{_build_generated_files};
    my $has_login = {};
    for my $def (@$defs) {
      $def = ref $def ? $def : {name => $def};
      my $name = defined $def->{name} ? $def->{name} : $def->{expression};
      die "No |name|" unless defined $name;
      $def->{path} = '.' unless defined $def->{path};
      $def->{branch} = 'master' unless defined $def->{branch};
      if ($has_bg) {
        push @{$_[0]->{_build_generated_images} ||= []}, $name;
      }
      push @{$_[0]->{_build} ||= []},
          'docker build -t ' . $name . ' ' . $def->{path};

      next if $def->{no_push};
      if ($name =~ m{^([^/]+)/([^/]+)/([^/]+)$}) {
        if (not $has_login->{$1}) {
          push @{$_[0]->{$has_bg ? '_deploy_jobs' : '_deploy'}->{$def->{branch}} ||= []},
              'docker login -e $DOCKER_EMAIL -u $DOCKER_USER -p $DOCKER_PASS '.$1.' || docker login -u $DOCKER_USER -p $DOCKER_PASS '.$1;
          $has_login->{$1} = 1;
        }
      } else {
        if (not $has_login->{''}) {
          push @{$_[0]->{$has_bg ? '_deploy_jobs' : '_deploy'}->{$def->{branch}} ||= []},
              'docker login -e $DOCKER_EMAIL -u $DOCKER_USER -p $DOCKER_PASS || docker login -u $DOCKER_USER -p $DOCKER_PASS';
          $has_login->{''} = 1;
        }
      }

      push @{$_[0]->{$has_bg ? '_deploy_jobs' : '_deploy'}->{$def->{branch}} ||= []},
          'docker push ' . $name . ' && ' .
          'curl -sSLf $BWALL_URL'.(defined $def->{bwall_suffix} ? '.' . $def->{bwall_suffix} : $def->{branch} eq 'master' ? '' : '.' . $def->{branch}).' -X POST';
    } # $def
  },
};

$Options->{'circleci', 'build'} = {
  set => sub {
    push @{$_[0]->{_build} ||= []}, @{$_[1]};
  },
};

$Options->{'circleci', 'tests'} = {
  set => sub {
    if (ref $_[1] eq 'HASH') {
      die "No |build_generated_files|"
          unless defined $_[0]->{_build_generated_files};
      for (sort { $a cmp $b } keys %{$_[1]}) {
        push @{$_[0]->{_test_jobs}->{$_} ||= []}, @{$_[1]->{$_}};
      }
    } else {
      push @{$_[0]->{_test} ||= []}, @{$_[1]};
    }
  },
};

$Options->{'circleci', 'make_deploy_branches'} = {
  set => sub {
    my $has_bg = !! $_[0]->{_build_generated_files};
    for (@{$_[1]}) {
      my $branch;
      my $testless;
      if (ref $_) {
        $branch = $_->{name};
        $testless = $_->{testless};
      } else {
        $branch = $_;
      }
      die "No |build_generated_files|" if $testless and not $has_bg;
      push @{$_[0]->{$testless ? '_early_deploy_jobs' : $has_bg ? '_deploy_jobs' : '_deploy'}->{$branch} ||= []},
          "make deploy-$branch";
    }
  },
};

$Options->{'circleci', 'deploy'} = {
  set => sub {
    my $def = $_[1];
    if (ref $_[1] eq 'ARRAY') {
      $def = {branch => 'master', commands => $_[1]};
    }
    my $has_bg = !! $_[0]->{_build_generated_files};
    push @{$_[0]->{$has_bg ? '_deploy_jobs' : '_deploy'}->{$def->{branch}} ||= []},
        @{$def->{commands}};
  },
};

$Options->{'circleci', 'deploy_branch'} = {
  set => sub {
    my $def = $_[1];
    my $has_bg = !! $_[0]->{_build_generated_files};
    for my $branch (sort { $a cmp $b } keys %$def) {
      push @{$_[0]->{$has_bg ? '_deploy_jobs' : '_deploy'}->{$branch} ||= []}, @{$def->{$branch}};
    }
  },
};

$Options->{'circleci', 'merger'} = {
  set => sub {
    my $json = $_[0];
    return unless $_[1];
    my $into = 'master';
    if (ref $_[1] eq 'HASH') {
      $into = $_[1]->{into} if defined $_[1]->{into};
    }
    for my $branch (qw(staging nightly)) {
      push @{$json->{_deploy_jobs}->{$branch} ||= []}, join "\n",
          'git rev-parse HEAD > head.txt',
          'curl -f -s -S --request POST --header "Authorization:token $GITHUB_ACCESS_TOKEN" --header "Content-Type:application/json" --data-binary "{\"base\":\"'.$into.'\",\"head\":\"`cat head.txt`\",\"commit_message\":\"auto-merge $CIRCLE_BRANCH into '.$into.'\"}" "https://api.github.com/repos/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/merges"';
    } # $branch
  },
};

$Options->{'circleci', 'awscli'} = {
  set => sub {
    return unless $_[1];
    push @{$_[0]->{_build} ||= []}, install_awscli_command ();
  },
};

$Options->{'circleci', 'parallel'} = {
  set => sub {
    return unless $_[1];
    return if ref $_[1] eq 'SCALAR' and not ${$_[1]};
    my $value = 2;
    if (not ref $_[1]) {
      $value = 0+$_[1];
      $value = 2 if $value < 2;
    }
    $_[0]->{_parallel} = $value;
  },
};

$Options->{'circleci', 'empty'} = {
  set => sub {
    $_[0]->{_empty} = 1;
  },
};

$Options->{'circleci', 'gaa'} = {
  set => sub {
    my $json = $_[0];
    $json->{jobs}->{gaa4} = new_job;
    $json->{jobs}->{gaa4}->{steps} = [
        "checkout",
        circle_step (join ";",
          'git config --global user.email "temp@circleci.test"',
          'git config --global user.name "CircleCI"',
        ),
        circle_step ("make deps"),
        circle_step ("make updatenightly"),
        circle_step ("git commit -m auto", deploy => 1),
        circle_step ("git push origin +`git rev-parse HEAD`:refs/heads/nightly", deploy => 1),
    ];
    my $hour = int ($json->{_random_day_time} / 60);
    my $minute = ($json->{_random_day_time}) % 60;
    $json->{workflows}->{gaa4} = {
      "jobs" => ["gaa4"],
      "triggers" => [
        {
          "schedule" => {
            "cron" => "$minute $hour * * *",
            "filters" => {
              "branches" => {
                "only" => [
                  "staging"
                ]
              }
            }
          }
        }
      ],
    };
  },
};

sub generate ($$$;%) {
  my ($class, $input, $root_path, %args) = @_;

  my $data = {};
  my $random_day_time = ((($args{input_length} || 0) + 12*60 + 21)) % (24*60);

  for my $platform (sort { $a cmp $b } keys %$input) {
    my $p_def = $Platforms->{$platform};
    die "Unknown platform |$platform|" unless defined $p_def;
    my $json = {};
    local $json->{_random_day_time} = $random_day_time;

    for my $opt (sort { $a cmp $b } keys %{$input->{$platform}}) {
      my $o_def = $Options->{$platform, $opt};
      die "Unknown option |$platform|, |$opt|" unless defined $o_def;
      my $o_param = $input->{$platform}->{$opt};
      $o_def->{set}->($json, $o_param, $root_path);
    } # $opt

    $p_def->{set}->($json);

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

Copyright 2018-2020 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
