-- v12: beta hardening for shopping lists.
create unique index if not exists shopping_lists_one_active_per_household
  on public.shopping_lists(household_id)
  where status = 'active';

create or replace function public.get_or_create_active_shopping_list(p_household_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
begin
  if not public.is_household_member(p_household_id) then
    raise exception 'not a household member';
  end if;

  select id into v_id
  from public.shopping_lists
  where household_id = p_household_id
    and status = 'active'
  order by created_at desc
  limit 1;

  if v_id is not null then
    return v_id;
  end if;

  insert into public.shopping_lists (household_id, name, status)
  values (p_household_id, 'Einkaufsliste', 'active')
  on conflict do nothing
  returning id into v_id;

  if v_id is null then
    select id into v_id
    from public.shopping_lists
    where household_id = p_household_id
      and status = 'active'
    limit 1;
  end if;

  return v_id;
end;
$$;

grant execute on function public.get_or_create_active_shopping_list(uuid) to authenticated;

alter table public.shopping_list_items
  drop constraint if exists shopping_list_items_quantity_positive;

alter table public.shopping_list_items
  add constraint shopping_list_items_quantity_positive
  check (quantity > 0);
