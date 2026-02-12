# Watch List

Resources monitored but not yet integrated into the guide. Event-driven re-evaluation (not time-based).

## Lifecycle

```
New resource → /eval-resource
  Score >= 3 but not ready → Active Watch
  Score < 3               → Dropped (or not listed)

Trigger reached → re-evaluation → Integrate (Graduated) / Drop (Dropped)
```

## Active Watch

| Resource | Type | Added | Why Watching | Re-eval Trigger |
|----------|------|-------|--------------|-----------------|
| [ICM](https://github.com/rtk-ai/icm) | MCP | 2026-02-12 | Pre-v1 (1 star, 11 commits) | First release + >20 stars |
| [System Prompts](https://github.com/x1xhlol/system-prompts-and-models-of-ai-tools) | Tool | 2026-01-26 | Redundant with official sources | Anthropic confirms CLI prompts not published |

## Graduated

Resources that moved from watch to integrated in the guide.

| Resource | Graduated | Evaluation |
|----------|-----------|------------|

## Dropped

Resources removed from watch after re-evaluation.

| Resource | Dropped | Reason |
|----------|---------|--------|
