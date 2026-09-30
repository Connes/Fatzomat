# v1.13.0 Decision Ask Navigation Fix

## Fix
- `Entscheide Du` carries only a request/message and intentionally has no decision snapshot.
- Pressing `Los geht's` now navigates directly to the personal `Heute` page.
- The app no longer tries to apply `decisionType`/`decisionValue` for an `ask` message.
- `Entscheidung geteilt` keeps the existing apply flow: the shared decision is written into the personal Today plan and then opens `Heute`.

## Regression coverage
- Added a static regression assertion for the dedicated `isAsk` navigation branch.
