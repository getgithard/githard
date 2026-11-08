# Evals

One folder per case under `evals/<skill>/<case>/`: a `prompt.md` and its `graders/`. Each case also runs without the plugin, so you can see what GitHard adds.

Run them from the repo root:

```sh
claude plugin eval . --judge-model sonnet
```

Use the sonnet judge. With the default haiku judge, the same reply sometimes passes and sometimes fails. Results go to `evals/results/`, which git ignores.
