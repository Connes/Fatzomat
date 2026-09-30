-- Private two-person product mode: recipe generation happens in the external
-- ChatGPT app and returns a together_recipe JSON file. The paid OpenAI Edge
-- Function is no longer part of the client product path.
revoke all on function public.consume_ai_generation_quota() from public, anon, authenticated;
revoke all on function public.release_ai_generation_quota(bigint) from public, anon, authenticated;
