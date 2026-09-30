-- v1.13.8: Ingredients from different recipe sections share one shopping-list item.
-- Example: 3 eggs in "Teig" + 3 eggs in "Füllung" => 6 eggs.

create or replace function public.merge_recipe_shopping_item()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
declare
  existing_id uuid;
  merge_key text;
begin
  if coalesce(new.source, '') <> 'recipe' then
    return new;
  end if;

  merge_key := coalesce(new.personal_today_plan_id::text, '')
    || '|' || coalesce(new.shared_recipe_plan_id::text, '')
    || '|' || lower(btrim(new.name))
    || '|' || lower(btrim(new.unit));

  -- Serialize concurrent inserts of the same ingredient for the same plan.
  perform pg_advisory_xact_lock(hashtextextended(merge_key, 0));

  select si.id
    into existing_id
  from public.shopping_items si
  where si.id <> new.id
    and si.source = 'recipe'
    and lower(btrim(si.name)) = lower(btrim(new.name))
    and lower(btrim(si.unit)) = lower(btrim(new.unit))
    and (
      (new.personal_today_plan_id is not null and si.personal_today_plan_id = new.personal_today_plan_id)
      or
      (new.shared_recipe_plan_id is not null and si.shared_recipe_plan_id = new.shared_recipe_plan_id)
    )
  order by si.created_at, si.id
  limit 1
  for update;

  if existing_id is not null then
    update public.shopping_items
       set quantity = quantity + new.quantity,
           checked = checked or new.checked,
           checked_by = case when checked then checked_by else new.checked_by end
     where id = existing_id;

    delete from public.shopping_items where id = new.id;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_merge_recipe_shopping_item on public.shopping_items;
create trigger trg_merge_recipe_shopping_item
after insert on public.shopping_items
for each row
execute function public.merge_recipe_shopping_item();

-- Consolidate recipe duplicates that already exist before this migration.
do $$
declare
  r record;
  keep_id uuid;
begin
  for r in
    select
      coalesce(personal_today_plan_id::text, '') as personal_plan_key,
      coalesce(shared_recipe_plan_id::text, '') as shared_plan_key,
      lower(btrim(name)) as normalized_name,
      lower(btrim(unit)) as normalized_unit,
      min(id::text)::uuid as keep_id
    from public.shopping_items
    where source = 'recipe'
    group by
      coalesce(personal_today_plan_id::text, ''),
      coalesce(shared_recipe_plan_id::text, ''),
      lower(btrim(name)),
      lower(btrim(unit))
    having count(*) > 1
  loop
    keep_id := r.keep_id;

    update public.shopping_items keep_item
       set quantity = totals.total_quantity,
           checked = totals.any_checked,
           checked_by = case when totals.any_checked then keep_item.checked_by else null end
      from (
        select
          sum(si.quantity) as total_quantity,
          bool_or(si.checked) as any_checked
        from public.shopping_items si
        where si.source = 'recipe'
          and lower(btrim(si.name)) = r.normalized_name
          and lower(btrim(si.unit)) = r.normalized_unit
          and coalesce(si.personal_today_plan_id::text, '') = r.personal_plan_key
          and coalesce(si.shared_recipe_plan_id::text, '') = r.shared_plan_key
      ) totals
     where keep_item.id = keep_id;

    delete from public.shopping_items si
     where si.source = 'recipe'
       and si.id <> keep_id
       and lower(btrim(si.name)) = r.normalized_name
       and lower(btrim(si.unit)) = r.normalized_unit
       and coalesce(si.personal_today_plan_id::text, '') = r.personal_plan_key
       and coalesce(si.shared_recipe_plan_id::text, '') = r.shared_plan_key;
  end loop;
end;
$$;
