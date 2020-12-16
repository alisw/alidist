# alidist
Recipes to build ALICE SW

# Guidelines for commit messages

- Keep the first line of the commit below 50 chars
- Leave the second line empty
- Try to keep the lines after the third below 72 chars
- Use some imperative verb as first word of the first line
- Do not end the first line with a full-stop (i. e. `.`)
- Make sure you squash / cleanup your commits when it makes sense (e.g. if they are really one the fix of the other). Keep history clean.

Example:

```
Fix issue in Geant4

Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod
tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim
veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea
commodo consequat.
```

# Guidelines for contributing recipes

- Keep things simple (but concise).
- Use 2 spaces to indent them.
- Try avoid "fix typo" commits and squash history whenever makes sense.
- Avoid touching $SOURCEDIR. If your recipe needs to build in-source, first copy them to $BUILDIR via:

```
rsync -a $SOURCEDIR ./
```
- If a package is a toolkit not really affecting physics performance, make sure you provide a `prefer_system_check` rule to have laptop user pick it up from the system.
- If a package is a physics related one. Avoid providing a `prefer_system_check` unless explicitly discussed withing the Computing Board or the O2 Technical board.
- If `SOMETHING_VERSION` or `SOMETHING_REVISION` is defined, you can assume `SOMETHING_ROOT` is defined and points to an aliBuild built package. However the opposite is not true. I.e. you should not assume that `SOMETHING_ROOT` being defined means that a `something` was built with aliBuild (it could come from the system) and you cannot assume that `SOMETHING_VERSION` and `SOMETHING_REVISION` are set. 
- If a package can / could be picked up from the system, do not provide, in the modulefile, any variable which is not also exposed in general by the system installation. E.g. `ROOTSYS` is fine because that kind of a standard for ROOT installations, `GCC_ROOT` is not because GCC in general does not use `GCC_ROOT`.
- When picking up a system dependency installed with homebrew, make sure you override the `SOMETHING_ROOT` variable when it's not set by using `brew --prefix`.

```bash
case $ARCHITECTURE in
  osx)
[ ! $BOOST_ROOT ] || BOOST_ROOT=$(brew --prefix boost)
  ;;
esac
```

Then use such a variable to pass the information optionally to, e.g., CMake.

```bash
cmake ...                                   \
  ${BOOST_ROOT:+-DBOOST_ROOT=$BOOST_ROOT}
```

This will make sure that if a package was selected to be picked up by the system (i.e. `BOOST_ROOT` is not set), we will look it up in the package specific folder when using homebrew.

You should never set any `SOMETHING_ROOT` variable to `/usr/local` because that is a global folder and it will make it have precendence in the lookup, therefore potentially implicitly bringing in incompatible versions of external packages.

- If you need python use Python-system on non SLC distributions (Ubuntu, macOS) and use Python on SLC. This can be done usually by adding:

```yaml
- Python:slc.*
- Python-system:(osx.*)
```

in your `requires` section. Alternatively, if you also require `Python-modules` simply depend on it, without an explicit dependency on Python, which will be handled internally.

# Guidelines for handling externals sources

Whenever you need to build a new external, you should consider the following:

  - If a Git / GitHub mirror exists, and no patches are required, use it for the
    package source.
  - If a Git / GitHub repository exists and you need to patch it, fork it, decide a
    fork point, possibly based on a tag or eventually a commit hash, and create a branch
    in your fork called `alice/<fork-point>`. This can be done with:
 
        git checkout -b alice/<fork-point> <fork-point>

    patches should be applied on such a branch. You should then tag your development as:
    `<version>-alice<x>` where `<x>` is an incremental number for a given official `<version>`.
  - If no git repository is available, or if mirroring the whole repository is
    not desirable, create a repository with a `master` branch. On the master
    branch import relevant released tarballs, one commit per tarball. Make sure
    you tag the commit with the tag of the tarball. E.g.:

        git clone https://github.com/alisw/mysoft
        curl -O https://mysoftware.com/mysoft-version.tar.gz
        tar xzvf mysoft-version.tar.gz
        rsync -a --delete --exclude '**/.git' mysoft-version/ mysoft/
        cd mysoft
        git add -A .
        git commit -a -m 'Import https://mysoftware.com/mysoft-<version>.tar.gz'
        git tag <version>

    In case you need to add a patch on top of a tarball, create a branch with:

        git checkout -b alice/<version> <version>

    and add your patches on such a branch. You should then tag your development as:
    `<version>-alice<x>` where `<x>` is an incremental number for a given official `<version>`.
  - Do not create extra branches unless you do need to patch the original sources.

Moreover try to keep the package name (as specified inside the recipe
in the `package` field of the header) and the repository name the same,
including capitalization.

## Request a new package

Please open a JIRA issue with your request at:

https://alice.its.cern.ch/jira/secure/CreateIssue!default.jspa

Make sure you select "Dependencies" as component.

## Private packages

Private packages are highly discouraged and must be avoided as much as possible. Private packages **MUST** still comply to GLPv3 which basically means:

* You cannot have private packages depend on GPLv3 code.
* You cannot have GPLv3 code which can be considered "derived product" of a private package.

In order to have a private package please open a JIRA ticket and we will create one / mirror in the https://gitlab.cern.ch/AlicePrivateExternals, which is the only place where you are allowed to have a private external.
