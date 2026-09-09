---
layout: default
title: Home
---

# FieldTally

**FieldTally** is a mobile app for tracking your [Ingress](https://ingress.com)
statistics, designed for the phone and running **entirely locally**: no
account, no server, no data sent anywhere.

> ⚠️ **Under construction.** The repository holds the parser, the import guards
> and a first screen; there is no installable release yet.

## Not affiliated with Niantic

FieldTally is an **unofficial, fan-made** tool with no connection to Niantic,
Inc. "Ingress", along with badge and counter names, are trademarks and content
of Niantic, Inc. This project uses no protected asset.

## What already exists

- The [full v1 specification](spec/SPECIFICATION-v1.md) (written in French).
- The [counter registry](registry/counters.json), source of truth for
  categorisation, labels and — eventually — badge thresholds.

## Contributing

The most useful contribution, and the simplest, is adding or fixing an entry in
`docs/registry/counters.json` when a new counter shows up in the game. No Dart
knowledge required: see
[CONTRIBUTING.md](https://github.com/Nohzoh/FieldTally/blob/main/CONTRIBUTING.md).
