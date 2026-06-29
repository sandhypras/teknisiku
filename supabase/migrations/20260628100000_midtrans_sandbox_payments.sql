alter table public.payments
  add column if not exists midtrans_order_id text,
  add column if not exists snap_token text,
  add column if not exists snap_redirect_url text,
  add column if not exists transaction_id text,
  add column if not exists fraud_status text,
  add column if not exists raw_response jsonb;

create unique index if not exists payments_midtrans_order_id_key
  on public.payments(midtrans_order_id)
  where midtrans_order_id is not null;

