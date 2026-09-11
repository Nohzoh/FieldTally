---
layout: default
title: Features
lang_alt: /fonctionnalites
---
{% include nav-en.html %}

# Features

## Adding a snapshot

From Ingress, **Share** your stats screen and pick FieldTally: the text arrives
in the app, which shows you what it understood before saving anything. You can
also paste the text by hand.

The app reads columns **by name**, never by position. When Niantic adds or moves
a counter, nothing breaks and nothing shifts by one.

**An unknown counter is not lost.** It is tracked under its original name and
filed under "Other" until someone declares it — which is a small contribution,
not a wait for an app update.

## Two guards on import

Copying "This Week" instead of the all-time total is the easiest mistake to
make and the most annoying: it overwrites your history with tiny numbers.

- The app **refuses** a snapshot that declares itself a partial period.
- It **warns** when a counter went backwards since the previous snapshot,
  naming which one and by how much. You decide.

## Seeing your progress

- **Dashboard**: the counters you pin, with their value, their progress since
  the previous snapshot and a trend line.
- **All counters**: the full list, grouped by category in the game's own order,
  with search and sorting.
- **Counter detail**: a chart over the week, the month or the whole history, an
  activity calendar, and the exact export column name so you can find the
  counter in the game.

## Projections and goals

**Next badge** shows what is left and an estimated date at your recent pace —
over the last seven or thirty days, your choice. When your pace is flat or the
answer is years out, the app says so instead of inventing a date.

You can set a **personal goal** on any counter, with or without a deadline, and
see whether your current pace gets you there.

## Reminders

Two notifications, scheduled on the device and nowhere else:

- a reminder when you have not recorded anything for a while (configurable);
- an announcement when a snapshot crosses a badge tier.

Off until you turn them on.

## Sharing and exporting

- A **stats card** as an image, covering the period you choose, ready to post.
- A **CSV export** of the whole history, to keep elsewhere or move to a new
  phone.

## What does not exist yet

No account, no leaderboard, no head-to-head comparison, no finished iOS build,
no reading of a screenshot. None of that is possible without a server, and v1
has none. See the [roadmap]({{ '/en/roadmap' | relative_url }}).
