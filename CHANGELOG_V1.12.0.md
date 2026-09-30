# Personal-First UX and Recipe Suggestions

- Today shows only **Entscheidung entfernen** for an existing personal decision; changing is done by removing and choosing again.
- Recipe Detail shows **Für heute ausgewählt** instead of a redundant personal Today action when the opened recipe is already today's personal recipe.
- Connection mode now supports explicit recipe suggestions with pending/accepted/declined/cancelled states. Suggestions never overwrite a personal TodayPlan and do not transfer recipe ownership.
- Suggested recipes are readable only through an explicit connection suggestion, with matching ingredient RLS.


## Personal Today Decision Types

- Personal Today now persists `recipe`, `order`, `dine_out`, and `surprise` decisions without faking non-recipe choices as recipes.
- Collaboration decision flows no longer write the decider's personal TodayPlan.
- Today can remove a non-recipe decision as well as a recipe decision.
- Added regression coverage for decision types and the personal/collaboration boundary.
# Schmackofatz V1.12.0

## Personal First

- Persönlicher TodayPlan ist unabhängig von einer Connection.
- `shared_recipe_plans` ist ausschließlich Collaboration.
- Persönliche Einkaufsartikel werden getrennt von gemeinsamen Einkaufsartikeln gespeichert.
- Rezeptauswahl für heute funktioniert ohne Connection.
- Neues/importiertes Rezept kann ohne Connection direkt für heute ausgewählt werden.
- Connections gewähren keinen pauschalen Zugriff mehr auf persönliche Rezept-Saves.
- Gemeinsame Rezeptpläne bleiben explizite Collaboration-Aktionen.
- Persönlicher Status und persönlicher Einkaufsflow sind von Collaboration entkoppelt.

## Sicherheit

- Persönlicher TodayPlan besitzt eigene Ownership-RLS.
- Shopping-Items müssen genau einem persönlichen oder gemeinsamen Plan zugeordnet sein.
- Neue Personal-Today-RPCs laufen als SECURITY INVOKER, damit RLS die Autorisierung übernimmt.

## Connection Readiness Hardening

- Connection-Code generation no longer depends on `gen_random_bytes()`.
- `Entscheide Du` resolves into the requester's personal TodayPlan instead of a shared recipe plan.
- Order/dine-out decisions are persisted only after a concrete restaurant/provider is selected.
- Recipe suggestions use a guarded RPC to avoid recursive RLS evaluation.
- Added live two-user database regression checks for connection, suggestion, decision, isolation and disconnect flows.

## Release

- Version: `1.12.0+211`
- Personal First, Collaboration Optional
