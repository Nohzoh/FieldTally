---
layout: default
title: Features
lang_alt: /fonctionnalites
---
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
  with search, sorting and filters. Counters that carry a badge show its
  emblem, with the tier you have reached named beside it — and the list can be
  narrowed to those counters alone, or ordered by the badge you are closest to.
  Recent progress is measured as a pace per day over a window you pick, so
  counters you record at different rhythms can be compared.
- **Counter detail**: a chart over the week, the month or the whole history,
  with a line at what you are chasing — your goal if you set one, otherwise the
  next badge. Plus an activity calendar and the exact export column name so you
  can find the counter in the game.

Under the **Events** category, the app says since when it has been watching. The
Ingress export is cumulative, so every counter it carries arrives complete — but
an event's column eventually leaves it. An event that closed before your first
snapshot is nowhere, and the app says so rather than letting its silence pass
for a medal you failed to earn.

## Projections and goals

**Next badge** shows what is left and an estimated date at your recent pace —
over the last seven or thirty days, your choice. When your pace is flat or the
answer is years out, the app says so instead of inventing a date.

Onyx is not the end of it. Past the top threshold the app counts in multiples
of it, the way the game does: how many whole times over you are, and what is
left to the next one.

**Anomaly medals** — a campaign's Global Op and its Season medal — are
recognisable by their broken rim rather than a solid one: they stop being
earnable on a date, and the app knows it. The Global Op's carries a stud at the
top as well. Their thresholds arrive through the registry rather than an app
update, so a campaign that opens is understood without installing anything.

You can set a **personal goal** on any counter, with or without a deadline, and
see whether your current pace gets you there. On the chart, the scale stretches
to hold the target even when that flattens the curve against the bottom: that
flattening is the information, telling you at a glance that what you are after
is a long way off.

## Reminders

Two notifications, scheduled on the device and nowhere else:

- a reminder when you have not recorded anything for a while (configurable);
- an announcement when a snapshot crosses a badge tier, passes the top one
  another whole time, or takes you up a level.

Off until you turn them on.

## Sharing and exporting

- A **stats card** as an image, covering the period you choose, ready to post.
- A **CSV export** of the whole history, to keep elsewhere or move to a new
  phone.
- A **comparison with an agent next to you**: send them your totals through the
  Android share sheet and their app puts your numbers side by side, counter by
  counter. No server, and what they send you never enters your history.

## What does not exist yet

No account, no leaderboard, no comparison at a distance and no overlaid curves.
None of that exists without a server, and v1 has none — which is exactly what
lets it ask for nothing and collect nothing. Comparing in person does work: two
phones in the same room need nobody.

No iOS build either, and no reading of a screenshot. Those two are not about the
server: the first needs a paid developer account and a trip through the App
Store, the second would only matter if the game's share text ever disappeared.

What is missing, and what is being considered, is tracked in the
[issues](https://github.com/Nohzoh/FieldTally/issues).
