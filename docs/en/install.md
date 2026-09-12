---
layout: default
title: Install FieldTally
lang_alt: /installer
---
{% include nav-en.html %}

# Install FieldTally

FieldTally is not on the Play Store. You install an `.apk` file directly, which
Android calls sideloading. It is normal and safe, but your phone will ask you
two unusual questions along the way. Here they are in order, with what to
answer.

**You need:** an Android 8.0 phone or newer. There is no iOS build yet.

## 1. Download the file

Open the [releases page](https://github.com/Nohzoh/FieldTally/releases/latest)
and tap the file ending in **`.apk`**.

Your browser may say "This type of file can harm your device". That is a generic
message Android shows for **every** APK, whatever it contains. Tap **Download
anyway**.

## 2. Allow the installation

Open the downloaded file. Android says:

> For your security, your phone is not allowed to install unknown apps from
> this source.

Tap **Settings**, turn on **Allow from this source**, then go back. The
permission applies only to the app you downloaded from (your browser), and you
can revoke it afterwards.

## 3. The Play Protect warning

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

## 4. First run

Open FieldTally, then in Ingress: stats screen → **Share** → **FieldTally**.
Your first snapshot is saved and the app starts building your history.

Coming from Agent Stats? Your existing CSV export is read as is: menu →
**Snapshots** → **Import from Agent Stats**.

## Updating

Download the new APK from the same page and install it over the old one. Your
data is kept. **Only use APKs published here**: an update signed with a
different key is refused by Android, which is exactly what the signature is
for.

There is no automatic update — a sideloaded app has no store to notify it. If
you want one, [Obtainium](https://github.com/ImranR98/Obtainium) follows GitHub
releases and handles it.

## Uninstalling

Like any app. Everything goes with it, since nothing exists anywhere else —
export your CSV first if you want to keep your history.
