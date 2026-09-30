# Legacy AI recipe diagnostics

This document describes the former server-side `generate-recipes` workflow.
It is retained as historical context only.

The current private two-person product does not call the OpenAI API. Recipe
creation happens in the external ChatGPT app and crosses the app boundary via
the versioned `together_recipe` JSON file.
