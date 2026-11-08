# Evals

One folder per case under `evals/<skill>/<case>/`: a `prompt.md` and its `graders/`. Each case also runs without the plugin, so you can see what GitHard adds.

Run them from the repo root:

```sh
claude plugin eval . --scaffold --allow-tools Bash Write Edit --judge-model sonnet
```

`--scaffold` runs each case's `scaffold.sh`, which builds a small throwaway repo for the case to work in. Only pass it for cases you've read. The repo-setup cases write files and run `audit.sh`, which is why they need `--allow-tools`. Filter by skill with `--tag <skill>`.

Use the sonnet judge. With the default haiku judge, the same reply sometimes passes and sometimes fails. Results go to `evals/results/`, which git ignores.
