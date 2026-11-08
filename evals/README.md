# Evals

One folder per case under `evals/<skill>/<case>/`: a `prompt.md` and its `graders/`. Each case also runs without the plugin, so you can see what GitHard adds.

Run them from the repo root:

```sh
claude plugin eval . --scaffold --allow-tools Bash Write Edit --judge-model sonnet
```

`--scaffold` runs each case's `scaffold.sh`, which builds a small throwaway repo for the case to work in. Only pass it for cases you've read. The repo-setup cases write files and run `audit.sh`, which is why they need `--allow-tools`. Filter by skill with `--tag <skill>`.

Use the sonnet judge. With the default haiku judge, the same reply sometimes passes and sometimes fails. Results go to `evals/results/`, which git ignores.

## When a skill ships

The `using-githard` cases named `planned-*` check what GitHard says about a skill that isn't built yet. When that skill ships, point the case at one that's still planned, or it can never pass again. Also take that skill's topics out of the list of planned skills in `using-githard`'s description, so requests go straight to the new skill.

## What CI checks

The evals need Claude credentials, so CI doesn't run them. `scripts/check.sh` does the parts that don't need them: every case has a tagged `prompt.md` and typed graders, every `scaffold.sh` runs in an empty folder, and `audit.sh` flags every gap in the `audit-existing` scaffold. Run the evals yourself before you merge a skill change.
