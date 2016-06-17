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
- Avoid touching $SOURCEDIR. If your recipe needs to compile in source, first copy them to $BUILDIR via:

```
rsync -a $SOURCEDIR ./
```

# Guidelines for handling externals sources

Whenever you need to build a new external, you should consider the following:

  - If a Git / GitHub mirror exists, and no patches are required, use it for the
    package source.
  - If a Git / GitHub repository exists and you need to patch it, fork it, decide a
    fork point, possibly based on a tag or eventually a commit hash, and create a branch
    in your fork called `alice/<fork-point>`. This can be done with:
 
        git checkout -b alice/<fork-point> <fork-point>

    patches should be applied on such a branch.
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

    and add your patches on such a branch.
  - Do not create extra branches unless you do need to patch the original sources.

Moreover try to keep the package name (as specified inside the recipe
in the `package` field of the header) and the repository name the same,
including capitalization.

# PWGMM owned packages

The following packages have been agreed to be under PWGMM ownership and will require its signoff to be deployed in production.

- aligenerators
- crmc
- epos
- epos-test
- hepmc
- jewel
- lhapdf
- lhapdf5
- powheg
- pythia
- pythia6
- rivet
- rivet-test
- sherpa
- thepeg
- thepeg-test
- yoda

Plus any of their dependencies.
