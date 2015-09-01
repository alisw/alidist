# alidist
Recipes to build ALICE SW

# Guidelines for contributing recipes

- Keep things simple (but concise).
- Use 2 spaces to indent them.
- Try avoid "fix typo" commits and squash history whenever makes sense.
- Avoid touching $SOURCEDIR. If your recipe needs to compile in source, first copy them to $BUILDIR via:

```
rsync -a $SOURCEDIR ./
```
