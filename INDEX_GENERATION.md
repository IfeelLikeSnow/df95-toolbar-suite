# index.xml generation

`index.xml` is the ReaPack repository index.

- It must be valid XML starting with `<?xml ...?>` and a root `<index ...>` element.
- It is generated and updated by `reapack-index` (GitHub Actions deploy workflow).

If you ever see `index.xml` replaced by plain text (URLs, logs, etc.), ReaPack imports will break.

Fix:
1) Restore a valid `index.xml` (or this placeholder),
2) Ensure GitHub Actions `deploy` runs `reapack-index --scan --amend --commit .`,
3) Sync in REAPER.

