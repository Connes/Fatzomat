# Schmackofatz v1.13.0 – Shared Recipe Shopping on Accept

- When a shared Today decision is a recipe and the recipient accepts it, the backend now creates the shared recipe plan.
- The recipe ingredients are copied into `shopping_items` under `shared_recipe_plan_id`, scaled to the shared serving count.
- Both connected partners can therefore use the same common shopping list through the existing shared shopping-list flow.
- Cancelling the linked shared Today decision removes the shared recipe plan, which cascades its shopping items, and notifies the connected partner.
