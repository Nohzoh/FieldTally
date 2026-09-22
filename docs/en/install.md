---
layout: default
title: Install FieldTally
lang_alt: /installer
---
# Install FieldTally

FieldTally is installed from the **Play Store**. The app is in **closed
testing** there: the listing is only visible to people signed up as testers, and
signing up takes three steps, in this order.

**You need:** an Android 8.0 phone or newer, and the Google account you use on
it. There is no iOS build yet.

## 1. Join the group

Open the [FieldTally group](https://groups.google.com/g/fieldtally) with the
Google account your phone uses. The page offers to let you join, one tap is
enough, and there is nobody to wait for.

This is the step nobody guesses, and Play will show you nothing until it is
done. The group is also where changes are announced and where your feedback
goes.

## 2. Sign up as a tester

Open the [sign-up page](https://play.google.com/apps/testing/io.nohzoh.fieldtally)
and accept the test. The same links are posted again in the group's messages
once you have joined.

## 3. Install

The Play listing opens from that same page, and installing works like it does
for any other app.

**If the listing shows as unavailable**, it is almost always step 1 that is
missing, or a Google account other than the one used on the phone. Play
sometimes takes a few minutes to register the sign-up.

## Updating

Nothing to do: Play handles it like it does for your other apps. The app
fetches nothing of its own and asks nothing of you.

## Did you install the APK file?

The versions handed out by hand before the app reached the Play Store carry the
same signing certificate as the ones Play installs. The Play install therefore
lands on top of yours, and your history is kept.

If Play refuses to take over the existing install anyway, you have to uninstall
first — export your CSV before you do, since everything goes with the app.

## First run

Open FieldTally, then in Ingress: stats screen → **Share** → **FieldTally**.
Your first snapshot is saved and the app starts building your history.

Coming from Agent Stats? Copy the table from its export page and paste it into
menu → **Snapshots** → **Import from Agent Stats**. The banner and the
pagination can come along, they are ignored.

## What you can check

- **The source code is public**, all of it, under AGPL v3.
- **The app is built by GitHub Actions** from that source, not on a private
  machine. The build log of every version is public, and it refuses to continue
  if the signature is not the right one.
- **The signing key is the project's own**, the same one since the first
  version. Its SHA-256 fingerprint is:

  ```
  9be340de759dde7f92fcace5f9453a47ee910fa7779ad43912bdda351172ca85
  ```

## Uninstalling

Like any app. Everything goes with it, since nothing exists anywhere else —
export your CSV first if you want to keep your history.
