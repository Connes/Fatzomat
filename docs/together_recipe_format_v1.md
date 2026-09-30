# together_recipe Format v1

`together_recipe` is the stable, AI-agnostic import/export format used by Schmackofatz.

## Structure

```json
{
  "format": "together_recipe",
  "version": 1,
  "recipe": {
    "title": "Kartoffelgratin",
    "description": "Einfaches Gratin",
    "servings": 4,
    "prep_time_minutes": 10,
    "cook_time_minutes": 45,
    "difficulty": "Einfach",
    "ingredients": [
      {
        "name": "Kartoffeln",
        "amount": 800,
        "unit": "g"
      }
    ],
    "steps": [
      "Kartoffeln schälen und schneiden."
    ]
  }
}
```

## Rules

- `format` must be `together_recipe`.
- `version` must currently be `1`.
- `recipe.title` is required.
- `recipe.ingredients` and `recipe.steps` are required arrays.
- Each ingredient requires `name` and `unit`. `amount` should normally be numeric; `null` is explicitly allowed for qualitative amounts such as „Prise“ or „nach Bedarf“ and is normalized to the internal quantity `1`.
- Optional `food_id` can preserve a known together food ID.
- Unknown/extra JSON fields are ignored so the format can evolve without breaking old imports.
- The app shows an import preview before saving.
- Importing this format does not use an AI service or the OpenAI API.

ChatGPT can create this file from recipe text or a photo; the resulting JSON is then imported into Schmackofatz.


## Import limits

Schmackofatz accepts recipe files up to 1 MB, with at most 50 ingredients and 50 preparation steps. Titles, ingredient names, units and steps are length-limited to keep externally supplied data bounded.
