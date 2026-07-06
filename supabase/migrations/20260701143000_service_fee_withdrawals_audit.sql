alter table public.orders
  add column if not exists service_fee numeric(12,2) not null default 6000;

update public.orders
set service_fee = 6000
where service_fee is null or service_fee = 0;

do $$
begin
  if not exists (select 1 from pg_type where typname = 'withdrawal_status') then
    create type public.withdrawal_status as enum (
      'pending',
      'processing',
      'paid',
      'rejected'
    );
  end if;
end $$;

create table if not exists public.technician_withdrawals (
  id uuid primary key default gen_random_uuid(),
  technician_id uuid not null references public.technician_profiles(id) on delete cascade,
  amount numeric(12,2) not null,
  bank_name text not null,
  account_number text not null,
  account_holder text not null,
  status public.withdrawal_status not null default 'pending',
  admin_note text,
  requested_at timestamptz not null default now(),
  processed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint technician_withdrawals_amount_positive check (amount > 0)
);

create index if not exists technician_withdrawals_technician_id_idx
  on public.technician_withdrawals(technician_id);
create index if not exists technician_withdrawals_status_idx
  on public.technician_withdrawals(status);

drop trigger if exists technician_withdrawals_set_updated_at on public.technician_withdrawals;
create trigger technician_withdrawals_set_updated_at
before update on public.technician_withdrawals
for each row execute function public.set_updated_at();

create table if not exists public.admin_audit_logs (
  id uuid primary key default gen_random_uuid(),
  admin_id uuid references public.profiles(id) on delete set null,
  action text not null,
  entity text not null,
  entity_id uuid,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists admin_audit_logs_created_at_idx
  on public.admin_audit_logs(created_at desc);
create index if not exists admin_audit_logs_entity_idx
  on public.admin_audit_logs(entity, entity_id);

create or replace function public.log_admin_action(
  p_action text,
  p_entity text,
  p_entity_id uuid default null,
  p_metadata jsonb default '{}'::jsonb
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    return;
  end if;

  insert into public.admin_audit_logs (admin_id, action, entity, entity_id, metadata)
  values (auth.uid(), p_action, p_entity, p_entity_id, coalesce(p_metadata, '{}'::jsonb));
end;
$$;

create or replace function public.apply_order_totals()
returns trigger
language plpgsql
as $$
declare
  platform_base numeric;
begin
  platform_base := greatest(coalesce(new.final_total, 0) - coalesce(new.service_fee, 0), 0);
  new.commission_amount = round(
    (platform_base * coalesce(new.commission_percentage, 0) / 100) + coalesce(new.service_fee, 0),
    2
  );
  new.technician_income = greatest(coalesce(new.final_total, 0) - new.commission_amount, 0);
  return new;
end;
$$;

drop trigger if exists orders_apply_totals on public.orders;
create trigger orders_apply_totals
before insert or update of final_total, commission_percentage, service_fee on public.orders
for each row execute function public.apply_order_totals();

create or replace function public.submit_order_diagnosis(
  p_order_id uuid,
  p_diagnosis_result text,
  p_work_estimation text,
  p_service_cost numeric,
  p_spareparts jsonb default '[]'::jsonb
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  current_technician uuid;
  sparepart_item jsonb;
  sparepart_id uuid;
  sparepart_name text;
  sparepart_qty integer;
  sparepart_price numeric;
  sparepart_total numeric := 0;
  order_service_fee numeric := 6000;
begin
  current_technician := public.current_technician_profile_id();

  if current_technician is null then
    raise exception 'Profil teknisi tidak ditemukan';
  end if;

  select coalesce(service_fee, 6000)
  into order_service_fee
  from public.orders
  where id = p_order_id
    and technician_id = current_technician
    and status in ('inspection', 'waiting_price_approval', 'in_progress');

  if not found then
    raise exception 'Order tidak tersedia untuk diagnosis';
  end if;

  insert into public.diagnoses (
    order_id,
    technician_id,
    diagnosis_result,
    work_estimation,
    service_cost,
    sparepart_cost
  )
  values (
    p_order_id,
    current_technician,
    trim(p_diagnosis_result),
    nullif(trim(coalesce(p_work_estimation, '')), ''),
    greatest(coalesce(p_service_cost, 0), 0),
    0
  )
  on conflict (order_id) do update
  set
    diagnosis_result = excluded.diagnosis_result,
    work_estimation = excluded.work_estimation,
    service_cost = excluded.service_cost,
    updated_at = now();

  delete from public.order_spareparts
  where order_id = p_order_id;

  for sparepart_item in select * from jsonb_array_elements(coalesce(p_spareparts, '[]'::jsonb))
  loop
    sparepart_name := nullif(trim(sparepart_item ->> 'name'), '');
    sparepart_qty := greatest(coalesce(nullif(sparepart_item ->> 'quantity', '')::integer, 1), 1);
    sparepart_price := greatest(coalesce(nullif(sparepart_item ->> 'unit_price', '')::numeric, 0), 0);

    if sparepart_name is null then
      continue;
    end if;

    insert into public.spareparts (name)
    values (sparepart_name)
    on conflict (name) do update
    set updated_at = now()
    returning id into sparepart_id;

    insert into public.order_spareparts (
      order_id,
      sparepart_id,
      sparepart_name,
      quantity,
      unit_price
    )
    values (
      p_order_id,
      sparepart_id,
      sparepart_name,
      sparepart_qty,
      sparepart_price
    );

    sparepart_total := sparepart_total + (sparepart_qty * sparepart_price);
  end loop;

  update public.diagnoses
  set sparepart_cost = sparepart_total
  where order_id = p_order_id;

  update public.orders
  set
    final_total = greatest(coalesce(p_service_cost, 0), 0) + sparepart_total + order_service_fee,
    service_fee = order_service_fee,
    status = 'waiting_price_approval'
  where id = p_order_id;
end;
$$;

alter table public.technician_withdrawals enable row level security;
alter table public.admin_audit_logs enable row level security;

drop policy if exists "Technicians read own withdrawals" on public.technician_withdrawals;
create policy "Technicians read own withdrawals"
on public.technician_withdrawals
for select to authenticated
using (
  public.is_admin()
  or technician_id = public.current_technician_profile_id()
);

drop policy if exists "Technicians create own withdrawal requests" on public.technician_withdrawals;
create policy "Technicians create own withdrawal requests"
on public.technician_withdrawals
for insert to authenticated
with check (
  technician_id = public.current_technician_profile_id()
);

drop policy if exists "Admins update withdrawals" on public.technician_withdrawals;
create policy "Admins update withdrawals"
on public.technician_withdrawals
for update to authenticated
using (public.is_admin())
with check (public.is_admin());

drop policy if exists "Admins delete withdrawals" on public.technician_withdrawals;
create policy "Admins delete withdrawals"
on public.technician_withdrawals
for delete to authenticated
using (public.is_admin());

drop policy if exists "Admins read audit logs" on public.admin_audit_logs;
create policy "Admins read audit logs"
on public.admin_audit_logs
for select to authenticated
using (public.is_admin());

drop policy if exists "Admins write audit logs" on public.admin_audit_logs;
create policy "Admins write audit logs"
on public.admin_audit_logs
for insert to authenticated
with check (public.is_admin());
