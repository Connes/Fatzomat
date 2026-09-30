# Deprecated: generate-recipes

Schmackofatz uses the external ChatGPT workflow for recipe creation.

The Flutter app does not call an OpenAI API. It creates a prompt, the user
runs it in ChatGPT, and Schmackofatz imports the resulting `together_recipe`
JSON file.

The former `generate-recipes` function is retained only as a deployment-name
placeholder for environments where the remote function cannot be deleted by
the project tooling. Its former quota table and RPCs are removed by the
`20260919150000_cleanup_retired_ai_generation` migration.
