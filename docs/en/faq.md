---
layout: default
title: FAQ
lang_alt: /faq
---
{% include nav-en.html %}

# Frequently asked questions

## Why is the app not on the Play Store?

Publishing there needs a paid developer account, a listing to maintain and a
review delay on every update. For a v1 written in spare time it was not worth
it. It is not ruled out later.

In the meantime, [installing it by hand]({{ '/en/install' | relative_url }})
takes two minutes, and that page explains each of Android's warnings as it comes.

## Is my data sent anywhere?

No. No account, no server, no usage statistics, no automatic crash reports.
Your snapshots live in a database on your phone and leave it only when you
decide — a CSV export, or a stats card you share yourself.

One nuance, stated in full on the
[privacy page]({{ '/en/privacy' | relative_url }}): on startup the app downloads
a public file listing counter names and categories. It is a read, it sends
nothing about you, and it can be turned off in the settings.

## Adding my stats does not work

Three causes, most common first:

**The text is not from the stats screen.** It has to be the share from Ingress's
stats screen, not a screenshot and not another screen. The app does not read
images.

**You shared a partial period.** If you were on the `WEEK` or `MONTH` tab, the
app refuses the snapshot: saving one week in place of the all-time total would
corrupt your history. Switch back to `ALL TIME` and try again.

**The format changed.** This is the project's main risk: Niantic does not
document this format and can change it without notice. If the error mentions
missing columns, [open an issue](https://github.com/Nohzoh/FieldTally/issues/new)
with an excerpt of the shared text — replace your agent name if you like, only
the column names matter.

## A counter is missing, or shows in English under "Other"

That is the intended behaviour, not a bug. The app tracks **every** counter it
finds, including ones it has never seen — it simply shows them under their
original name until someone declares them.

That declaration happens in one public file,
[`counters.json`](https://github.com/Nohzoh/FieldTally/blob/main/docs/registry/counters.json),
which the app fetches on startup. So a new anomaly counter can be named and
categorised for everyone **without a new version of the app**. It is the most
useful contribution you can make.

## The counter names do not match the game

The game shows counter names in English even when its interface is in another
language. FieldTally translates them. To find the match, open the counter: its
detail screen shows the **export column name**, which is the game's exact
wording.

## I am changing phones, do I lose everything?

Export your CSV first (menu → **Snapshots** → export). On the new phone, the
import reads that file. There is no automatic sync: there is no server to do it.

## Can I bring my Agent Stats history over?

Yes. The Agent Stats CSV export is read as is: menu → **Snapshots** → **Import
from Agent Stats**. The whole history comes across at once.

Note that this format does not say whether a row is a running total or a period,
so only the consistency check applies to it. The app shows you any regressions
it finds before saving.

## Is the app official? Am I risking my account?

It is not official and has no connection to Niantic. It does not connect to
Ingress, never asks for your credentials and automates nothing in the game. It
reads a piece of text *you* hand it, from a share feature the game provides
itself.
