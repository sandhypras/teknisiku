create extension if not exists pg_net with schema extensions;

create table if not exists public.user_device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  fcm_token text not null unique,
  platform text not null default 'android',
  device_info jsonb not null default '{}'::jsonb,
  is_active boolean not null default true,
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint user_device_tokens_token_not_empty check (length(trim(fcm_token)) > 0)
);

create index if not exists user_device_tokens_user_id_idx
  on public.user_device_tokens(user_id);
create index if not exists user_device_tokens_active_idx
  on public.user_device_tokens(user_id, is_active);

drop trigger if exists user_device_tokens_set_updated_at on public.user_device_tokens;
create trigger user_device_tokens_set_updated_at
before update on public.user_device_tokens
for each row execute function public.set_updated_at();

alter table public.user_device_tokens enable row level security;

drop policy if exists "Users manage own device tokens" on public.user_device_tokens;
create policy "Users manage own device tokens"
on public.user_device_tokens
for all to authenticated
using (user_id = auth.uid() or public.is_admin())
with check (user_id = auth.uid() or public.is_admin());

create or replace function public.notify_push_on_notification_insert()
returns trigger
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  function_url text;
  function_secret text;
begin
  select value #>> '{}'
  into function_url
  from public.app_settings
  where key = 'push_function_url';

  select value #>> '{}'
  into function_secret
  from public.app_settings
  where key = 'push_function_secret';

  if function_url is null
    or trim(function_url) = ''
    or function_secret is null
    or trim(function_secret) = ''
  then
    return new;
  end if;

  perform net.http_post(
    url := function_url,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-push-secret', function_secret
    ),
    body := jsonb_build_object('notification_id', new.id),
    timeout_milliseconds := 5000
  );

  return new;
exception
  when others then
    return new;
end;
$$;

drop trigger if exists notifications_send_push on public.notifications;
create trigger notifications_send_push
after insert on public.notifications
for each row execute function public.notify_push_on_notification_insert();
