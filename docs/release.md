# Cutting a release

The release pipeline (§7.2) builds a signed APK and attaches it to a GitHub
Release. It runs only on a `v*` tag or a manual dispatch — never on a pull
request, because it holds the signing key and this repository is public.

## One-time setup

### 1. Generate the keystore

Somewhere **outside this repository**:

```sh
keytool -genkeypair -v \
  -keystore fieldtally-release.jks \
  -alias fieldtally \
  -keyalg RSA -keysize 4096 \
  -validity 10000 \
  -storetype PKCS12
```

`keytool` asks for a password and for identity fields; only `CN` matters, and
none of it is shown to users. All of it is permanent for the life of the app.

**Use the same password for the keystore and for the key.** PKCS12 does not
support separate ones: `keytool` accepts `-keypass`, prints a warning, and
ignores it. A build configured with two different passwords fails at packaging
time with `Given final block not properly padded`, which does not point
anywhere near the real cause.

**Back up the `.jks` file and the password before going further.** FieldTally
is sideloaded, so there is no Play App Signing to fall back on: this key *is*
the app's identity. Losing it means no existing install can ever be updated —
every user would have to uninstall, losing their local history.

### 2. Add the repository secrets

```sh
base64 -i fieldtally-release.jks | tr -d '\n'
```

Under **Settings → Secrets and variables → Actions**, add four secrets:

| Secret | Value |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | the base64 output above |
| `KEY_ALIAS` | `fieldtally` |
| `KEY_PASSWORD` | the keystore password |
| `STORE_PASSWORD` | the same password again |

The workflow fails on its first step, naming the missing ones, if any is absent.

### 3. Check it before tagging anything

Run the **Release** workflow manually from the Actions tab. A manual run stops
at an artifact instead of publishing, so it proves the signing works without
creating a release. The job summary prints the certificate fingerprint.

## Publishing

```sh
git tag -s v1.0.0 -m "FieldTally 1.0.0"
git push origin v1.0.0
```

The tag must be signed, like every commit here. The workflow builds, refuses to
continue if the APK turns out to be debug-signed, and publishes a release whose
notes are generated from the pull requests merged since the previous tag.

Bump `version:` in `app/pubspec.yaml` before tagging: it is what becomes
`versionName` and `versionCode`, and Android refuses to install an update whose
`versionCode` has not increased.

## Verifying a downloaded APK

```sh
"$ANDROID_HOME"/build-tools/*/apksigner verify --print-certs fieldtally.apk
```

The SHA-256 digest should match the one printed in the release job summary.
Note that `keytool -printcert -jarfile` reports nothing useful here: `minSdk`
is 26, so the APK carries a v2/v3 signature and no v1 JAR signature.
