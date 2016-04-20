#!groovy

node {
  stage "Verify author"
  def power_users = ["ktf", "dberzano"]
  echo "Changeset from " + env.CHANGE_AUTHOR
  if (power_users.contains(env.CHANGE_AUTHOR)) {
    currentBuild.displayName = "Testing ${env.BRANCH_NAME} from ${env.CHANGE_AUTHOR}"
    echo "PR comes from power user. Testing"
  } else {
    currentBuild.displayName = "Feedback needed for ${env.BRANCH_NAME} from ${env.CHANGE_AUTHOR}"
    input "Do you want to test this change?"
  }
  currentBuild.displayName = "Testing ${env.BRANCH_NAME} from ${env.CHANGE_AUTHOR}"
  
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
    
      # Whenever we change a spec file, we rebuild it and then we
      # rebuild AliRoot just to make sure we did not break anything.
      for p in `cd alidist ; git diff --name-only origin/$CHANGE_TARGET | grep .sh | sed -e's|[.]sh$||'`; do
        # Euristics to decide which kind of test we should run.
        case $p in
          # Packages which only touch rivet
          yoda|rivet)
            BUILD_TEST="Rivet-test" ;;

          # Packages which only touch O2
          o2|fairroot|dds|zeromq|nanomsg|sodium|pythia|pythia6|lhapdf)
            BUILD_TEST="O2" ;;

          # Packages which are only for AliRoot
          aliphysics|aliroot-test)
            BUILD_TEST="$BUILD_TEST AliRoot-test" ;;

          # Packages which are common between O2 and Rivet
          python-modules|python|freetype|libpng|hepmc)
            BUILD_TEST="$BUILD_TEST Rivet-test" ;; # FIXME: For the moment we test only Rivet

          # Packages which are for AliRoot and O2
          aliroot|geant4|geant4_vmc|geant3)
            BUILD_TEST="$BUILD_TEST AliRoot-test" ;; # FIXME: For the moment we test only AliRoot

          # Packages which are (will be) common for all of them
          gcc-toolchain|root|cmake|zlib|alien-runtime|gsl|boost|cgal|fastjet)
            BUILD_TEST="$BUILD_TEST AliRoot-test Rivet-test" ;;

          # Packages which are standalone
          *) BUILD_TEST=$p ;;
        esac
      done

      for p in `echo $BUILD_TEST | sort -u`; do
        alibuild/aliBuild --work-dir $WORKAREA/$WORKAREA_INDEX               \
                          --reference-sources /build/mirror                  \
                          --debug                                            \
                          --jobs 16                                          \
                          --remote-store rsync://repo.marathon.mesos/store/  \
                          -d build $p || BUILDERR=$?
      done

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
        withEnv (["CHANGE_TARGET=${env.CHANGE_TARGET}"]) {
          sh test_script
        }
      }
    },
    "ubuntu1510": {
      node ("ubt1510_x86-64-large") {
        dir ("alidist") {
          checkout scm
        }
        withEnv (["CHANGE_TARGET=${env.CHANGE_TARGET}"]) {
          sh test_script
        }
      }
    },
    "slc5": {
      node ("slc5_x86-64-large") {
        dir ("alidist") {
          checkout scm
        }
        withEnv (["CHANGE_TARGET=${env.CHANGE_TARGET}"]) {
          sh test_script
        }
      }
    },
    "slc6": {
      node ("slc6_x86-64-large") {
        dir ("alidist") {
          checkout scm
        }
        withEnv (["CHANGE_TARGET=${env.CHANGE_TARGET}"]) {
          sh test_script
        }
      }
    }
  )
}
