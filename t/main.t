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

  [{circleci => {}} => {'.circleci/config.yml' => {json => {
    version => 2,
    jobs => {build => {
      machine => {enabled => \1},
      environment => {CIRCLE_ARTIFACTS => '/tmp/circle-artifacts'},
      steps => [
        'checkout',
        {run => {command => 'mkdir -p $CIRCLE_ARTIFACTS'}},
        {store_artifacts => {path => '/tmp/circle-artifacts'}},
      ],
    }},
    workflows => {version => 2, build => {jobs => ['build']}},
  }}}],
  [{circleci => {gaa => 1}} => {'.circleci/config.yml' => {json => {
    version => 2,
    jobs => {build => {
      machine => {enabled => \1},
      environment => {CIRCLE_ARTIFACTS => '/tmp/circle-artifacts'},
      steps => [
        'checkout',
        {run => {command => 'mkdir -p $CIRCLE_ARTIFACTS'}},
        {store_artifacts => {path => '/tmp/circle-artifacts'}},
      ],
    }},
    workflows => {version => 2, build => {jobs => ['build']}},
  }}}],
  [{circleci => {required_docker_images => ['a/b', 'a/b/c']}} => {'.circleci/config.yml' => {json => {
    version => 2,
    jobs => {build => {
      machine => {enabled => \1},
      environment => {CIRCLE_ARTIFACTS => '/tmp/circle-artifacts'},
      steps => [
        'checkout',
        {run => {command => 'mkdir -p $CIRCLE_ARTIFACTS'}},
        {run => {command => 'docker info'}},
        {run => {command => 'docker pull a/b && docker pull a/b/c',
                 background => \1}},
        {store_artifacts => {path => '/tmp/circle-artifacts'}},
      ],
    }},
    workflows => {version => 2, build => {jobs => ['build']}},
  }}}],
  [{circleci => {heroku => 1}} => {'.circleci/config.yml' => {json => {
    version => 2,
    jobs => {build => {
      machine => {enabled => \1},
      environment => {CIRCLE_ARTIFACTS => '/tmp/circle-artifacts'},
      steps => [
        'checkout',
        {run => {command => 'mkdir -p $CIRCLE_ARTIFACTS'}},
        {run => {command => 
      'git config --global user.email "temp@circleci.test"' . "\x0A" .
      'git config --global user.name "CircleCI"'
        }},
        {store_artifacts => {path => '/tmp/circle-artifacts'}},
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == "master" ]; then} . "\x0A" . 'git checkout --orphan herokucommit && git commit -m "Heroku base commit"' . "\x0Afi"}},
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == "master" ]; then} . "\x0A" . 'make create-commit-for-heroku' . "\x0Afi"}},
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == "master" ]; then} . "\x0A" . 'git push git@heroku.com:$HEROKU_APP_NAME.git +`git rev-parse HEAD`:refs/heads/master' . "\x0Afi"}},
      ],
    }},
    workflows => {version => 2, build => {jobs => ['build']}},
  }}}],
  [{circleci => {heroku => {prepare => [
    'abc', './foo bar',
  ]}}} => {'.circleci/config.yml' => {json => {
    version => 2,
    jobs => {build => {
      machine => {enabled => \1},
      environment => {CIRCLE_ARTIFACTS => '/tmp/circle-artifacts'},
      steps => [
        'checkout',
        {run => {command => 'mkdir -p $CIRCLE_ARTIFACTS'}},
        {run => {command => 
      'git config --global user.email "temp@circleci.test"' . "\x0A" .
      'git config --global user.name "CircleCI"'
        }},
        {store_artifacts => {path => '/tmp/circle-artifacts'}},
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == "master" ]; then} . "\x0A" . 'git checkout --orphan herokucommit && git commit -m "Heroku base commit"' . "\x0Afi"}},
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == "master" ]; then} . "\x0A" . 'abc' . "\x0Afi"}},
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == "master" ]; then} . "\x0A" . './foo bar' . "\x0Afi"}},
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == "master" ]; then} . "\x0A" . 'make create-commit-for-heroku' . "\x0Afi"}},
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == "master" ]; then} . "\x0A" . 'git push git@heroku.com:$HEROKU_APP_NAME.git +`git rev-parse HEAD`:refs/heads/master' . "\x0Afi"}},
      ],
    }},
    workflows => {version => 2, build => {jobs => ['build']}},
  }}}],
  [{circleci => {heroku => {pushed => [
    'abc', './foo bar',
  ]}}} => {'.circleci/config.yml' => {json => {
    version => 2,
    jobs => {build => {
      machine => {enabled => \1},
      environment => {CIRCLE_ARTIFACTS => '/tmp/circle-artifacts'},
      steps => [
        'checkout',
        {run => {command => 'mkdir -p $CIRCLE_ARTIFACTS'}},
        {run => {command => 
      'git config --global user.email "temp@circleci.test"' . "\x0A" .
      'git config --global user.name "CircleCI"'
        }},
        {store_artifacts => {path => '/tmp/circle-artifacts'}},
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == "master" ]; then} . "\x0A" . 'git checkout --orphan herokucommit && git commit -m "Heroku base commit"' . "\x0Afi"}},
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == "master" ]; then} . "\x0A" . 'make create-commit-for-heroku' . "\x0Afi"}},
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == "master" ]; then} . "\x0A" . 'git push git@heroku.com:$HEROKU_APP_NAME.git +`git rev-parse HEAD`:refs/heads/master' . "\x0Afi"}},
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == "master" ]; then} . "\x0A" . 'abc' . "\x0Afi"}},
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == "master" ]; then} . "\x0A" . './foo bar' . "\x0Afi"}},
      ],
    }},
    workflows => {version => 2, build => {jobs => ['build']}},
  }}}],
  [{circleci => {deploy => ['true', 'false']}} => {'.circleci/config.yml' => {json => {
    version => 2,
    jobs => {build => {
      machine => {enabled => \1},
      environment => {CIRCLE_ARTIFACTS => '/tmp/circle-artifacts'},
      steps => [
        'checkout',
        {run => {command => 'mkdir -p $CIRCLE_ARTIFACTS'}},
        {store_artifacts => {path => '/tmp/circle-artifacts'}},
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == "master" ]; then} . "\x0A" . 'true' . "\x0Afi"}},
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == "master" ]; then} . "\x0A" . 'false' . "\x0Afi"}},
      ],
    }},
    workflows => {version => 2, build => {jobs => ['build']}},
  }}}],
  [{circleci => {deploy => {
    branch => 'oge',
    commands => ['true', 'false'],
  }}} => {'.circleci/config.yml' => {json => {
    version => 2,
    jobs => {build => {
      machine => {enabled => \1},
      environment => {CIRCLE_ARTIFACTS => '/tmp/circle-artifacts'},
      steps => [
        'checkout',
        {run => {command => 'mkdir -p $CIRCLE_ARTIFACTS'}},
        {store_artifacts => {path => '/tmp/circle-artifacts'}},
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == "oge" ]; then} . "\x0A" . 'true' . "\x0Afi"}},
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == "oge" ]; then} . "\x0A" . 'false' . "\x0Afi"}},
      ],
    }},
    workflows => {version => 2, build => {jobs => ['build']}},
  }}}],
  [{circleci => {
    make_deploy_branches => ['master', 'staging'],
  }} => {'.circleci/config.yml' => {json => {
    version => 2,
    jobs => {build => {
      machine => {enabled => \1},
      environment => {CIRCLE_ARTIFACTS => '/tmp/circle-artifacts'},
      steps => [
        'checkout',
        {run => {command => 'mkdir -p $CIRCLE_ARTIFACTS'}},
        {store_artifacts => {path => '/tmp/circle-artifacts'}},
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == "master" ]; then} . "\x0A" . 'make deploy-master' . "\x0Afi"}},
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == "staging" ]; then} . "\x0A" . 'make deploy-staging' . "\x0Afi"}},
      ],
    }},
    workflows => {version => 2, build => {jobs => ['build']}},
  }}}],
  [{circleci => {merger => 1}} => {'.circleci/config.yml' => {json => {
    version => 2,
    jobs => {build => {
      machine => {enabled => \1},
      environment => {CIRCLE_ARTIFACTS => '/tmp/circle-artifacts'},
      steps => [
        'checkout',
        {run => {command => 'mkdir -p $CIRCLE_ARTIFACTS'}},
        {store_artifacts => {path => '/tmp/circle-artifacts'}},
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == "nightly" ]; then} . "\x0A" . 'git rev-parse HEAD > head.txt' . "\x0A" .
          'curl -f -s -S --request POST --header "Authorization:token $GITHUB_ACCESS_TOKEN" --header "Content-Type:application/json" --data-binary "{\\"base\\":\\"master\\",\\"head\\":\\"`cat head.txt`\\",\\"commit_message\\":\\"auto-merge $CIRCLE_BRANCH into master\\"}" "https://api.github.com/repos/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/merges"' . "\x0Afi"}},
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == "staging" ]; then} . "\x0A" . 'git rev-parse HEAD > head.txt' . "\x0A" .
          'curl -f -s -S --request POST --header "Authorization:token $GITHUB_ACCESS_TOKEN" --header "Content-Type:application/json" --data-binary "{\\"base\\":\\"master\\",\\"head\\":\\"`cat head.txt`\\",\\"commit_message\\":\\"auto-merge $CIRCLE_BRANCH into master\\"}" "https://api.github.com/repos/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/merges"' . "\x0Afi"}},
      ],
    }},
    workflows => {version => 2, build => {jobs => ['build']}},
  }}}],
  [{circleci => {merger => {into => 'dev'}}} => {'.circleci/config.yml' => {json => {
    version => 2,
    jobs => {build => {
      machine => {enabled => \1},
      environment => {CIRCLE_ARTIFACTS => '/tmp/circle-artifacts'},
      steps => [
        'checkout',
        {run => {command => 'mkdir -p $CIRCLE_ARTIFACTS'}},
        {store_artifacts => {path => '/tmp/circle-artifacts'}},
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == "nightly" ]; then} . "\x0A" . 'git rev-parse HEAD > head.txt' . "\x0A" .
          'curl -f -s -S --request POST --header "Authorization:token $GITHUB_ACCESS_TOKEN" --header "Content-Type:application/json" --data-binary "{\\"base\\":\\"dev\\",\\"head\\":\\"`cat head.txt`\\",\\"commit_message\\":\\"auto-merge $CIRCLE_BRANCH into dev\\"}" "https://api.github.com/repos/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/merges"' . "\x0Afi"}},
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == "staging" ]; then} . "\x0A" . 'git rev-parse HEAD > head.txt' . "\x0A" .
          'curl -f -s -S --request POST --header "Authorization:token $GITHUB_ACCESS_TOKEN" --header "Content-Type:application/json" --data-binary "{\\"base\\":\\"dev\\",\\"head\\":\\"`cat head.txt`\\",\\"commit_message\\":\\"auto-merge $CIRCLE_BRANCH into dev\\"}" "https://api.github.com/repos/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/merges"' . "\x0Afi"}},
      ],
    }},
    workflows => {version => 2, build => {jobs => ['build']}},
  }}}],
) {
  my ($input, $expected) = @$_;
  for (qw(.travis.yml circle.yml .circleci/config.yml)) {
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
