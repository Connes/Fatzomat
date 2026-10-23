-- Prevent duplicate custom foods regardless of letter case or surrounding whitespace.
-- Existing duplicate custom rows must be resolved before this migration can be applied.
create unique index if not exists foods_custom_name_normalized_unique
  on public.foods (lower(btrim(name)))
  where created_by is not null;

