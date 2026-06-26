-- Si Teknisi initial Supabase backend schema.
-- Run with Supabase CLI or paste into Supabase SQL editor.

create extension if not exists "pgcrypto";

do $$
begin
  if exists (select 1 from pg_type where typname = 'payment_status')
    and not exists (
      select 1
      from pg_enum e
      join pg_type t on t.oid = e.enumtypid
      where t.typname = 'payment_status'
        and e.enumlabel = 'unpaid'
    )
    and not exists (select 1 from pg_type where typname = 'legacy_payment_status') then
    alter type public.payment_status rename to legacy_payment_status;
  end if;

  if not exists (select 1 from pg_type where typname = 'app_role') then
    create type public.app_role as enum ('customer', 'technician', 'admin');
  end if;
  if not exists (select 1 from pg_type where typname = 'verification_status') then
    create type public.verification_status as enum ('pending', 'verified', 'rejected', 'inactive');
  end if;
  if not exists (select 1 from pg_type where typname = 'service_approval_status') then
    create type public.service_approval_status as enum ('pending', 'approved', 'rejected');
  end if;
  if not exists (select 1 from pg_type where typname = 'order_status') then
    create type public.order_status as enum (
      'waiting_confirmation',
      'accepted',
      'on_the_way',
      'inspection',
      'waiting_price_approval',
      'in_progress',
      'waiting_payment',
      'completed',
      'rejected',
      'price_rejected'
    );
  end if;
  if not exists (select 1 from pg_type where typname = 'payment_method') then
    create type public.payment_method as enum ('cash', 'bank_transfer');
  end if;
  if not exists (select 1 from pg_type where typname = 'payment_status') then
    create type public.payment_status as enum ('unpaid', 'waiting_verification', 'paid', 'rejected');
  end if;
  if not exists (select 1 from pg_type where typname = 'warranty_status') then
    create type public.warranty_status as enum ('active', 'expired', 'claimed', 'void');
  end if;
  if not exists (select 1 from pg_type where typname = 'notification_type') then
    create type public.notification_type as enum (
      'technician_registered',
      'technician_verified',
      'service_approved',
      'new_order',
      'order_accepted',
      'order_rejected',
      'price_approval_requested',
      'price_approved',
      'work_completed',
      'payment_paid'
    );
  end if;
end $$;

do $$
declare
  policy_record record;
begin
  for policy_record in
    select schemaname, tablename, policyname
    from pg_policies
    where schemaname in ('public', 'storage')
  loop
    execute format(
      'drop policy if exists %I on %I.%I',
      policy_record.policyname,
      policy_record.schemaname,
      policy_record.tablename
    );
  end loop;

  if exists (
    select 1
    from information_schema.tables
    where table_schema = 'public'
      and table_name = 'services'
  ) and not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'services'
      and column_name = 'technician_id'
  ) then
    if not exists (
      select 1
      from information_schema.tables
      where table_schema = 'public'
        and table_name = 'legacy_services'
    ) then
      alter table public.services rename to legacy_services;
    end if;
  end if;

  if exists (
    select 1 from information_schema.tables
    where table_schema = 'public' and table_name = 'payments'
  ) and not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'payments' and column_name = 'order_id'
  ) then
    if not exists (
      select 1 from information_schema.tables
      where table_schema = 'public' and table_name = 'legacy_payments'
    ) then
      alter table public.payments rename to legacy_payments;
    end if;
  end if;

  if exists (
    select 1 from information_schema.tables
    where table_schema = 'public' and table_name = 'reviews'
  ) and not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'reviews' and column_name = 'order_id'
  ) then
    if not exists (
      select 1 from information_schema.tables
      where table_schema = 'public' and table_name = 'legacy_reviews'
    ) then
      alter table public.reviews rename to legacy_reviews;
    end if;
  end if;

  if exists (
    select 1 from information_schema.tables
    where table_schema = 'public' and table_name = 'invoices'
  ) and not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'invoices' and column_name = 'order_id'
  ) then
    if not exists (
      select 1 from information_schema.tables
      where table_schema = 'public' and table_name = 'legacy_invoices'
    ) then
      alter table public.invoices rename to legacy_invoices;
    end if;
  end if;

  if exists (
    select 1
    from information_schema.tables
    where table_schema = 'public'
      and table_name = 'profiles'
  ) then
    alter table public.profiles add column if not exists email text not null default '';
    alter table public.profiles add column if not exists profile_image_url text;
    alter table public.profiles add column if not exists is_active boolean not null default true;
    if exists (
      select 1
      from information_schema.columns
      where table_schema = 'public'
        and table_name = 'profiles'
        and column_name = 'role'
        and udt_name <> 'app_role'
    ) then
      alter table public.profiles
        alter column role drop default;
      alter table public.profiles
        alter column role type public.app_role
        using role::text::public.app_role;
      alter table public.profiles
        alter column role set default 'customer'::public.app_role;
    end if;
    if exists (
      select 1
      from information_schema.columns
      where table_schema = 'public'
        and table_name = 'profiles'
        and column_name = 'avatar_url'
    ) then
      update public.profiles
      set profile_image_url = coalesce(profile_image_url, avatar_url)
      where profile_image_url is null;
    end if;
  end if;
