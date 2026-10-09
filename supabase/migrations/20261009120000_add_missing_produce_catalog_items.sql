-- Add missing produce items to the shared onboarding catalog.
-- Knoblauch already exists in the catalog, so it is intentionally not inserted again.
insert into public.foods (id, name, category, default_unit) values
  ('watermelon', 'Wassermelone', 'Obst', 'Stück'),
  ('kiwi', 'Kiwi', 'Obst', 'Stück'),
  ('olive', 'Olive', 'Obst', 'Stück')
on conflict do nothing;
