---
layout: default
title: FieldTally
lang_alt: /
---
{% include nav-en.html %}

# FieldTally

**Track your Ingress stats on your phone, with no account and no server.**
Everything stays on the device: nothing to sign up for, nothing sent anywhere.

> ⚠️ **Unofficial.** FieldTally is a fan-made tool with no connection to
> Niantic, Inc. "Ingress", along with badge and counter names, are trademarks
> and content of Niantic, Inc. This project uses no protected asset.

<p>
<img src="{{ '/assets/screenshots/dashboard.png' | relative_url }}" alt="Dashboard: four pinned counters with their value, their progress and a trend line" width="240">
<img src="{{ '/assets/screenshots/detail.png' | relative_url }}" alt="Counter detail: chart over the whole history and the projection for the next badge" width="240">
<img src="{{ '/assets/screenshots/share-card.png' | relative_url }}" alt="Shareable stats card as an image" width="240">
</p>

## How it works

1. In Ingress, open your stats screen and tap **Share**.
2. Pick **FieldTally**. The text lands straight in the app.
3. Check the preview and save. That's it.

Every snapshot is dated and kept. Over time the app shows your progress counter
by counter, each on its own scale rather than as one unreadable chart.

## What you get

- **A dashboard** of the handful of counters *you* picked.
- **One chart per counter**, on its own scale.
- **A badge projection**: how much is left, and the date at your recent pace —
  or nothing at all when your pace cannot support an honest estimate.
- **Personal goals** and **reminders**, scheduled on the device.
- **A stats card** as an image, ready to post.
- **A full CSV export** of your history, whenever you want it.

[See all features]({{ '/en/features' | relative_url }}) ·
[Install the app]({{ '/en/install' | relative_url }})

## Why not just Agent Stats?

FieldTally is not out to replace Agent Stats, and it reads its export so you can
bring your existing history over. Three things differ: everything stays on your
phone, every counter gets its own scale, and the app refuses to record a partial
snapshot ("this week" instead of the all-time total) that would quietly corrupt
your history.