end $$;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  full_name text not null,
  phone text,
  role public.app_role not null default 'customer',
  profile_image_url text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_email_not_empty check (length(trim(email)) > 0),
  constraint profiles_full_name_not_empty check (length(trim(full_name)) > 0)
);

create table if not exists public.technician_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.profiles(id) on delete cascade,
  address text not null,
  experience text,
  skills text[] not null default '{}',
  service_area text not null default 'Solo',
  description text,
  verification_status public.verification_status not null default 'pending',
  rejection_reason text,
  verified_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.technician_documents (
  id uuid primary key default gen_random_uuid(),
  technician_id uuid not null references public.technician_profiles(id) on delete cascade,
  document_type text not null,
  file_url text not null,
  uploaded_at timestamptz not null default now(),
  constraint technician_documents_type_not_empty check (length(trim(document_type)) > 0)
);

create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  description text,
  icon_url text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

do $$
begin
  if exists (
    select 1
    from information_schema.tables
    where table_schema = 'public'
      and table_name = 'legacy_services'
  ) then
    insert into public.categories (name, description, icon_url, is_active, created_at, updated_at)
    select name, description, icon_url, is_active, created_at, updated_at
    from public.legacy_services
    on conflict (name) do nothing;
  end if;
end $$;

create table if not exists public.services (
  id uuid primary key default gen_random_uuid(),
  technician_id uuid not null references public.technician_profiles(id) on delete cascade,
  category_id uuid not null references public.categories(id) on delete restrict,
  name text not null,
  description text,
  estimated_price numeric(12,2) not null default 0,
  estimated_duration text,
  available_schedule text,
  approval_status public.service_approval_status not null default 'pending',
  rejection_reason text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint services_price_non_negative check (estimated_price >= 0),
  constraint services_name_not_empty check (length(trim(name)) > 0)
);

