create or replace function public._notify_user(
  p_user_id uuid,
  p_type public.notification_type,
  p_title text,
  p_message text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_user_id is null then
    return;
  end if;

  insert into public.notifications (user_id, type, title, message)
  values (p_user_id, p_type, p_title, p_message);
end;
$$;

create or replace function public.notify_order_status_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  technician_user_id uuid;
begin
  select user_id
  into technician_user_id
  from public.technician_profiles
  where id = new.technician_id;

  if tg_op = 'INSERT' then
    perform public._notify_user(
      technician_user_id,
      'new_order',
      'Order baru masuk',
      'Order ' || new.order_number || ' menunggu konfirmasi Anda.'
    );
    return new;
  end if;

  if old.status is not distinct from new.status then
    return new;
  end if;

  if new.status = 'accepted' then
    perform public._notify_user(
      new.customer_id,
      'order_accepted',
      'Order diterima',
      'Teknisi menerima order ' || new.order_number || '.'
    );
  elsif new.status = 'rejected' then
    perform public._notify_user(
      new.customer_id,
      'order_rejected',
      'Order ditolak',
      'Teknisi menolak order ' || new.order_number || '.'
    );
  elsif new.status = 'waiting_price_approval' then
    perform public._notify_user(
      new.customer_id,
      'price_approval_requested',
      'Estimasi biaya siap',
      'Teknisi mengirim estimasi final untuk order ' || new.order_number || '.'
    );
  elsif new.status = 'in_progress' then
    perform public._notify_user(
      new.customer_id,
      'price_approved',
      'Pekerjaan dimulai',
      'Order ' || new.order_number || ' sedang dikerjakan.'
    );
  elsif new.status = 'waiting_payment' then
    perform public._notify_user(
      new.customer_id,
      'work_completed',
      'Pekerjaan selesai',
      'Order ' || new.order_number || ' selesai dikerjakan dan menunggu pembayaran.'
    );
  elsif new.status = 'completed' then
    perform public._notify_user(
      new.customer_id,
      'payment_paid',
      'Pembayaran berhasil',
      'Order ' || new.order_number || ' sudah lunas dan dokumen layanan tersedia.'
    );
  end if;

  return new;
end;
$$;

drop trigger if exists orders_notify_status_change on public.orders;
create trigger orders_notify_status_change
after insert or update of status on public.orders
for each row execute function public.notify_order_status_change();

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
begin
  current_technician := public.current_technician_profile_id();

  if current_technician is null then
    raise exception 'Profil teknisi tidak ditemukan';
  end if;

  if not exists (
    select 1
    from public.orders
    where id = p_order_id
      and technician_id = current_technician
      and status in ('inspection', 'waiting_price_approval', 'in_progress')
  ) then
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
    final_total = greatest(coalesce(p_service_cost, 0), 0) + sparepart_total,
    status = 'waiting_price_approval'
  where id = p_order_id;
end;
$$;

create or replace function public.customer_decide_order_price(
  p_order_id uuid,
  p_approved boolean
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  order_row public.orders%rowtype;
  technician_user_id uuid;
begin
  select *
  into order_row
  from public.orders
  where id = p_order_id
    and customer_id = auth.uid()
    and status = 'waiting_price_approval';

  if not found then
    raise exception 'Order tidak tersedia untuk persetujuan biaya';
  end if;

  update public.orders
  set status = case when p_approved then 'in_progress'::public.order_status else 'price_rejected'::public.order_status end
  where id = p_order_id;

  select user_id
  into technician_user_id
  from public.technician_profiles
  where id = order_row.technician_id;

  perform public._notify_user(
    technician_user_id,
    case when p_approved then 'price_approved'::public.notification_type else 'order_rejected'::public.notification_type end,
    case when p_approved then 'Biaya disetujui' else 'Biaya ditolak' end,
    'Customer sudah merespons estimasi biaya order ' || order_row.order_number || '.'
  );
end;
$$;

create or replace function public.complete_order_with_documents(
  p_order_id uuid,
  p_payment_id uuid default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  order_row public.orders%rowtype;
  warranty_days integer := 7;
  jwt_role text := current_setting('request.jwt.claim.role', true);
begin
  select *
  into order_row
  from public.orders
  where id = p_order_id;

  if not found then
    raise exception 'Order tidak ditemukan';
  end if;

  if jwt_role is distinct from 'service_role'
    and not public.is_admin()
    and order_row.technician_id is distinct from public.current_technician_profile_id()
  then
    raise exception 'Tidak memiliki akses menyelesaikan order';
  end if;

  select coalesce((value #>> '{}')::integer, 7)
  into warranty_days
  from public.app_settings
  where key = 'warranty_days';

  update public.orders
  set status = 'completed'
  where id = p_order_id;

  insert into public.invoices (
    order_id,
    invoice_number,
    payment_id,
    total_amount
  )
  values (
    p_order_id,
    public.generate_invoice_number(),
    p_payment_id,
    case when order_row.final_total > 0 then order_row.final_total else order_row.estimated_total end
  )
  on conflict (order_id) do nothing;

  insert into public.warranties (
    order_id,
    warranty_number,
    start_date,
    end_date,
    status
  )
  values (
    p_order_id,
    public.generate_warranty_number(),
    current_date,
    current_date + warranty_days,
    'active'
  )
  on conflict (order_id) do nothing;
end;
$$;
