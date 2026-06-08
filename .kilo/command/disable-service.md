---
name: disable-service
description: Disable a single service include in its aggregator compose
trigger: /disable-service
---

## Usage

```
/disable-service <service-name>
```

## Rules

- Comment out the matching `include:` line in the relevant aggregator.
- Do NOT delete services' own compose files.
- Run `Format-YmlFiles.ps1` after the change.
