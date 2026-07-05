create or replace function public.email_exists(lookup_email text)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from public.profiles
    where lower(email) = lower(trim(lookup_email))
  )
$$;

grant execute on function public.email_exists(text) to anon, authenticated;
