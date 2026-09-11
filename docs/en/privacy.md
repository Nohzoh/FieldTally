---
layout: default
title: Privacy
lang_alt: /confidentialite
---
{% include nav-en.html %}

# Privacy

This page is short because there is not much to say. It will be rewritten the
day that stops being true.

## What FieldTally does not do

- No account, no sign-up, no identifier.
- No server: there is no FieldTally database anywhere but on your phone.
- No usage statistics, no advertising tracker, no automatic crash reporting.
- No personal data sent to anyone, including the author of the project.

## Where your data lives

In a local database, inside the app's private storage on your phone. No other
app can read it. Uninstalling erases everything.

Your data leaves only when you ask it to: a CSV export, or a stats card you
share yourself, to a destination you pick. FieldTally does not know where you
sent it and keeps no copy.

## The one network request

On startup, and at most once a day, the app downloads a public file hosted on
GitHub Pages:

```
https://nohzoh.github.io/FieldTally/registry/counters.json
```

It holds counter names, categories and badge thresholds, so a new counter can be
named correctly without waiting for an app update.

In detail, so it is verifiable rather than promised:

- It is a **GET** on a static file. Nothing is sent — no snapshot, no
  identifier, no usage data.
- GitHub, which hosts the file, sees that request the way any web server sees a
  visit: IP address and client type. That is unavoidable once a download
  happens, and it is why the whole thing can be switched off.
- **You can turn it off**: Settings → *Update online*. The app then runs fully
  offline on the copy bundled in the APK. No feature is lost; only counters
  added after the version you installed will keep their original names.

## Notifications

Reminders and badge announcements are scheduled **by your phone**, locally.
There is no push notification, so no server knows when to wake you. They are off
until you turn them on.

## Ingress and Niantic

FieldTally does not connect to Ingress and does not talk to Niantic. It reads a
piece of text you hand it from the game's own share feature.

## If this changes

Adding a server, accounts or an analytics tool would make this page false. The
day that happens, it will be rewritten before, not after, and this site's
history lets you check what it used to say.
