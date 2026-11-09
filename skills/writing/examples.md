# Before and after

Each pair is invented, for a made-up notes app called Jot. The "after" follows `knowledge/voice.md`.

## README opening

Before:

> Jot is a robust, cutting-edge note-taking solution that empowers users to seamlessly capture and organise their thoughts across devices.

After:

> Jot keeps your notes as plain Markdown files in a folder you choose, so they still open in ten years with or without Jot. It syncs through any folder sync you already use.

Why: the "before" uses four banned words and still doesn't say what Jot does. The "after" names the format, the folder and the reason you'd care.

## Docs

Before:

> Jot's powerful export feature lets you effortlessly unlock your data in a variety of formats!

After:

> `jot export --format html ./site` writes one HTML page per note into `./site`. It prints each file as it goes:
>
> ```
> wrote site/index.html
> wrote site/groceries.html
> ```

Why: docs are there to be used, not to sell. Give the exact command and its real output.

## Release notes

Before:

> This release includes various improvements and bug fixes. Thanks to all our contributors!

After:

> **Search is now instant on big folders.** On 20,000 notes, the first result shows up in 40 ms instead of 3 s. Thanks @rkhan for the index (#212).
>
> **Fixed:** notes with an emoji in the title no longer fail to sync (#219, thanks @mlopez).

Why: say what each change does for the reader, with the figure, and thank each person by handle next to their work. Leave out anything that didn't merge, even if it's nearly done.

## CHANGELOG entry

Before:

> ## 2.1.0
>
> - Various fixes and improvements.

After:

> ## 2.1.0 (2026-03-14)
>
> **Before you upgrade:** `sync_dir` in `jot.toml` is now `folder`. Jot still reads the old name, and warns each time it starts until you rename it (#230).
>
> **Changed**
>
> - Search matches whole words. Add a `*` for the old prefix match: `meet*` finds "meeting" (#224).
>
> **Fixed**
>
> - `jot export` no longer skips images with a space in their path (#227).
> - A note renamed on two devices at once keeps both copies instead of losing one (#233).

Why: the person reading a changelog is deciding whether an upgrade breaks their setup. Put what they have to do first, say which behaviour changes under their fingers, and link every line to its issue. "Various fixes" tells them nothing, so they have to read the commits.

## Reply to a contributor

Before:

> Thank you for your contribution. Your pull request is under review and will be processed in due course.

After:

> Thanks, Priya. Splitting the parser out made this much easier to read. I'll review it properly by Friday. If CI asks for approval in the meantime, that's normal for a first PR from a fork. I'll approve it once I've read the diff.

Why: use their name, thank them for the specific thing they did, and give a next step with a date.

## Post

Before:

> In today's fast-paced world, staying organised is more important than ever. That's why we're excited to announce Jot 2.0!

After:

> I lost a week of notes to a sync app that went bust. Jot 2.0 is my answer to that: plain files, your folder, no account. Here's what it looks like after a year of daily use.

Why: start with the reader's problem, or yours if it's the same one. Then show the thing.
