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
  }}}],
  [{travisci => {pmbp => 'latest'}} => {'.travis.yml' => {json => {
    git => {submodules => \0},
    language => 'perl',
    perl => ['5.32'],
    before_install => 'true',
    install => 'make test-deps',
    script => 'make test',
  }}}],
  [{travisci => {pmbp => '5.8+'}} => {'.travis.yml' => {json => {
    git => {submodules => \0},
    language => 'perl',
    perl => ['5.32', '5.14', '5.8'],
    before_install => 'true',
    install => 'make test-deps',
    script => 'make test',
  }}}],
  [{travisci => {pmbp => '5.10+'}} => {'.travis.yml' => {json => {
    git => {submodules => \0},
    language => 'perl',
    perl => ['5.32', '5.14', '5.10'],
    before_install => 'true',
    install => 'make test-deps',
    script => 'make test',
  }}}],
  [{travisci => {pmbp => '5.12+'}} => {'.travis.yml' => {json => {
    git => {submodules => \0},
    language => 'perl',
    perl => ['5.32', '5.14', '5.12'],
    before_install => 'true',
    install => 'make test-deps',
    script => 'make test',
  }}}],
  [{travisci => {pmbp => '5.14+'}} => {'.travis.yml' => {json => {
    git => {submodules => \0},
    language => 'perl',
    perl => ['5.32', '5.14'],
    before_install => 'true',
    install => 'make test-deps',
    script => 'make test',
  }}}],
  [{travisci => {pmbp => 1}} => {'.travis.yml' => {json => {
    git => {submodules => \0},
    language => 'perl',
    perl => ['5.32', '5.14', '5.8'],
    before_install => 'true',
    install => 'make test-deps',
    script => 'make test',
  }}}],
  [{travisci => {notifications => 'suika'}} => {'.travis.yml' => {json => {
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
      environment => {CIRCLE_ARTIFACTS => '/tmp/circle-artifacts/build'},
      steps => [
        'checkout',
        {run => {command => 'mkdir -p $CIRCLE_ARTIFACTS'}},
        {store_artifacts => {path => '/tmp/circle-artifacts/build'}},
      ],
    }},
    workflows => {version => 2, build => {jobs => ['build']}},
  }}}],
  [{circleci => {'docker-build' => 'abc/def'}} => {'.circleci/config.yml' => {json => {
    version => 2,
    jobs => {build => {
      machine => {enabled => \1},
      environment => {CIRCLE_ARTIFACTS => '/tmp/circle-artifacts/build'},
      steps => [
        'checkout',
        {run => {command => 'mkdir -p $CIRCLE_ARTIFACTS'}},
        {run => {command => 'docker info'}},
        {run => {command => 'docker build -t abc/def .'}},
        {store_artifacts => {path => '/tmp/circle-artifacts/build'}},
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
      environment => {CIRCLE_ARTIFACTS => '/tmp/circle-artifacts/build'},
      steps => [
        'checkout',
        {run => {command => 'mkdir -p $CIRCLE_ARTIFACTS'}},
        {run => {command => 'docker info'}},
        {run => {command => 'docker build -t xyz/abc/def .'}},
        {store_artifacts => {path => '/tmp/circle-artifacts/build'}},
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == 'master' ]; then} ."\x0Atrue\x0A" . 'docker login -e $DOCKER_EMAIL -u $DOCKER_USER -p $DOCKER_PASS xyz || docker login -u $DOCKER_USER -p $DOCKER_PASS xyz' . "\x0Afi"}},
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == 'master' ]; then} ."\x0Atrue\x0A" . 'docker push xyz/abc/def && curl -sSLf $BWALL_URL -X POST' . "\x0Afi"}},
      ],
    }},
    workflows => {version => 2, build => {jobs => ['build']}},
  }}}],
  [{circleci => {
    'docker-build' => 'xyz/abc/def',
    build_generated_files => [],
  }} => {'.circleci/config.yml' => {json => {
    version => 2,
    jobs => {build => {
      machine => {enabled => \1},
      environment => {CIRCLE_ARTIFACTS => '/tmp/circle-artifacts/build'},
      steps => [
        'checkout',
        {run => {command => 'mkdir -p $CIRCLE_ARTIFACTS'}},
        {run => {command => 'docker info'}},
        {run => {command => 'docker build -t xyz/abc/def .'}},
        {store_artifacts => {path => '/tmp/circle-artifacts/build'}},
        {run => {command => 'mkdir -p .ciconfigtemp/dockerimages/xyz/abc/'}},
        {run => {command => 'docker save -o .ciconfigtemp/dockerimages/xyz/abc/def.tar xyz/abc/def'}},
        {"persist_to_workspace" => {
          "root" => "./",
          "paths" => ['.ciconfigtemp'],
        }},
      ],
    }, test => {
      machine => {enabled => \1},
      environment => {CIRCLE_ARTIFACTS => '/tmp/circle-artifacts/test'},
      steps => [
        'checkout',
        {"attach_workspace" => {"at" => "./"}},
        {run => {command => 'docker load -i .ciconfigtemp/dockerimages/xyz/abc/def.tar'}},
        {run => {command => 'mkdir -p $CIRCLE_ARTIFACTS'}},
        {store_artifacts => {path => '/tmp/circle-artifacts/test'}},
      ],
    }, deploy_master => {
      machine => {enabled => \1},
      steps => [
        'checkout',
        {"attach_workspace" => {"at" => "./"}},
        {run => {command => 'docker load -i .ciconfigtemp/dockerimages/xyz/abc/def.tar'}},
        {deploy => {command => 'docker login -e $DOCKER_EMAIL -u $DOCKER_USER -p $DOCKER_PASS xyz || docker login -u $DOCKER_USER -p $DOCKER_PASS xyz'}},
        {deploy => {command => 'docker push xyz/abc/def && curl -sSLf $BWALL_URL -X POST'}},
      ],
    }},
    workflows => {version => 2, build => {jobs => [
      'build',
      {test => {requires => ['build']}},
      {'deploy_master' => {filters => {branches => {only => ['master']}},
                           requires => ['test']}},
    ]}},
  }}}, 'build jobs / docker'],
  [{circleci => {
    'docker-build' => 'xyz/abc/def',
    build_generated_files => [],
    pmbp => 1,
    build => ["echo 2"],
    tests => ["echo 1"],
  }} => {'.circleci/config.yml' => {json => {
    version => 2,
    jobs => {build => {
      machine => {enabled => \1},
      environment => {CIRCLE_ARTIFACTS => '/tmp/circle-artifacts/build'},
      steps => [
        'checkout',
        {run => {command => 'mkdir -p $CIRCLE_ARTIFACTS'}},
        {run => {command => 'echo 2'}},
        {run => {command => 'docker info'}},
        {run => {command => 'docker build -t xyz/abc/def .'}},
        {run => {command => 'make test-deps'}},
        {store_artifacts => {path => '/tmp/circle-artifacts/build'}},
        {run => {command => 'mkdir -p .ciconfigtemp/dockerimages/xyz/abc/'}},
        {run => {command => 'docker save -o .ciconfigtemp/dockerimages/xyz/abc/def.tar xyz/abc/def'}},
        {"persist_to_workspace" => {
          "root" => "./",
          "paths" => ['.ciconfigtemp'],
        }},
      ],
    }, test => {
      machine => {enabled => \1},
      environment => {CIRCLE_ARTIFACTS => '/tmp/circle-artifacts/test'},
      steps => [
        'checkout',
        {"attach_workspace" => {"at" => "./"}},
        {run => {command => 'docker load -i .ciconfigtemp/dockerimages/xyz/abc/def.tar'}},
        {run => {command => 'mkdir -p $CIRCLE_ARTIFACTS'}},
        {run => {command => 'make test'}},
        {run => {command => 'echo 1'}},
        {store_artifacts => {path => '/tmp/circle-artifacts/test'}},
      ],
    }, deploy_master => {
      machine => {enabled => \1},
      steps => [
        'checkout',
        {"attach_workspace" => {"at" => "./"}},
        {run => {command => 'docker load -i .ciconfigtemp/dockerimages/xyz/abc/def.tar'}},
        {deploy => {command => 'docker login -e $DOCKER_EMAIL -u $DOCKER_USER -p $DOCKER_PASS xyz || docker login -u $DOCKER_USER -p $DOCKER_PASS xyz'}},
        {deploy => {command => 'docker push xyz/abc/def && curl -sSLf $BWALL_URL -X POST'}},
      ],
    }},
    workflows => {version => 2, build => {jobs => [
      'build',
      {test => {requires => ['build']}},
      {'deploy_master' => {filters => {branches => {only => ['master']}},
                           requires => ['test']}},
    ]}},
  }}}, 'build jobs / docker with tests'],
  [{circleci => {required_docker_images => ['a/b', 'a/b/c']}} => {'.circleci/config.yml' => {json => {
    version => 2,
    jobs => {build => {
      machine => {enabled => \1},
      environment => {CIRCLE_ARTIFACTS => '/tmp/circle-artifacts/build'},
      steps => [
        'checkout',
        {run => {command => 'mkdir -p $CIRCLE_ARTIFACTS'}},
        {run => {command => 'docker info'}},
        {run => {command => 'docker pull a/b && docker pull a/b/c',
                 background => \1}},
        {store_artifacts => {path => '/tmp/circle-artifacts/build'}},
      ],
    }},
    workflows => {version => 2, build => {jobs => ['build']}},
  }}}],
  [{circleci => {heroku => 1}} => {'.circleci/config.yml' => {json => {
    version => 2,
    jobs => {build => {
      machine => {enabled => \1},
      environment => {CIRCLE_ARTIFACTS => '/tmp/circle-artifacts/build'},
      steps => [
        'checkout',
        {run => {command => 'mkdir -p $CIRCLE_ARTIFACTS'}},
        {run => {command => 
      'git config --global user.email "temp@circleci.test"' . "\x0A" .
      'git config --global user.name "CircleCI"'
        }},
        {store_artifacts => {path => '/tmp/circle-artifacts/build'}},
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == 'master' ]; then} . "\x0Atrue\x0A" . 'git checkout --orphan herokucommit && git commit -m "Heroku base commit"' . "\x0Afi"}},
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == 'master' ]; then} . "\x0Atrue\x0A" . 'make create-commit-for-heroku' . "\x0Afi"}},
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == 'master' ]; then} . "\x0Atrue\x0A" . 'git push git@heroku.com:$HEROKU_APP_NAME.git +`git rev-parse HEAD`:refs/heads/master' . "\x0Afi"}},
      ],
    }},
    workflows => {version => 2, build => {jobs => ['build']}},
  }}}],
  [{circleci => {heroku => {
    app_name => 'abcdef',
  }}} => {'.circleci/config.yml' => {json => {
    version => 2,
    jobs => {build => {
      machine => {enabled => \1},
      environment => {CIRCLE_ARTIFACTS => '/tmp/circle-artifacts/build'},
      steps => [
        'checkout',
        {run => {command => 'mkdir -p $CIRCLE_ARTIFACTS'}},
        {run => {command => 
      'git config --global user.email "temp@circleci.test"' . "\x0A" .
      'git config --global user.name "CircleCI"'
        }},
        {store_artifacts => {path => '/tmp/circle-artifacts/build'}},
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == 'master' ]; then} . "\x0Atrue\x0A" . 'git checkout --orphan herokucommit && git commit -m "Heroku base commit"' . "\x0Afi"}},
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == 'master' ]; then} . "\x0Atrue\x0A" . 'make create-commit-for-heroku' . "\x0Afi"}},
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == 'master' ]; then} . "\x0Atrue\x0A" . 'git push git@heroku.com:abcdef.git +`git rev-parse HEAD`:refs/heads/master' . "\x0Afi"}},
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
      environment => {CIRCLE_ARTIFACTS => '/tmp/circle-artifacts/build'},
      steps => [
        'checkout',
        {run => {command => 'mkdir -p $CIRCLE_ARTIFACTS'}},
        {run => {command => 
      'git config --global user.email "temp@circleci.test"' . "\x0A" .
      'git config --global user.name "CircleCI"'
        }},
        {store_artifacts => {path => '/tmp/circle-artifacts/build'}},
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
      environment => {CIRCLE_ARTIFACTS => '/tmp/circle-artifacts/build'},
      steps => [
        'checkout',
        {run => {command => 'mkdir -p $CIRCLE_ARTIFACTS'}},
        {run => {command => 
      'git config --global user.email "temp@circleci.test"' . "\x0A" .
      'git config --global user.name "CircleCI"'
        }},
        {store_artifacts => {path => '/tmp/circle-artifacts/build'}},
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == 'master' ]; then} . "\x0Atrue\x0A" . 'git checkout --orphan herokucommit && git commit -m "Heroku base commit"' . "\x0Afi"}},
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == 'master' ]; then} . "\x0Atrue\x0A" . 'make create-commit-for-heroku' . "\x0Afi"}},
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == 'master' ]; then} . "\x0Atrue\x0A" . 'git push git@heroku.com:$HEROKU_APP_NAME.git +`git rev-parse HEAD`:refs/heads/master' . "\x0Afi"}},
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == 'master' ]; then} . "\x0Atrue\x0A" . 'abc' . "\x0Afi"}},
        {deploy => {command => q{if [ "${CIRCLE_BRANCH}" == 'master' ]; then} . "\x0Atrue\x0A" . './foo bar' . "\x0Afi"}},
      ],
    }},
    workflows => {version => 2, build => {jobs => ['build']}},
  }}}],
  [{circleci => {
    heroku => 1,
    build_generated_files => [],
  }} => {'.circleci/config.yml' => {json => {
    version => 2,
    jobs => {build => {
      machine => {enabled => \1},
      environment => {CIRCLE_ARTIFACTS => '/tmp/circle-artifacts/build'},
      steps => [
        'checkout',
        {run => {command => 'mkdir -p $CIRCLE_ARTIFACTS'}},
        {store_artifacts => {path => '/tmp/circle-artifacts/build'}},
        {"persist_to_workspace" => {
          "root" => "./",
          "paths" => ['.ciconfigtemp'],
        }},
      ],
    }, test => {
      machine => {enabled => \1},
      environment => {CIRCLE_ARTIFACTS => '/tmp/circle-artifacts/test'},
      steps => [
        'checkout',
        {"attach_workspace" => {"at" => "./"}},
        {run => {command => 'mkdir -p $CIRCLE_ARTIFACTS'}},
        {store_artifacts => {path => '/tmp/circle-artifacts/test'}},
      ],
    }, deploy_master => {
      machine => {enabled => \1},
      steps => [
        'checkout',
        {"attach_workspace" => {"at" => "./"}},
        {deploy => {command => 
      'git config --global user.email "temp@circleci.test"' . "\x0A" .
      'git config --global user.name "CircleCI"'
        }},
        {deploy => {command => 'git checkout --orphan herokucommit && git commit -m "Heroku base commit"'}},
        {deploy => {command => 'make create-commit-for-heroku'}},
        {deploy => {command => 'git push git@heroku.com:$HEROKU_APP_NAME.git +`git rev-parse HEAD`:refs/heads/master'}},
      ],
    }},
    workflows => {version => 2, build => {jobs => [
      'build',
      {test => {requires => ['build']}},
      {'deploy_master' => {filters => {branches => {only => ['master']}},
                           requires => ['test']}},
    ]}},
  }}}, 'empty build_generated_files'],
  [{circleci => {
    heroku => 1,
    build_generated_files => ['foo', 'bar'],
  }} => {'.circleci/config.yml' => {json => {
    version => 2,
    jobs => {build => {
      machine => {enabled => \1},
      environment => {CIRCLE_ARTIFACTS => '/tmp/circle-artifacts/build'},
      steps => [
        'checkout',
        {run => {command => 'mkdir -p $CIRCLE_ARTIFACTS'}},
        {store_artifacts => {path => '/tmp/circle-artifacts/build'}},
        {"persist_to_workspace" => {
          "root" => "./",
          "paths" => ['.ciconfigtemp', 'foo', 'bar'],
        }},
      ],
    }, test => {
      machine => {enabled => \1},
      environment => {CIRCLE_ARTIFACTS => '/tmp/circle-artifacts/test'},
      steps => [
        'checkout',
        {"attach_workspace" => {"at" => "./"}},
        {run => {command => 'mkdir -p $CIRCLE_ARTIFACTS'}},
        {store_artifacts => {path => '/tmp/circle-artifacts/test'}},
      ],
    }, deploy_master => {
      machine => {enabled => \1},
      steps => [
        'checkout',
        {"attach_workspace" => {"at" => "./"}},
        {deploy => {command => 
      'git config --global user.email "temp@circleci.test"' . "\x0A" .
      'git config --global user.name "CircleCI"'
        }},
        {deploy => {command => 'git checkout --orphan herokucommit && git commit -m "Heroku base commit"'}},
        {deploy => {command => 'make create-commit-for-heroku'}},
        {deploy => {command => 'git push git@heroku.com:$HEROKU_APP_NAME.git +`git rev-parse HEAD`:refs/heads/master'}},
      ],
    }},
    workflows => {version => 2, build => {jobs => [
      'build',
      {test => {requires => ['build']}},
      {'deploy_master' => {filters => {branches => {only => ['master']}},
                           requires => ['test']}},
    ]}},
  }}}],
  [{circleci => {
    heroku => 1,
    build_generated_files => ['foo', 'bar'],
    build_generated_pmbp => 1,
  }} => {'.circleci/config.yml' => {json => {
    version => 2,
    jobs => {build => {
      machine => {enabled => \1},
      environment => {CIRCLE_ARTIFACTS => '/tmp/circle-artifacts/build'},
      steps => [
        'checkout',
        {run => {command => 'mkdir -p $CIRCLE_ARTIFACTS'}},
        {store_artifacts => {path => '/tmp/circle-artifacts/build'}},
        {"persist_to_workspace" => {
          "root" => "./",
          "paths" => ['.ciconfigtemp', 'foo', 'bar',
                      qw(deps local perl prove plackup lserver local-server rev)],
        }},
      ],
    }, test => {
      machine => {enabled => \1},
      environment => {CIRCLE_ARTIFACTS => '/tmp/circle-artifacts/test'},
      steps => [
        'checkout',
        {"attach_workspace" => {"at" => "./"}},
        {run => {command => 'mkdir -p $CIRCLE_ARTIFACTS'}},
        {store_artifacts => {path => '/tmp/circle-artifacts/test'}},
      ],
    }, deploy_master => {
      machine => {enabled => \1},
      steps => [
        'checkout',
        {"attach_workspace" => {"at" => "./"}},
        {deploy => {command => 
      'git config --global user.email "temp@circleci.test"' . "\x0A" .
      'git config --global user.name "CircleCI"'
        }},
        {deploy => {command => 'git checkout --orphan herokucommit && git commit -m "Heroku base commit"'}},
        {deploy => {command => 'make create-commit-for-heroku'}},
        {deploy => {command => 'git push git@heroku.com:$HEROKU_APP_NAME.git +`git rev-parse HEAD`:refs/heads/master'}},
      ],
    }},
    workflows => {version => 2, build => {jobs => [
      'build',
      {test => {requires => ['build']}},
      {'deploy_master' => {filters => {branches => {only => ['master']}},
                           requires => ['test']}},
    ]}},
  }}}],
  [{circleci => {deploy => ['true', 'false']}} => {'.circleci/config.yml' => {json => {
    version => 2,
    jobs => {build => {
      machine => {enabled => \1},
      environment => {CIRCLE_ARTIFACTS => '/tmp/circle-artifacts/build'},
      steps => [
        'checkout',
        {run => {command => 'mkdir -p $CIRCLE_ARTIFACTS'}},
        {store_artifacts => {path => '/tmp/circle-artifacts/build'}},
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
      environment => {CIRCLE_ARTIFACTS => '/tmp/circle-artifacts/build'},
      steps => [
        'checkout',
        {run => {command => 'mkdir -p $CIRCLE_ARTIFACTS'}},
        {store_artifacts => {path => '/tmp/circle-artifacts/build'}},
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
      environment => {CIRCLE_ARTIFACTS => '/tmp/circle-artifacts/build'},
      steps => [
        'checkout',
        {run => {command => 'mkdir -p $CIRCLE_ARTIFACTS'}},
        {store_artifacts => {path => '/tmp/circle-artifacts/build'}},
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
      environment => {CIRCLE_ARTIFACTS => '/tmp/circle-artifacts/build'},
      steps => [
        'checkout',
        {run => {command => 'mkdir -p $CIRCLE_ARTIFACTS'}},
        {store_artifacts => {path => '/tmp/circle-artifacts/build'}},
      ],
    }, deploy_staging => {
      machine => {enabled => \1},
      steps => [
        'checkout',
        {deploy => {command => 'git rev-parse HEAD > head.txt' . "\x0A" .
          'curl -f -s -S --request POST --header "Authorization:token $GITHUB_ACCESS_TOKEN" --header "Content-Type:application/json" --data-binary "{\\"base\\":\\"master\\",\\"head\\":\\"`cat head.txt`\\",\\"commit_message\\":\\"auto-merge $CIRCLE_BRANCH into master\\"}" "https://api.github.com/repos/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/merges"'}},
      ],
    }, deploy_nightly => {
      machine => {enabled => \1},
      steps => [
        'checkout',
        {deploy => {command => 'git rev-parse HEAD > head.txt' . "\x0A" .
          'curl -f -s -S --request POST --header "Authorization:token $GITHUB_ACCESS_TOKEN" --header "Content-Type:application/json" --data-binary "{\\"base\\":\\"master\\",\\"head\\":\\"`cat head.txt`\\",\\"commit_message\\":\\"auto-merge $CIRCLE_BRANCH into master\\"}" "https://api.github.com/repos/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/merges"'}},
      ],
    }},
    workflows => {version => 2, build => {jobs => [
      'build',
      {'deploy_nightly' => {filters => {branches => {only => ['nightly']}},
                            requires => ['build']}},
      {'deploy_staging' => {filters => {branches => {only => ['staging']}},
                            requires => ['build']}},
    ]}},
  }}}],
  [{circleci => {merger => {into => 'dev'}}} => {'.circleci/config.yml' => {json => {
    version => 2,
    jobs => {build => {
      machine => {enabled => \1},
      environment => {CIRCLE_ARTIFACTS => '/tmp/circle-artifacts/build'},
      steps => [
        'checkout',
        {run => {command => 'mkdir -p $CIRCLE_ARTIFACTS'}},
        {store_artifacts => {path => '/tmp/circle-artifacts/build'}},
      ],
    }, deploy_staging => {
      machine => {enabled => \1},
      steps => [
        'checkout',
        {deploy => {command => 'git rev-parse HEAD > head.txt' . "\x0A" .
          'curl -f -s -S --request POST --header "Authorization:token $GITHUB_ACCESS_TOKEN" --header "Content-Type:application/json" --data-binary "{\\"base\\":\\"dev\\",\\"head\\":\\"`cat head.txt`\\",\\"commit_message\\":\\"auto-merge $CIRCLE_BRANCH into dev\\"}" "https://api.github.com/repos/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/merges"'}},
      ],
    }, deploy_nightly => {
      machine => {enabled => \1},
      steps => [
        'checkout',
        {deploy => {command => 'git rev-parse HEAD > head.txt' . "\x0A" .
          'curl -f -s -S --request POST --header "Authorization:token $GITHUB_ACCESS_TOKEN" --header "Content-Type:application/json" --data-binary "{\\"base\\":\\"dev\\",\\"head\\":\\"`cat head.txt`\\",\\"commit_message\\":\\"auto-merge $CIRCLE_BRANCH into dev\\"}" "https://api.github.com/repos/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/merges"'}},
      ],
    }},
    workflows => {version => 2, build => {jobs => [
      'build',
      {'deploy_nightly' => {filters => {branches => {only => ['nightly']}},
                            requires => ['build']}},
      {'deploy_staging' => {filters => {branches => {only => ['staging']}},
                            requires => ['build']}},
    ]}},
  }}}],
  [{circleci => {awscli => 1}} => {'.circleci/config.yml' => {json => {
    version => 2,
    jobs => {build => {
      machine => {enabled => \1},
      environment => {CIRCLE_ARTIFACTS => '/tmp/circle-artifacts/build'},
      steps => [
        'checkout',
        {run => {command => 'mkdir -p $CIRCLE_ARTIFACTS'}},
        {run => {command => "(((sudo apt-cache search python-dev | grep ^python-dev) || sudo apt-get update) && sudo apt-get install -y python-dev) || (sudo apt-get update && sudo apt-get install -y python-dev)\n".
                 "sudo pip install awscli --upgrade\n".
                 "aws --version"}},
        {store_artifacts => {path => '/tmp/circle-artifacts/build'}},
      ],
    }},
    workflows => {version => 2, build => {jobs => ['build']}},
  }}}],
  [{circleci => {parallel => \1}} => {'.circleci/config.yml' => {json => {
    version => 2,
    jobs => {build => {
      parallelism => 2,
      machine => {enabled => \1},
      environment => {CIRCLE_ARTIFACTS => '/tmp/circle-artifacts/build'},
      steps => [
        'checkout',
        {run => {command => 'mkdir -p $CIRCLE_ARTIFACTS'}},
        {store_artifacts => {path => '/tmp/circle-artifacts/build'}},
      ],
    }},
    workflows => {version => 2, build => {jobs => ['build']}},
  }}}],
  [{circleci => {parallel => 1}} => {'.circleci/config.yml' => {json => {
    version => 2,
    jobs => {build => {
      parallelism => 2,
      machine => {enabled => \1},
      environment => {CIRCLE_ARTIFACTS => '/tmp/circle-artifacts/build'},
      steps => [
        'checkout',
        {run => {command => 'mkdir -p $CIRCLE_ARTIFACTS'}},
        {store_artifacts => {path => '/tmp/circle-artifacts/build'}},
      ],
    }},
    workflows => {version => 2, build => {jobs => ['build']}},
  }}}],
  [{circleci => {parallel => 4}} => {'.circleci/config.yml' => {json => {
    version => 2,
    jobs => {build => {
      parallelism => 4,
      machine => {enabled => \1},
      environment => {CIRCLE_ARTIFACTS => '/tmp/circle-artifacts/build'},
      steps => [
        'checkout',
        {run => {command => 'mkdir -p $CIRCLE_ARTIFACTS'}},
        {store_artifacts => {path => '/tmp/circle-artifacts/build'}},
      ],
    }},
    workflows => {version => 2, build => {jobs => ['build']}},
  }}}, 'parallel 4'],
  [{circleci => {
    build_generated_files => [],
    parallel => 4,
  }} => {'.circleci/config.yml' => {json => {
    version => 2,
    jobs => {build => {
      machine => {enabled => \1},
      environment => {CIRCLE_ARTIFACTS => '/tmp/circle-artifacts/build'},
      steps => [
        'checkout',
        {run => {command => 'mkdir -p $CIRCLE_ARTIFACTS'}},
        {store_artifacts => {path => '/tmp/circle-artifacts/build'}},
        {"persist_to_workspace" => {
          "root" => "./",
          "paths" => ['.ciconfigtemp'],
        }},
      ],
    }, test => {
      parallelism => 4,
      machine => {enabled => \1},
      environment => {CIRCLE_ARTIFACTS => '/tmp/circle-artifacts/test'},
      steps => [
        'checkout',
        {"attach_workspace" => {"at" => "./"}},
        {run => {command => 'mkdir -p $CIRCLE_ARTIFACTS'}},
        {store_artifacts => {path => '/tmp/circle-artifacts/test'}},
      ],
    }},
    workflows => {version => 2, build => {jobs => [
      'build',
      {test => {requires => ['build']}},
    ]}},
  }}}, 'parallel 4 build and test'],
  [{circleci => {parallel => 0}} => {'.circleci/config.yml' => {json => {
    version => 2,
    jobs => {build => {
      machine => {enabled => \1},
      environment => {CIRCLE_ARTIFACTS => '/tmp/circle-artifacts/build'},
      steps => [
        'checkout',
        {run => {command => 'mkdir -p $CIRCLE_ARTIFACTS'}},
        {store_artifacts => {path => '/tmp/circle-artifacts/build'}},
      ],
    }},
    workflows => {version => 2, build => {jobs => ['build']}},
  }}}],
  [{circleci => {parallel => \0}} => {'.circleci/config.yml' => {json => {
    version => 2,
    jobs => {build => {
      machine => {enabled => \1},
      environment => {CIRCLE_ARTIFACTS => '/tmp/circle-artifacts/build'},
      steps => [
        'checkout',
        {run => {command => 'mkdir -p $CIRCLE_ARTIFACTS'}},
        {store_artifacts => {path => '/tmp/circle-artifacts/build'}},
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
      environment => {CIRCLE_ARTIFACTS => '/tmp/circle-artifacts/build'},
      steps => [
        'checkout',
        {run => {command => 'mkdir -p $CIRCLE_ARTIFACTS'}},
        {run => {command => 'a'}},
        {run => {command => q{if [ "${CIRCLE_BRANCH}" == 'c' ]; then} . "\x0Atrue\x0A" . 'b' . "\x0Afi"}},
        {store_artifacts => {path => '/tmp/circle-artifacts/build'}},
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
      environment => {CIRCLE_ARTIFACTS => '/tmp/circle-artifacts/build'},
      steps => [
        'checkout',
        {run => {command => 'mkdir -p $CIRCLE_ARTIFACTS'}},
        {run => {command => 'a'}},
        {run => {command => q{if [ "${CIRCLE_NODE_INDEX}" == "0" ]; then} . "\x0A" . "true\x0A" . 'b' . "\x0Afi"}},
        {store_artifacts => {path => '/tmp/circle-artifacts/build'}},
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
      environment => {CIRCLE_ARTIFACTS => '/tmp/circle-artifacts/build'},
      steps => [
        'checkout',
        {run => {command => 'mkdir -p $CIRCLE_ARTIFACTS'}},
        {run => {command => 'a' . "\n" . 'b'}},
        {store_artifacts => {path => '/tmp/circle-artifacts/build'}},
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
      environment => {CIRCLE_ARTIFACTS => '/tmp/circle-artifacts/build'},
      steps => [
        'checkout',
        {run => {command => 'mkdir -p $CIRCLE_ARTIFACTS'}},
        {run => {command => 'a' . "\n" . 'b'}},
        {store_artifacts => {path => '/tmp/circle-artifacts/build'}},
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
        steps => [
          "checkout",
          {run => {command => 'git config --global user.email "temp@circleci.test";git config --global user.name "CircleCI"'}},
          {run => {command => 'make deps'}},
          {run => {command => 'make updatenightly'}},
          {deploy => {command => 'git commit -m auto'}},
          {deploy => {command => 'git push origin +`git rev-parse HEAD`:refs/heads/nightly'}},
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
        steps => [
          "checkout",
          {run => {command => 'git config --global user.email "temp@circleci.test";git config --global user.name "CircleCI"'}},
          {run => {command => 'make deps'}},
          {run => {command => 'make updatenightly'}},
          {deploy => {command => 'git commit -m auto'}},
          {deploy => {command => 'git push origin +`git rev-parse HEAD`:refs/heads/nightly'}},
        ],
      },
      build => {
        machine => {enabled => \1},
        environment => {CIRCLE_ARTIFACTS => '/tmp/circle-artifacts/build'},
        steps => [
          'checkout',
          {run => {command => 'mkdir -p $CIRCLE_ARTIFACTS'}},
          {store_artifacts => {path => '/tmp/circle-artifacts/build'}},
        ],
      },
    },
    workflows => {version => 2, gaa4 => {
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
  my ($input, $expected, $name) = @$_;
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
    #use Data::Dumper;
    #warn Dumper $output;
    done $c;
  } n => 1, name => $name;
}

run_tests;

=head1 LICENSE

Copyright 2018-2020 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
