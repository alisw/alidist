#!groovy

node {
  stage "Verify author"
  def power_users = ["ktf", "dberzano"]
  echo "Changeset from " + env.CHANGE_AUTHOR
  if (power_users.contains(env.CHANGE_AUTHOR)) {
    echo "PR comes from power user. Testing"
  } else {
    input "Do you want to test this change?"
  }
  
  stage "Build AliRoot"
  def test_script = '''
      (cd alidist && git show)
      rm -fr alibuild
      git clone https://github.com/alisw/alibuild
      x=`date +"%s"`
      WORKAREA=/build/workarea/pr/`echo $(( $x / 3600 / 24 / 7))`

      # Make sure we have only one builder per directory
      CURRENT_SLAVE=unknown
      while [[ "$CURRENT_SLAVE" != '' ]]; do
        WORKAREA_INDEX=$((WORKAREA_INDEX+1))
        CURRENT_SLAVE=$(cat $WORKAREA/$WORKAREA_INDEX/current_slave 2> /dev/null || true)
        [[ "$CURRENT_SLAVE" == "$NODE_NAME" ]] && CURRENT_SLAVE=
      done

      mkdir -p $WORKAREA/$WORKAREA_INDEX
      echo $NODE_NAME > $WORKAREA/$WORKAREA_INDEX/current_slave

      alibuild/aliBuild --work-dir $WORKAREA/$WORKAREA_INDEX               \
                        --reference-sources /build/mirror                  \
                        --debug                                            \
                        --jobs 16                                          \
                        --remote-store rsync://repo.marathon.mesos/store/  \
                        -d build AliRoot || BUILDERR=$?

      rm -f $WORKAREA/$WORKAREA_INDEX/current_slave
      if [ ! "X$BUILDERR" = X ]; then
        exit $BUILDERR
      fi
    '''

  currentBuild.displayName = "Testing ${env.BRANCH_NAME}"
  parallel(
    "slc7": {
      node ("slc7_x86-64-large") {
        dir ("alidist") {
          checkout scm
        }
        sh test_script
      }
    },
    "ubuntu1510": {
      node ("ubt1510_x86-64-large") {
        dir ("alidist") {
          checkout scm
        }
        sh test_script
      }
    },
    "slc5": {
      node ("slc5_x86-64-large") {
        dir ("alidist") {
          checkout scm
        }
        sh test_script
      }
    },
    "slc6": {
      node ("slc6_x86-64-large") {
        dir ("alidist") {
          checkout scm
        }
        sh test_script
      }
    }
  )
}