create table if not exists public.service_images (
  id uuid primary key default gen_random_uuid(),
  service_id uuid not null references public.services(id) on delete cascade,
  image_url text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.technician_schedules (
  id uuid primary key default gen_random_uuid(),
  technician_id uuid not null references public.technician_profiles(id) on delete cascade,
  day_of_week smallint not null,
  start_time time not null,
  end_time time not null,
  is_available boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint technician_schedules_day_range check (day_of_week between 0 and 6),
  constraint technician_schedules_valid_time check (start_time < end_time)
);

create table if not exists public.customer_addresses (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.profiles(id) on delete cascade,
  label text not null,
  recipient_name text not null,
  phone text not null,
  full_address text not null,
  city text not null default 'Solo',
  district text,
  village text,
  postal_code text,
  latitude numeric(10,7),
  longitude numeric(10,7),
  is_primary boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  order_number text not null unique,
  customer_id uuid not null references public.profiles(id) on delete restrict,
  technician_id uuid not null references public.technician_profiles(id) on delete restrict,
  address_id uuid references public.customer_addresses(id) on delete set null,
  schedule_date date not null,
  schedule_time time not null,
  problem_description text not null,
  status public.order_status not null default 'waiting_confirmation',
  estimated_total numeric(12,2) not null default 0,
  final_total numeric(12,2) not null default 0,
  commission_percentage numeric(5,2) not null default 10.00,
  commission_amount numeric(12,2) not null default 0,
  technician_income numeric(12,2) not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint orders_estimated_total_non_negative check (estimated_total >= 0),
  constraint orders_final_total_non_negative check (final_total >= 0),
  constraint orders_commission_percentage_range check (commission_percentage between 0 and 100)
);

create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  service_id uuid references public.services(id) on delete set null,
  service_name text not null,
  estimated_price numeric(12,2) not null default 0,
  final_price numeric(12,2) not null default 0,
  created_at timestamptz not null default now(),
  constraint order_items_estimated_price_non_negative check (estimated_price >= 0),
  constraint order_items_final_price_non_negative check (final_price >= 0)
);

create table if not exists public.order_attachments (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  file_url text not null,
  caption text,
  created_at timestamptz not null default now()
);

create table if not exists public.diagnoses (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null unique references public.orders(id) on delete cascade,
  technician_id uuid not null references public.technician_profiles(id) on delete restrict,
  diagnosis_result text not null,
  work_estimation text,
  service_cost numeric(12,2) not null default 0,
  sparepart_cost numeric(12,2) not null default 0,
  total_cost numeric(12,2) generated always as (service_cost + sparepart_cost) stored,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint diagnoses_service_cost_non_negative check (service_cost >= 0),
  constraint diagnoses_sparepart_cost_non_negative check (sparepart_cost >= 0)
);

create table if not exists public.spareparts (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  description text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.order_spareparts (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  sparepart_id uuid references public.spareparts(id) on delete set null,
  sparepart_name text not null,
  quantity integer not null default 1,
  unit_price numeric(12,2) not null default 0,
  total_price numeric(12,2) generated always as (quantity * unit_price) stored,
  created_at timestamptz not null default now(),
  constraint order_spareparts_quantity_positive check (quantity > 0),
  constraint order_spareparts_unit_price_non_negative check (unit_price >= 0)
);

create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null unique references public.orders(id) on delete cascade,
  payment_method public.payment_method not null,
  amount numeric(12,2) not null default 0,
  proof_url text,
  payment_status public.payment_status not null default 'unpaid',
  paid_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint payments_amount_non_negative check (amount >= 0)
);

create table if not exists public.reviews (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null unique references public.orders(id) on delete cascade,
  customer_id uuid not null references public.profiles(id) on delete cascade,
  technician_id uuid not null references public.technician_profiles(id) on delete cascade,
  rating smallint not null,
  comment text,
  image_url text,
  created_at timestamptz not null default now(),
  constraint reviews_rating_range check (rating between 1 and 5)
);

create table if not exists public.warranties (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null unique references public.orders(id) on delete cascade,
  warranty_number text not null unique,
  start_date date not null,
  end_date date not null,
  status public.warranty_status not null default 'active',
  created_at timestamptz not null default now(),
  constraint warranties_valid_period check (start_date <= end_date)
);

