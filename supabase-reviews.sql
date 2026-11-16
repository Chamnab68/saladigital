create table if not exists public.reviews (
  id uuid primary key default gen_random_uuid(),
  book_id text not null,
  user_id uuid not null references auth.users (id) on delete cascade,
  user_name text not null,
  rating smallint not null check (rating between 1 and 5),
  comment text not null check (length(trim(comment)) > 0),
  created_at timestamptz not null default now()
);

create index if not exists reviews_book_id_created_at_idx
  on public.reviews (book_id, created_at desc);

alter table public.reviews enable row level security;

drop policy if exists "Reviews are readable by everyone" on public.reviews;
create policy "Reviews are readable by everyone"
  on public.reviews for select
  to anon, authenticated
  using (true);

drop policy if exists "Authenticated users can create their own reviews" on public.reviews;
create policy "Authenticated users can create their own reviews"
  on public.reviews for insert
  to authenticated
  with check (auth.uid() = user_id);

grant select on public.reviews to anon, authenticated;
grant insert on public.reviews to authenticated;
