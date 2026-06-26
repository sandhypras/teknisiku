do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'technician_documents_unique_type'
      and conrelid = 'public.technician_documents'::regclass
  ) then
    if exists (
      select 1
      from pg_indexes
      where schemaname = 'public'
        and tablename = 'technician_documents'
        and indexname = 'technician_documents_unique_type_idx'
    ) then
      alter table public.technician_documents
        add constraint technician_documents_unique_type
        unique using index technician_documents_unique_type_idx;
    else
      alter table public.technician_documents
        add constraint technician_documents_unique_type
        unique (technician_id, document_type);
    end if;
  end if;
end $$;
