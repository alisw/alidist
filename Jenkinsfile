#!groovy

def buildAny(architecture) {
  def build_script = '''
      # Make sure we have only one builder per directory
      BUILD_DATE=$(echo 2015$(echo "$(date -u +%s) / (86400 * 3)" | bc))
      WORKAREA=/build/workarea/$WORKAREA_PREFIX/$BUILD_DATE

      CURRENT_SLAVE=unknown
      while [[ "$CURRENT_SLAVE" != '' ]]; do
        WORKAREA_INDEX=$((WORKAREA_INDEX+1))
        CURRENT_SLAVE=$(cat $WORKAREA/$WORKAREA_INDEX/current_slave 2> /dev/null || true)
        [[ "$CURRENT_SLAVE" == "$NODE_NAME" ]] && CURRENT_SLAVE=
      done

      mkdir -p $WORKAREA/$WORKAREA_INDEX
      echo $NODE_NAME > $WORKAREA/$WORKAREA_INDEX/current_slave

      (cd alidist && git show)
      rm -fr alibuild
      git clone https://github.com/alisw/alibuild

      # Whenever we change a spec file, we rebuild it and then we
      # rebuild AliRoot just to make sure we did not break anything.
      case $CHANGE_TARGET in
        null)
          PKGS=AliPhysics
        ;;
        *)
          PKGS=`cd alidist ; git diff --name-status origin/$CHANGE_TARGET | grep -v -e '^D' | awk '{print $2}' | grep .sh | sed -e's|[.]sh$||'`
        ;;
      esac

      for p in $PKGS; do
        # Euristics to decide which kind of test we should run.
        case $p in
          # Packages which only touch rivet
          yoda|rivet)
            BUILD_TEST="$BUILD_TEST Rivet-test" ;;

          # Packages which only touch O2
          o2|fairroot|dds|zeromq|nanomsg|sodium|pythia|pythia6|lhapdf|fftw3)
            BUILD_TEST="$BUILD_TEST O2 " ;;

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
          gcc-toolchain|root|cmake|zlib|gsl|boost|cgal|fastjet)
            BUILD_TEST="$BUILD_TEST AliRoot-test Rivet-test" ;;

          # Packages which are standalone
          *) BUILD_TEST="$BUILD_TEST $p" ;;
        esac
      done

      for p in `echo $BUILD_TEST | sort -u`; do
        alibuild/aliBuild --work-dir $WORKAREA/$WORKAREA_INDEX                                 \
                          --reference-sources /build/mirror                                    \
                          --debug                                                              \
                          --jobs 16                                                            \
                          --disable DDS                                                        \
                          --remote-store rsync://repo.marathon.mesos/store/${DO_UPLOAD:+::rw}  \
                          -d build $p || BUILDERR=$?
      done

      rm -f $WORKAREA/$WORKAREA_INDEX/current_slave
      [[ "$BUILDERR" != '' ]] && exit $BUILDERR
      exit 0
    '''
  return { -> node("${architecture}-large") {
                dir ("alidist") { checkout scm }
                sh build_script
              }
  }
}

node {
  stage "Verify author"
  def power_users = ["ktf", "dberzano"]
  echo "Changeset from " + env.CHANGE_AUTHOR
  if (env.CHANGE_AUTHOR == null && env.BRANCH_NAME.matches("IB/[^/]+/[^/]+")) {
    echo "Branch ${env.BRANCH_NAME} updated."
  } else if (power_users.contains(env.CHANGE_AUTHOR)) {
    currentBuild.displayName = "Testing ${env.BRANCH_NAME} from ${env.CHANGE_AUTHOR}"
    echo "PR comes from power user. Testing"
  } else {
    currentBuild.displayName = "Feedback needed for ${env.BRANCH_NAME} from ${env.CHANGE_AUTHOR}"
    input "Do you want to test this change?"
  }
  currentBuild.displayName = "Testing ${env.BRANCH_NAME} from ${env.CHANGE_AUTHOR}"

  stage "Build software"
  currentBuild.displayName = "Testing ${env.BRANCH_NAME}"
  if (env.BRANCH_NAME && env.BRANCH_NAME.matches("IB/.*/next") && env.CHANGE_AUTHOR == null) {
    // This is a change to the next branch. Let's build and upload results for slc7, slc6 and ubuntu
    withEnv (["CHANGE_TARGET=${env.CHANGE_TARGET}",
              "DO_UPLOAD=true",
              "WORKAREA_PREFIX=ci"]) {
      parallel(
        "slc7": buildAny("slc7_x86-64"),
        "slc6": buildAny("slc6_x86-64"),
        "slc7-daq": buildAny("slc7_x86-64-daq")
      )
    }
  }
  else if (env.BRANCH_NAME && env.BRANCH_NAME.matches("IB/.*/prod") && env.CHANGE_AUTHOR == null) {
    // This is a change to the prod branch. Let's build and upload results for slc5.
    withEnv (["CHANGE_TARGET=${env.CHANGE_TARGET}",
              "DO_UPLOAD=true",
              "WORKAREA_PREFIX=ci"]) {
      buildAny("slc5_x86-64")
    }
  }
  else if (env.CHANGE_TARGET && env.CHANGE_TARGET.matches("IB/.*/next") && env.CHANGE_AUTHOR)
  {
    // This is a PR on the next branch. We check it on slc6, slc7, ubuntu
    withEnv (["CHANGE_TARGET=${env.CHANGE_TARGET}",
              "WORKAREA_PREFIX=pr"]) {
      parallel(
        "slc7": buildAny("slc7_x86-64"),
        "slc6": buildAny("slc6_x86-64"),
        "slc7-daq": buildAny("slc7_x86-64-daq")
      )
    }
  }
  else if (env.CHANGE_TARGET && env.CHANGE_TARGET.matches("IB/.*/prod") && env.CHANGE_AUTHOR) {
    // This is a PR on the next branch. We check it on slc5 only
    withEnv (["CHANGE_TARGET=${env.CHANGE_TARGET}",
              "WORKAREA_PREFIX=pr"]) {
      buildAny("slc5_x86-64")
    }
  }
  else  {
    // This is either an old branch or one which we should not build automatically
    // skipping
  }
}
