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
  def test_script = """
      (cd alidist && git show)
      rm -fr alibuild
      git clone https://github.com/alisw/alibuild
      alibuild/aliBuild --reference-sources /build/mirror --debug --remote-store rsync://repo.marathon.mesos/store/ -d build AliRoot
    """

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
    }
  )
}
