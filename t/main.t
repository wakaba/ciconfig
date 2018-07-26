use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('t_deps/modules/*/lib');
use Test::X1;
use Test::Differences;
use Main;

for (
  [{} => {}],

  [{travisci => {}} => {'.travis.yml' => {json => {
    jobs => {include => [{stage => 'test'}]},
  }}}],
  [{travisci => {pmbp => 'latest'}} => {'.travis.yml' => {json => {
    jobs => {include => [{stage => 'test'}]},
    git => {submodules => \0},
    language => 'perl',
    perl => ['5.26'],
    before_install => 'true',
    install => 'make test-deps',
    script => 'make test',
  }}}],
  [{travisci => {pmbp => '5.8+'}} => {'.travis.yml' => {json => {
    jobs => {include => [{stage => 'test'}]},
    git => {submodules => \0},
    language => 'perl',
    perl => ['5.26', '5.14', '5.8'],
    before_install => 'true',
    install => 'make test-deps',
    script => 'make test',
  }}}],
  [{travisci => {pmbp => '5.10+'}} => {'.travis.yml' => {json => {
    jobs => {include => [{stage => 'test'}]},
    git => {submodules => \0},
    language => 'perl',
    perl => ['5.26', '5.14', '5.10'],
    before_install => 'true',
    install => 'make test-deps',
    script => 'make test',
  }}}],
  [{travisci => {pmbp => '5.12+'}} => {'.travis.yml' => {json => {
    jobs => {include => [{stage => 'test'}]},
    git => {submodules => \0},
    language => 'perl',
    perl => ['5.26', '5.14', '5.12'],
    before_install => 'true',
    install => 'make test-deps',
    script => 'make test',
  }}}],
  [{travisci => {pmbp => '5.14+'}} => {'.travis.yml' => {json => {
    jobs => {include => [{stage => 'test'}]},
    git => {submodules => \0},
    language => 'perl',
    perl => ['5.26', '5.14'],
    before_install => 'true',
    install => 'make test-deps',
    script => 'make test',
  }}}],
  [{travisci => {pmbp => 1}} => {'.travis.yml' => {json => {
    jobs => {include => [{stage => 'test'}]},
    git => {submodules => \0},
    language => 'perl',
    perl => ['5.26', '5.14', '5.8'],
    before_install => 'true',
    install => 'make test-deps',
    script => 'make test',
  }}}],
  [{travisci => {notifications => 'suika'}} => {'.travis.yml' => {json => {
    jobs => {include => [{stage => 'test'}]},
    notifications => {
      email => ['wakaba@suikawiki.org'],
      irc => {channels => ['ircs://irc.suikawiki.org:6697#mechanize'], use_notice => \1},
    },
  }}}],
  [{travisci => {merger => 1}} => {'.travis.yml' => {json => {
    env => {global => {secure => "ab xxx 314444\n"}},
    jobs => {include => [
      {stage => 'test'},
      {stage => 'merge',
       before_install => "true",
       install => "true",
       script => 'curl -f https://gist.githubusercontent.com/wakaba/ab553f86cd017e0cb28c6dbb5364b009/raw/travis-merge-job.pl | perl'},
    ]},
  }}}],

  [{circleci => {}} => {'circle.yml' => {json => {}}}],
  [{circleci => {gaa => 1}} => {'circle.yml' => {json => {}}}],
  [{circleci => {required_docker_images => ['a/b', 'a/b/c']}} => {'circle.yml' => {json => {
    machine => {services => ['docker']},
    dependencies => {override => [
      'docker info',
      {'docker pull a/b && docker pull a/b/c' => {background => 1}},
    ]},
  }}}],
  [{circleci => {heroku => 1}} => {'circle.yml' => {json => {
    dependencies => {override => [
      'git config --global user.email "temp@circleci.test"',
      'git config --global user.name "CircleCI"',
    ]},
    deployment => {
      master => {
        branch => 'master',
        commands => [
          'git checkout --orphan herokucommit && git commit -m "Heroku base commit"',
          'make create-commit-for-heroku',
          'git push git@heroku.com:$HEROKU_APP_NAME.git +`git rev-parse HEAD`:refs/heads/master',
        ],
      },
    },
  }}}],
  [{circleci => {heroku => {prepare => [
    'abc', './foo bar',
  ]}}} => {'circle.yml' => {json => {
    dependencies => {override => [
      'git config --global user.email "temp@circleci.test"',
      'git config --global user.name "CircleCI"',
    ]},
    deployment => {
      master => {
        branch => 'master',
        commands => [
          'git checkout --orphan herokucommit && git commit -m "Heroku base commit"',
          'abc',
          './foo bar',
          'make create-commit-for-heroku',
          'git push git@heroku.com:$HEROKU_APP_NAME.git +`git rev-parse HEAD`:refs/heads/master',
        ],
      },
    },
  }}}],
  [{circleci => {heroku => {pushed => [
    'abc', './foo bar',
  ]}}} => {'circle.yml' => {json => {
    dependencies => {override => [
      'git config --global user.email "temp@circleci.test"',
      'git config --global user.name "CircleCI"',
    ]},
    deployment => {
      master => {
        branch => 'master',
        commands => [
          'git checkout --orphan herokucommit && git commit -m "Heroku base commit"',
          'make create-commit-for-heroku',
          'git push git@heroku.com:$HEROKU_APP_NAME.git +`git rev-parse HEAD`:refs/heads/master',
          'abc',
          './foo bar',
        ],
      },
    },
  }}}],
  [{circleci => {deploy => ['true', 'false']}} => {'circle.yml' => {json => {
    deployment => {
      master => {
        branch => 'master',
        commands => ['true', 'false'],
      },
    },
  }}}],
  [{circleci => {deploy => {
    branch => 'oge',
    commands => ['true', 'false'],
  }}} => {'circle.yml' => {json => {
    deployment => {
      oge => {
        branch => 'oge',
        commands => ['true', 'false'],
      },
    },
  }}}],
  [{circleci => {
    make_deploy_branches => ['master', 'staging'],
  }} => {'circle.yml' => {json => {
    deployment => {
      master => {
        branch => 'master',
        commands => ['make deploy-master'],
      },
      staging => {
        branch => 'staging',
        commands => ['make deploy-staging'],
      },
    },
  }}}],
  [{circleci => {merger => 1}} => {'circle.yml' => {json => {
    deployment => {
      nightly => {
        branch => 'nightly',
        commands => [
          'git rev-parse HEAD > head.txt',
          'curl -f -s -S --request POST --header "Authorization:token $GITHUB_ACCESS_TOKEN" --header "Content-Type:application/json" --data-binary "{\\"base\\":\\"master\\",\\"head\\":\\"`cat head.txt`\\",\\"commit_message\\":\\"auto-merge $CIRCLE_BRANCH into master\\"}" "https://api.github.com/repos/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/merges"',
        ],
      },
      staging => {
        branch => 'staging',
        commands => [
          'git rev-parse HEAD > head.txt',
          'curl -f -s -S --request POST --header "Authorization:token $GITHUB_ACCESS_TOKEN" --header "Content-Type:application/json" --data-binary "{\\"base\\":\\"master\\",\\"head\\":\\"`cat head.txt`\\",\\"commit_message\\":\\"auto-merge $CIRCLE_BRANCH into master\\"}" "https://api.github.com/repos/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/merges"',
        ],
      },
    },
  }}}],
  [{circleci => {merger => {into => 'dev'}}} => {'circle.yml' => {json => {
    deployment => {
      nightly => {
        branch => 'nightly',
        commands => [
          'git rev-parse HEAD > head.txt',
          'curl -f -s -S --request POST --header "Authorization:token $GITHUB_ACCESS_TOKEN" --header "Content-Type:application/json" --data-binary "{\\"base\\":\\"dev\\",\\"head\\":\\"`cat head.txt`\\",\\"commit_message\\":\\"auto-merge $CIRCLE_BRANCH into dev\\"}" "https://api.github.com/repos/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/merges"',
        ],
      },
      staging => {
        branch => 'staging',
        commands => [
          'git rev-parse HEAD > head.txt',
          'curl -f -s -S --request POST --header "Authorization:token $GITHUB_ACCESS_TOKEN" --header "Content-Type:application/json" --data-binary "{\\"base\\":\\"dev\\",\\"head\\":\\"`cat head.txt`\\",\\"commit_message\\":\\"auto-merge $CIRCLE_BRANCH into dev\\"}" "https://api.github.com/repos/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/merges"',
        ],
      },
    },
  }}}],
) {
  my ($input, $expected) = @$_;
  for (qw(.travis.yml circle.yml)) {
    $expected->{$_} ||= {remove => 1};
  }
  test {
    my $c = shift;
    my $path = path (__FILE__)->parent->parent->child ('t_deps/data');
    my $output = Main->generate ($input, $path);
    eq_or_diff $output, $expected;
    done $c;
  } n => 1;
}

run_tests;

=head1 LICENSE

Copyright 2018 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