create table if not exists public.invoices (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null unique references public.orders(id) on delete cascade,
  invoice_number text not null unique,
  payment_id uuid references public.payments(id) on delete set null,
  invoice_date date not null default current_date,
  total_amount numeric(12,2) not null default 0,
  created_at timestamptz not null default now(),
  constraint invoices_total_amount_non_negative check (total_amount >= 0)
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  type public.notification_type not null,
  title text not null,
  message text not null,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.app_settings (
  key text primary key,
  value jsonb not null,
  description text,
  updated_at timestamptz not null default now()
);

create index if not exists technician_profiles_user_id_idx on public.technician_profiles(user_id);
create index if not exists technician_profiles_status_idx on public.technician_profiles(verification_status);
create index if not exists services_technician_id_idx on public.services(technician_id);
create index if not exists services_category_id_idx on public.services(category_id);
create index if not exists services_approval_active_idx on public.services(approval_status, is_active);
create index if not exists customer_addresses_customer_id_idx on public.customer_addresses(customer_id);
create index if not exists orders_customer_id_idx on public.orders(customer_id);
create index if not exists orders_technician_id_idx on public.orders(technician_id);
create index if not exists orders_status_idx on public.orders(status);
create index if not exists notifications_user_read_idx on public.notifications(user_id, is_read);

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at before update on public.profiles for each row execute function public.set_updated_at();
drop trigger if exists technician_profiles_set_updated_at on public.technician_profiles;
create trigger technician_profiles_set_updated_at before update on public.technician_profiles for each row execute function public.set_updated_at();
drop trigger if exists categories_set_updated_at on public.categories;
create trigger categories_set_updated_at before update on public.categories for each row execute function public.set_updated_at();
drop trigger if exists services_set_updated_at on public.services;
create trigger services_set_updated_at before update on public.services for each row execute function public.set_updated_at();
drop trigger if exists technician_schedules_set_updated_at on public.technician_schedules;
create trigger technician_schedules_set_updated_at before update on public.technician_schedules for each row execute function public.set_updated_at();
drop trigger if exists customer_addresses_set_updated_at on public.customer_addresses;
create trigger customer_addresses_set_updated_at before update on public.customer_addresses for each row execute function public.set_updated_at();
drop trigger if exists orders_set_updated_at on public.orders;
create trigger orders_set_updated_at before update on public.orders for each row execute function public.set_updated_at();
drop trigger if exists diagnoses_set_updated_at on public.diagnoses;
create trigger diagnoses_set_updated_at before update on public.diagnoses for each row execute function public.set_updated_at();
drop trigger if exists spareparts_set_updated_at on public.spareparts;
create trigger spareparts_set_updated_at before update on public.spareparts for each row execute function public.set_updated_at();
drop trigger if exists payments_set_updated_at on public.payments;
create trigger payments_set_updated_at before update on public.payments for each row execute function public.set_updated_at();
drop trigger if exists app_settings_set_updated_at on public.app_settings;
create trigger app_settings_set_updated_at before update on public.app_settings for each row execute function public.set_updated_at();

drop function if exists public.current_user_role() cascade;
drop function if exists public.is_admin() cascade;
drop function if exists public.current_technician_profile_id() cascade;

create or replace function public.current_user_role()
returns public.app_role
language sql
security definer
set search_path = public
stable
as $$
  select role from public.profiles where id = auth.uid()
$$;

create or replace function public.is_admin()
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select coalesce(public.current_user_role() = 'admin', false)
$$;

create or replace function public.current_technician_profile_id()
returns uuid
language sql
security definer
set search_path = public
stable
as $$
  select id from public.technician_profiles where user_id = auth.uid()
$$;

create or replace function public.generate_order_number()
returns text
language sql
as $$
  select 'ST-' || to_char(now(), 'YYYYMMDD') || '-' || upper(substr(gen_random_uuid()::text, 1, 8))
$$;

create or replace function public.generate_invoice_number()
returns text
language sql
as $$
  select 'INV-' || to_char(now(), 'YYYYMMDD') || '-' || upper(substr(gen_random_uuid()::text, 1, 8))
$$;

create or replace function public.generate_warranty_number()
returns text
language sql
as $$
  select 'GAR-' || to_char(now(), 'YYYYMMDD') || '-' || upper(substr(gen_random_uuid()::text, 1, 8))
$$;

create or replace function public.apply_order_totals()
returns trigger
language plpgsql
as $$
begin
  new.commission_amount = round(coalesce(new.final_total, 0) * coalesce(new.commission_percentage, 0) / 100, 2);
  new.technician_income = coalesce(new.final_total, 0) - new.commission_amount;
  return new;
end;
$$;

drop trigger if exists orders_apply_totals on public.orders;
create trigger orders_apply_totals
before insert or update of final_total, commission_percentage on public.orders
for each row execute function public.apply_order_totals();

create or replace function public.create_profile_for_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  requested_role public.app_role;
begin
  requested_role = coalesce((new.raw_user_meta_data ->> 'role')::public.app_role, 'customer');

  if requested_role = 'admin' then
    requested_role = 'customer';
  end if;

  insert into public.profiles (id, email, full_name, phone, role)
  values (
    new.id,
    coalesce(new.email, ''),
    coalesce(new.raw_user_meta_data ->> 'full_name', split_part(coalesce(new.email, ''), '@', 1)),
    new.raw_user_meta_data ->> 'phone',
    requested_role
  );

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.create_profile_for_new_user();

alter table public.profiles enable row level security;
alter table public.technician_profiles enable row level security;
alter table public.technician_documents enable row level security;
alter table public.categories enable row level security;
alter table public.services enable row level security;
alter table public.service_images enable row level security;
alter table public.technician_schedules enable row level security;
alter table public.customer_addresses enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.order_attachments enable row level security;
alter table public.diagnoses enable row level security;
alter table public.spareparts enable row level security;
alter table public.order_spareparts enable row level security;
alter table public.payments enable row level security;
alter table public.reviews enable row level security;
alter table public.warranties enable row level security;
alter table public.invoices enable row level security;
alter table public.notifications enable row level security;
alter table public.app_settings enable row level security;

create policy "Profiles readable by authenticated users" on public.profiles for select to authenticated using (true);
create policy "Users update own profile" on public.profiles for update to authenticated using (id = auth.uid() or public.is_admin()) with check (id = auth.uid() or public.is_admin());
create policy "Admins manage profiles" on public.profiles for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy "Verified technician profiles are public" on public.technician_profiles for select to anon, authenticated using (verification_status = 'verified' or user_id = auth.uid() or public.is_admin());
create policy "Technicians create own profile" on public.technician_profiles for insert to authenticated with check (user_id = auth.uid() and public.current_user_role() = 'technician');
create policy "Technicians and admins update technician profiles" on public.technician_profiles for update to authenticated using (user_id = auth.uid() or public.is_admin()) with check (user_id = auth.uid() or public.is_admin());

create policy "Technician documents visible to owner and admin" on public.technician_documents for select to authenticated using (public.is_admin() or exists (select 1 from public.technician_profiles tp where tp.id = technician_documents.technician_id and tp.user_id = auth.uid()));
create policy "Technicians manage own documents" on public.technician_documents for all to authenticated using (public.is_admin() or exists (select 1 from public.technician_profiles tp where tp.id = technician_documents.technician_id and tp.user_id = auth.uid())) with check (public.is_admin() or exists (select 1 from public.technician_profiles tp where tp.id = technician_documents.technician_id and tp.user_id = auth.uid()));

create policy "Active categories are public" on public.categories for select to anon, authenticated using (is_active = true or public.is_admin());
create policy "Admins manage categories" on public.categories for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy "Approved active services are public" on public.services for select to anon, authenticated using ((approval_status = 'approved' and is_active = true and exists (select 1 from public.technician_profiles tp where tp.id = services.technician_id and tp.verification_status = 'verified')) or technician_id = public.current_technician_profile_id() or public.is_admin());
create policy "Verified technicians create own services" on public.services for insert to authenticated with check (technician_id = public.current_technician_profile_id() and exists (select 1 from public.technician_profiles tp where tp.id = services.technician_id and tp.verification_status = 'verified'));
create policy "Technicians and admins update services" on public.services for update to authenticated using (technician_id = public.current_technician_profile_id() or public.is_admin()) with check (technician_id = public.current_technician_profile_id() or public.is_admin());

create policy "Service images follow service access" on public.service_images for select to anon, authenticated using (exists (select 1 from public.services s where s.id = service_images.service_id));
create policy "Technicians manage own service images" on public.service_images for all to authenticated using (public.is_admin() or exists (select 1 from public.services s where s.id = service_images.service_id and s.technician_id = public.current_technician_profile_id())) with check (public.is_admin() or exists (select 1 from public.services s where s.id = service_images.service_id and s.technician_id = public.current_technician_profile_id()));

create policy "Schedules are readable" on public.technician_schedules for select to anon, authenticated using (is_available = true or technician_id = public.current_technician_profile_id() or public.is_admin());
create policy "Technicians manage own schedules" on public.technician_schedules for all to authenticated using (technician_id = public.current_technician_profile_id() or public.is_admin()) with check (technician_id = public.current_technician_profile_id() or public.is_admin());

create policy "Customers manage own addresses" on public.customer_addresses for all to authenticated using (customer_id = auth.uid() or public.is_admin()) with check (customer_id = auth.uid() or public.is_admin());

create policy "Order parties and admins read orders" on public.orders for select to authenticated using (customer_id = auth.uid() or technician_id = public.current_technician_profile_id() or public.is_admin());
create policy "Customers create own orders" on public.orders for insert to authenticated with check (customer_id = auth.uid() and public.current_user_role() = 'customer' and exists (select 1 from public.technician_profiles tp where tp.id = orders.technician_id and tp.verification_status = 'verified'));
create policy "Technicians and admins update orders" on public.orders for update to authenticated using (technician_id = public.current_technician_profile_id() or public.is_admin()) with check (technician_id = public.current_technician_profile_id() or public.is_admin());

create policy "Order items follow order access" on public.order_items for select to authenticated using (exists (select 1 from public.orders o where o.id = order_items.order_id and (o.customer_id = auth.uid() or o.technician_id = public.current_technician_profile_id() or public.is_admin())));
create policy "Customers create order items for own orders" on public.order_items for insert to authenticated with check (exists (select 1 from public.orders o where o.id = order_items.order_id and o.customer_id = auth.uid()));

create policy "Order attachments follow order access" on public.order_attachments for all to authenticated using (exists (select 1 from public.orders o where o.id = order_attachments.order_id and (o.customer_id = auth.uid() or o.technician_id = public.current_technician_profile_id() or public.is_admin()))) with check (exists (select 1 from public.orders o where o.id = order_attachments.order_id and (o.customer_id = auth.uid() or o.technician_id = public.current_technician_profile_id() or public.is_admin())));

create policy "Diagnoses visible to order parties" on public.diagnoses for select to authenticated using (exists (select 1 from public.orders o where o.id = diagnoses.order_id and (o.customer_id = auth.uid() or o.technician_id = public.current_technician_profile_id() or public.is_admin())));
create policy "Technicians manage diagnoses for own orders" on public.diagnoses for all to authenticated using (technician_id = public.current_technician_profile_id() or public.is_admin()) with check (technician_id = public.current_technician_profile_id() or public.is_admin());

create policy "Spareparts readable by authenticated users" on public.spareparts for select to authenticated using (true);
create policy "Technicians and admins manage spareparts" on public.spareparts for all to authenticated using (public.current_user_role() = 'technician' or public.is_admin()) with check (public.current_user_role() = 'technician' or public.is_admin());

create policy "Order spareparts follow order access" on public.order_spareparts for all to authenticated using (exists (select 1 from public.orders o where o.id = order_spareparts.order_id and (o.technician_id = public.current_technician_profile_id() or o.customer_id = auth.uid() or public.is_admin()))) with check (exists (select 1 from public.orders o where o.id = order_spareparts.order_id and (o.technician_id = public.current_technician_profile_id() or public.is_admin())));

create policy "Payments visible to order parties" on public.payments for select to authenticated using (exists (select 1 from public.orders o where o.id = payments.order_id and (o.customer_id = auth.uid() or o.technician_id = public.current_technician_profile_id() or public.is_admin())));
create policy "Order parties manage payments" on public.payments for all to authenticated using (public.is_admin() or exists (select 1 from public.orders o where o.id = payments.order_id and (o.customer_id = auth.uid() or o.technician_id = public.current_technician_profile_id()))) with check (public.is_admin() or exists (select 1 from public.orders o where o.id = payments.order_id and (o.customer_id = auth.uid() or o.technician_id = public.current_technician_profile_id())));

create policy "Reviews are public" on public.reviews for select to anon, authenticated using (true);
create policy "Customers create reviews for own completed orders" on public.reviews for insert to authenticated with check (customer_id = auth.uid() and exists (select 1 from public.orders o where o.id = reviews.order_id and o.customer_id = auth.uid() and o.status = 'completed'));
create policy "Admins manage reviews" on public.reviews for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy "Warranties visible to order parties" on public.warranties for select to authenticated using (exists (select 1 from public.orders o where o.id = warranties.order_id and (o.customer_id = auth.uid() or o.technician_id = public.current_technician_profile_id() or public.is_admin())));
create policy "Admins manage warranties" on public.warranties for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy "Invoices visible to order parties" on public.invoices for select to authenticated using (exists (select 1 from public.orders o where o.id = invoices.order_id and (o.customer_id = auth.uid() or o.technician_id = public.current_technician_profile_id() or public.is_admin())));
create policy "Admins manage invoices" on public.invoices for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy "Users read own notifications" on public.notifications for select to authenticated using (user_id = auth.uid() or public.is_admin());
create policy "Users update own notifications" on public.notifications for update to authenticated using (user_id = auth.uid() or public.is_admin()) with check (user_id = auth.uid() or public.is_admin());
create policy "Admins create notifications" on public.notifications for insert to authenticated with check (public.is_admin());

create policy "Settings readable by authenticated users" on public.app_settings for select to authenticated using (true);
create policy "Admins manage settings" on public.app_settings for all to authenticated using (public.is_admin()) with check (public.is_admin());

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('profile-images', 'profile-images', true, 2097152, array['image/jpeg', 'image/png', 'image/webp']),
  ('technician-documents', 'technician-documents', false, 5242880, array['image/jpeg', 'image/png', 'application/pdf']),
  ('service-images', 'service-images', true, 3145728, array['image/jpeg', 'image/png', 'image/webp']),
  ('order-attachments', 'order-attachments', false, 5242880, array['image/jpeg', 'image/png', 'image/webp', 'application/pdf']),
  ('payment-proofs', 'payment-proofs', false, 5242880, array['image/jpeg', 'image/png', 'image/webp', 'application/pdf'])
on conflict (id) do nothing;

create policy "Public can read public images" on storage.objects for select to anon, authenticated using (bucket_id in ('profile-images', 'service-images'));
create policy "Authenticated users upload profile images" on storage.objects for insert to authenticated with check (bucket_id = 'profile-images');
create policy "Authenticated users upload service images" on storage.objects for insert to authenticated with check (bucket_id = 'service-images');
create policy "Authenticated users read private files" on storage.objects for select to authenticated using (bucket_id in ('technician-documents', 'order-attachments', 'payment-proofs') or public.is_admin());
create policy "Authenticated users upload private files" on storage.objects for insert to authenticated with check (bucket_id in ('technician-documents', 'order-attachments', 'payment-proofs'));

insert into public.app_settings (key, value, description)
values
  ('commission_percentage', '10', 'Default application commission percentage'),
  ('service_city', '"Solo"', 'Initial service area'),
  ('warranty_days', '7', 'Default warranty duration after order completion')
on conflict (key) do update
set value = excluded.value,
    description = excluded.description,
    updated_at = now();
