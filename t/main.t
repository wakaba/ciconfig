use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('t_deps/modules/*/lib');
use Test::X1;
use Test::More;
use Main;
use JSON::PS;

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
  [{circleci => {'docker-build' => 'abc/def'}} => {'.circleci/config.yml' => {json => {
    version => 2,
    jobs => {build => {
      machine => {enabled => \1},
      environment => {CIRCLE_ARTIFACTS => '/tmp/circle-artifacts'},
      steps => [
        'checkout',
        {run => {command => 'mkdir -p $CIRCLE_ARTIFACTS'}},
        {run => {command => 'docker info'}},
        {run => {command => 'docker build -t abc/def .'}},
        {store_artifacts => {path => '/tmp/circle-artifacts'}},
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == 'master' ]; then} ."\x0Atrue\x0A" . 'docker login -e $DOCKER_EMAIL -u $DOCKER_USER -p $DOCKER_PASS || docker login -u $DOCKER_USER -p $DOCKER_PASS' . "\x0Afi"}},
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == 'master' ]; then} ."\x0Atrue\x0A" . 'docker push abc/def && curl -sSLf $BWALL_URL -X POST' . "\x0Afi"}},
      ],
    }},
    workflows => {version => 2, build => {jobs => ['build']}},
  }}}],
  [{circleci => {'docker-build' => 'xyz/abc/def'}} => {'.circleci/config.yml' => {json => {
    version => 2,
    jobs => {build => {
      machine => {enabled => \1},
      environment => {CIRCLE_ARTIFACTS => '/tmp/circle-artifacts'},
      steps => [
        'checkout',
        {run => {command => 'mkdir -p $CIRCLE_ARTIFACTS'}},
        {run => {command => 'docker info'}},
        {run => {command => 'docker build -t xyz/abc/def .'}},
        {store_artifacts => {path => '/tmp/circle-artifacts'}},
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == 'master' ]; then} ."\x0Atrue\x0A" . 'docker login -e $DOCKER_EMAIL -u $DOCKER_USER -p $DOCKER_PASS xyz || docker login -u $DOCKER_USER -p $DOCKER_PASS xyz' . "\x0Afi"}},
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == 'master' ]; then} ."\x0Atrue\x0A" . 'docker push xyz/abc/def && curl -sSLf $BWALL_URL -X POST' . "\x0Afi"}},
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
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == 'master' ]; then} . "\x0Atrue\x0A" . 'git checkout --orphan herokucommit && git commit -m "Heroku base commit"' . "\x0Afi"}},
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == 'master' ]; then} . "\x0Atrue\x0A" . 'make create-commit-for-heroku' . "\x0Afi"}},
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == 'master' ]; then} . "\x0Atrue\x0A" . 'git push git@heroku.com:$HEROKU_APP_NAME.git +`git rev-parse HEAD`:refs/heads/master' . "\x0Afi"}},
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
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == 'master' ]; then} . "\x0Atrue\x0A" . 'git checkout --orphan herokucommit && git commit -m "Heroku base commit"' . "\x0Afi"}},
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == 'master' ]; then} . "\x0Atrue\x0A" . 'abc' . "\x0Afi"}},
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == 'master' ]; then} . "\x0Atrue\x0A" . './foo bar' . "\x0Afi"}},
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == 'master' ]; then} . "\x0Atrue\x0A" . 'make create-commit-for-heroku' . "\x0Afi"}},
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == 'master' ]; then} . "\x0Atrue\x0A" . 'git push git@heroku.com:$HEROKU_APP_NAME.git +`git rev-parse HEAD`:refs/heads/master' . "\x0Afi"}},
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
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == 'master' ]; then} . "\x0Atrue\x0A" . 'git checkout --orphan herokucommit && git commit -m "Heroku base commit"' . "\x0Afi"}},
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == 'master' ]; then} . "\x0Atrue\x0A" . 'make create-commit-for-heroku' . "\x0Afi"}},
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == 'master' ]; then} . "\x0Atrue\x0A" . 'git push git@heroku.com:$HEROKU_APP_NAME.git +`git rev-parse HEAD`:refs/heads/master' . "\x0Afi"}},
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == 'master' ]; then} . "\x0Atrue\x0A" . 'abc' . "\x0Afi"}},
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == 'master' ]; then} . "\x0Atrue\x0A" . './foo bar' . "\x0Afi"}},
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
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == 'master' ]; then} . "\x0Atrue\x0A" . 'true' . "\x0Afi"}},
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == 'master' ]; then} . "\x0Atrue\x0A" . 'false' . "\x0Afi"}},
      ],
    }},
    workflows => {version => 2, build => {jobs => ['build']}},
  }}}],
  [{circleci => {deploy => {
    branch => q{oge"'\\x-},
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
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == 'oge"\\'\\\\x-' ]; then} . "\x0Atrue\x0A" . 'true' . "\x0Afi"}},
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == 'oge"\\'\\\\x-' ]; then} . "\x0Atrue\x0A" . 'false' . "\x0Afi"}},
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
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == 'master' ]; then} . "\x0Atrue\x0A" . 'make deploy-master' . "\x0Afi"}},
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == 'staging' ]; then} . "\x0Atrue\x0A" . 'make deploy-staging' . "\x0Afi"}},
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
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == 'nightly' ]; then} . "\x0Atrue\x0A" . 'git rev-parse HEAD > head.txt' . "\x0A" .
          'curl -f -s -S --request POST --header "Authorization:token $GITHUB_ACCESS_TOKEN" --header "Content-Type:application/json" --data-binary "{\\"base\\":\\"master\\",\\"head\\":\\"`cat head.txt`\\",\\"commit_message\\":\\"auto-merge $CIRCLE_BRANCH into master\\"}" "https://api.github.com/repos/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/merges"' . "\x0Afi"}},
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == 'staging' ]; then} . "\x0Atrue\x0A" . 'git rev-parse HEAD > head.txt' . "\x0A" .
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
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == 'nightly' ]; then} . "\x0Atrue\x0A" . 'git rev-parse HEAD > head.txt' . "\x0A" .
          'curl -f -s -S --request POST --header "Authorization:token $GITHUB_ACCESS_TOKEN" --header "Content-Type:application/json" --data-binary "{\\"base\\":\\"dev\\",\\"head\\":\\"`cat head.txt`\\",\\"commit_message\\":\\"auto-merge $CIRCLE_BRANCH into dev\\"}" "https://api.github.com/repos/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/merges"' . "\x0Afi"}},
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == 'staging' ]; then} . "\x0Atrue\x0A" . 'git rev-parse HEAD > head.txt' . "\x0A" .
          'curl -f -s -S --request POST --header "Authorization:token $GITHUB_ACCESS_TOKEN" --header "Content-Type:application/json" --data-binary "{\\"base\\":\\"dev\\",\\"head\\":\\"`cat head.txt`\\",\\"commit_message\\":\\"auto-merge $CIRCLE_BRANCH into dev\\"}" "https://api.github.com/repos/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/merges"' . "\x0Afi"}},
      ],
    }},
    workflows => {version => 2, build => {jobs => ['build']}},
  }}}],
  [{circleci => {awscli => 1}} => {'.circleci/config.yml' => {json => {
    version => 2,
    jobs => {build => {
      machine => {enabled => \1},
      environment => {CIRCLE_ARTIFACTS => '/tmp/circle-artifacts'},
      steps => [
        'checkout',
        {run => {command => 'mkdir -p $CIRCLE_ARTIFACTS'}},
        {run => {command => "(((sudo apt-cache search python-dev | grep ^python-dev) || sudo apt-get update) && sudo apt-get install -y python-dev) || (sudo apt-get update && sudo apt-get install -y python-dev)\n".
                 "sudo pip install awscli --upgrade\n".
                 "aws --version"}},
        {store_artifacts => {path => '/tmp/circle-artifacts'}},
      ],
    }},
    workflows => {version => 2, build => {jobs => ['build']}},
  }}}],
  [{circleci => {parallel => \1}} => {'.circleci/config.yml' => {json => {
    version => 2,
    jobs => {build => {
      parallelism => 2,
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
  [{circleci => {parallel => 1}} => {'.circleci/config.yml' => {json => {
    version => 2,
    jobs => {build => {
      parallelism => 2,
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
  [{circleci => {parallel => 4}} => {'.circleci/config.yml' => {json => {
    version => 2,
    jobs => {build => {
      parallelism => 4,
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
  [{circleci => {parallel => 0}} => {'.circleci/config.yml' => {json => {
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
  [{circleci => {parallel => \0}} => {'.circleci/config.yml' => {json => {
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
  [{circleci => {build => [
    {command => 'a'},
    {command => 'b', branch => 'c'},
  ]}} => {'.circleci/config.yml' => {json => {
    version => 2,
    jobs => {build => {
      machine => {enabled => \1},
      environment => {CIRCLE_ARTIFACTS => '/tmp/circle-artifacts'},
      steps => [
        'checkout',
        {run => {command => 'mkdir -p $CIRCLE_ARTIFACTS'}},
        {run => {command => 'a'}},
        {run => {command => q{if [ "${CIRCLE_BRANCH}" == 'c' ]; then} . "\x0Atrue\x0A" . 'b' . "\x0Afi"}},
        {store_artifacts => {path => '/tmp/circle-artifacts'}},
      ],
    }},
    workflows => {version => 2, build => {jobs => ['build']}},
  }}}],
  [{circleci => {build => [
    {command => 'a', parallel => 1},
    {command => 'b', parallel => 0},
  ]}} => {'.circleci/config.yml' => {json => {
    version => 2,
    jobs => {build => {
      machine => {enabled => \1},
      environment => {CIRCLE_ARTIFACTS => '/tmp/circle-artifacts'},
      steps => [
        'checkout',
        {run => {command => 'mkdir -p $CIRCLE_ARTIFACTS'}},
        {run => {command => 'a'}},
        {run => {command => q{if [ "${CIRCLE_NODE_INDEX}" == "0" ]; then} . "\x0A" . "true\x0A" . 'b' . "\x0Afi"}},
        {store_artifacts => {path => '/tmp/circle-artifacts'}},
      ],
    }},
    workflows => {version => 2, build => {jobs => ['build']}},
  }}}],
  [{circleci => {build => [
    {command => ['a', 'b']},
  ]}} => {'.circleci/config.yml' => {json => {
    version => 2,
    jobs => {build => {
      machine => {enabled => \1},
      environment => {CIRCLE_ARTIFACTS => '/tmp/circle-artifacts'},
      steps => [
        'checkout',
        {run => {command => 'mkdir -p $CIRCLE_ARTIFACTS'}},
        {run => {command => 'a' . "\n" . 'b'}},
        {store_artifacts => {path => '/tmp/circle-artifacts'}},
      ],
    }},
    workflows => {version => 2, build => {jobs => ['build']}},
  }}}],
  [{circleci => {build => [
    {command => ['a', 'b']},
  ], deploy_branch => {
    b1 => ['c'],
    b2 => ['d'],
  }}} => {'.circleci/config.yml' => {json => {
    version => 2,
    jobs => {build => {
      machine => {enabled => \1},
      environment => {CIRCLE_ARTIFACTS => '/tmp/circle-artifacts'},
      steps => [
        'checkout',
        {run => {command => 'mkdir -p $CIRCLE_ARTIFACTS'}},
        {run => {command => 'a' . "\n" . 'b'}},
        {store_artifacts => {path => '/tmp/circle-artifacts'}},
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == 'b1' ]; then} . "\x0Atrue\x0A" . 'c' . "\x0Afi"}},
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == 'b2' ]; then} . "\x0Atrue\x0A" . 'd' . "\x0Afi"}},
      ],
    }},
    workflows => {version => 2, build => {jobs => ['build']}},
  }}}],
  [{circleci => {
    empty => 1,
  }} => {'.circleci/config.yml' => {json => {
    version => 2,
    jobs => {},
    workflows => {version => 2},
  }}}],
  [{circleci => {
    gaa => 1,
    empty => 1,
  }} => {'.circleci/config.yml' => {json => {
    version => 2,
    jobs => {
      gaa4 => {
        machine => {enabled => \1},
        environment => {CIRCLE_ARTIFACTS => '/tmp/circle-artifacts'},
        steps => [
          "checkout",
          {run => {command => 'make updatenightly'}},
          {deploy => {command => 'git commit -m auto'}},
          {deploy => {command => 'git push origin +nightly'}},
        ],
      },
    },
    workflows => {version => 2, gaa4 => {
      jobs => ['gaa4'],
      "triggers" => [
        {
          "schedule" => {
            "cron" => "23 13 * * *",
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
    }},
  }}}],
  [{circleci => {gaa => 1}} => {'.circleci/config.yml' => {json => {
    version => 2,
    jobs => {
      gaa4 => {
        machine => {enabled => \1},
        environment => {CIRCLE_ARTIFACTS => '/tmp/circle-artifacts'},
        steps => [
          "checkout",
          {run => {command => 'make updatenightly'}},
          {deploy => {command => 'git commit -m auto'}},
          {deploy => {command => 'git push origin +nightly'}},
        ],
      },
      build => {
        machine => {enabled => \1},
        environment => {CIRCLE_ARTIFACTS => '/tmp/circle-artifacts'},
        steps => [
          'checkout',
          {run => {command => 'mkdir -p $CIRCLE_ARTIFACTS'}},
          {store_artifacts => {path => '/tmp/circle-artifacts'}},
        ],
      },
    },
    workflows => {version => 2, , gaa4 => {
      jobs => ['gaa4'],
      "triggers" => [
        {
          "schedule" => {
            "cron" => "4 13 * * *",
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
    }, build => {jobs => ['build']}},
  }}}],
) {
  my ($input, $expected) = @$_;
  for (qw(.travis.yml circle.yml .circleci/config.yml)) {
    $expected->{$_} ||= {remove => 1};
  }
  test {
    my $c = shift;
    my $path = path (__FILE__)->parent->parent->child ('t_deps/data');
    my $output = Main->generate ($input, $path, input_length => length perl2json_bytes_for_record $input);
    #use Test::Differences;
    #eq_or_diff $output, $expected;
    is_deeply $output, $expected;
    done $c;
  } n => 1;
}

run_tests;

=head1 LICENSE

Copyright 2018-2020 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
