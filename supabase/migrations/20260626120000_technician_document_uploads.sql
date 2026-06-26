create table if not exists public.technician_documents (
  id uuid primary key default gen_random_uuid(),
  technician_id uuid not null references public.technician_profiles(id) on delete cascade,
  document_type text not null,
  file_url text not null,
  uploaded_at timestamptz not null default now(),
  constraint technician_documents_type_not_empty check (length(trim(document_type)) > 0)
);

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'technician_documents_type_allowed'
  ) then
    alter table public.technician_documents
      add constraint technician_documents_type_allowed
      check (document_type in ('ktp', 'selfie', 'certificate', 'experience'));
  end if;
end $$;

create unique index if not exists technician_documents_unique_type_idx
  on public.technician_documents (technician_id, document_type);

alter table public.technician_documents enable row level security;

drop policy if exists "Technician documents visible to owner and admin" on public.technician_documents;
drop policy if exists "Technicians manage own documents" on public.technician_documents;

create policy "Technician documents visible to owner and admin"
on public.technician_documents for select to authenticated
using (
  public.is_admin()
  or exists (
    select 1
    from public.technician_profiles tp
    where tp.id = technician_documents.technician_id
      and tp.user_id = auth.uid()
  )
);

create policy "Technicians manage own documents"
on public.technician_documents for all to authenticated
using (
  public.is_admin()
  or exists (
    select 1
    from public.technician_profiles tp
    where tp.id = technician_documents.technician_id
      and tp.user_id = auth.uid()
  )
)
with check (
  public.is_admin()
  or exists (
    select 1
    from public.technician_profiles tp
    where tp.id = technician_documents.technician_id
      and tp.user_id = auth.uid()
  )
);

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('technician-documents', 'technician-documents', false, 5242880, array['image/jpeg', 'image/png', 'application/pdf'])
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Authenticated users read private files" on storage.objects;
drop policy if exists "Authenticated users upload private files" on storage.objects;
drop policy if exists "Authenticated users read order and payment files" on storage.objects;
drop policy if exists "Authenticated users upload order and payment files" on storage.objects;
drop policy if exists "Technicians read own document files" on storage.objects;
drop policy if exists "Technicians upload own document files" on storage.objects;
drop policy if exists "Technicians update own document files" on storage.objects;
drop policy if exists "Technicians delete own document files" on storage.objects;

create policy "Authenticated users read order and payment files"
on storage.objects for select to authenticated
using (
  bucket_id in ('order-attachments', 'payment-proofs')
  or public.is_admin()
);

create policy "Authenticated users upload order and payment files"
on storage.objects for insert to authenticated
with check (
  bucket_id in ('order-attachments', 'payment-proofs')
);

create policy "Technicians read own document files"
on storage.objects for select to authenticated
using (
  bucket_id = 'technician-documents'
  and (
    public.is_admin()
    or (storage.foldername(name))[1] = auth.uid()::text
  )
);

create policy "Technicians upload own document files"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'technician-documents'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "Technicians update own document files"
on storage.objects for update to authenticated
using (
  bucket_id = 'technician-documents'
  and (
    public.is_admin()
    or (storage.foldername(name))[1] = auth.uid()::text
  )
)
with check (
  bucket_id = 'technician-documents'
  and (
    public.is_admin()
    or (storage.foldername(name))[1] = auth.uid()::text
  )
);

create policy "Technicians delete own document files"
on storage.objects for delete to authenticated
using (
  bucket_id = 'technician-documents'
  and (
    public.is_admin()
    or (storage.foldername(name))[1] = auth.uid()::text
  )
);
