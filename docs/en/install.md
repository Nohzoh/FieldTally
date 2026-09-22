---
layout: default
title: Install FieldTally
lang_alt: /installer
---
# Install FieldTally

There are two ways to install FieldTally: from the **Play Store**, by joining
the closed test, or by installing the `.apk` file **by hand**. The first is
simpler and handles updates on its own; the second needs no Google account.

**You need:** an Android 8.0 phone or newer. There is no iOS build yet.

## From the Play Store

The app is in **closed testing**: the listing is only visible to people signed
up as testers. Three steps, in this order.

1. **Join the [FieldTally group](https://groups.google.com/g/fieldtally)** with
   the Google account your phone uses. The link offers to let you join, one tap
   is enough, and there is nobody to wait for.
2. **Sign up as a tester** on
   [this page](https://play.google.com/apps/testing/io.nohzoh.fieldtally) and
   accept the test.
3. **Install from the Play listing**, like any other app.

If the listing shows as unavailable, it is almost always step 1 that is
missing, or a Google account other than the one used on the phone. The group's
messages carry those same links once you have joined.

Updates then arrive on their own, like for your other apps, and none of the
warnings in the next section appear.

## By hand, with the APK file

This is what Android calls sideloading. It is normal and safe, but your phone
will ask you two unusual questions along the way. Here they are in order, with
what to answer.

### 1. Download the file

Open the [releases page](https://github.com/Nohzoh/FieldTally/releases/latest)
and tap the file ending in **`.apk`**.

Your browser may say "This type of file can harm your device". That is a generic
message Android shows for **every** APK, whatever it contains. Tap **Download
anyway**.

### 2. Allow the installation

Open the downloaded file. Android says:

> For your security, your phone is not allowed to install unknown apps from
> this source.

Tap **Settings**, turn on **Allow from this source**, then go back. The
permission applies only to the app you downloaded from (your browser), and you
can revoke it afterwards.

### 3. The Play Protect warning

This is the scary screen, and the one where people give up:

> **App blocked to protect your device**
>
> Play Protect hasn't seen this developer before. The app may not be safe.

**This does not mean anything was detected.** What Play Protect does not
recognise is the **signing key**: it groups apps by key, and FieldTally's is
recent, so it has not been seen on many devices. A malicious app and a perfectly
clean one produce exactly the same screen. The verdict fades on its own as the
app gets installed.

**The only visible button is OK, and it cancels the install.** To continue, tap
**"More details"** first: the option to install anyway appears underneath. Its
exact wording varies between Android versions.

What you can check for yourself, which is worth more than a promise:

- **The source code is public**, all of it, under AGPL v3.
- **The APK is built by GitHub Actions** from that source, not on a private
  machine. The build log of every release is public.
- **Every release is signed** with the same key. Its SHA-256 fingerprint is:

  ```
  9be340de759dde7f92fcace5f9453a47ee910fa7779ad43912bdda351172ca85
  ```

  It is printed in the build log of each release. If an APK claiming to be
  FieldTally ever carries a different fingerprint, it did not come from here.

  It is the same key the Play Store build uses: both ways of installing give
  you the same application.

### Updating

Download the new APK from the same page and install it over the old one. Your
data is kept. **Only use APKs published here**: an update signed with a
different key is refused by Android, which is exactly what the signature is
for.

The app tells you when a release is out: Settings names the version and opens
its page. It learns that by reading one small public file from the project
site, under the same *Update online* setting as the counter registry, and it
sends nothing.

**It never installs anything itself.** Doing so would mean asking Android for
the right to install applications, and an app whose whole argument is that it
does almost nothing should not widen what it can do to save you two taps. You
download and install it the way you did the first time.

If you want real automation, [Obtainium](https://github.com/ImranR98/Obtainium)
follows GitHub releases and handles detection, download and install.

## First run

However you installed it: open FieldTally, then in Ingress: stats screen →
**Share** → **FieldTally**. Your first snapshot is saved and the app starts
building your history.

Coming from Agent Stats? Copy the table from its export page and paste it into
menu → **Snapshots** → **Import from Agent Stats**. The banner and the
pagination can come along, they are ignored.

## Uninstalling

Like any app. Everything goes with it, since nothing exists anywhere else —
export your CSV first if you want to keep your history.
