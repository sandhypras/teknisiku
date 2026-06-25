# Supabase RLS Policy Notes

RLS policies are included inside `supabase/migrations/20260625163000_initial_backend.sql` so schema and access rules can be applied atomically.

## Role Model

- `customer`, `technician`, and `admin` are stored in `public.profiles.role`.
- Guest users are unauthenticated users and are not stored as a database role.
- Public read access is enabled for active categories, approved services, public technician profile data, service images, profile images, and reviews.

## Admin Accounts

The public registration trigger prevents users from self-registering as `admin`. Create admin accounts manually from Supabase Auth and update `public.profiles.role` to `admin` from the Supabase SQL editor or dashboard.

```sql
update public.profiles
set role = 'admin'
where email = 'admin@example.com';
```
