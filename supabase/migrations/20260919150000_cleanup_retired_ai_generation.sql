-- Retire the old server-side AI recipe generation infrastructure.
-- Recipe generation now happens through the external ChatGPT workflow.

drop function if exists public.release_ai_generation_quota(bigint);
drop function if exists public.consume_ai_generation_quota();
drop function if exists public.consume_ai_generation_quota(integer, integer);
drop table if exists public.ai_generation_events;
