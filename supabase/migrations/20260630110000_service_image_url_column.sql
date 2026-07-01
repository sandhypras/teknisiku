alter table public.services
  add column if not exists image_url text;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'service-images',
  'service-images',
  true,
  3145728,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Public can read service images" on storage.objects;
create policy "Public can read service images"
on storage.objects for select
to anon, authenticated
using (bucket_id = 'service-images');

drop policy if exists "Technicians upload service images" on storage.objects;
create policy "Technicians upload service images"
on storage.objects for insert
to authenticated
with check (bucket_id = 'service-images');
