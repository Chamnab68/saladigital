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

alter table public.review_reactions enable row level security;
alter table public.review_replies enable row level security;

drop policy if exists "Review reactions are readable by everyone" on public.review_reactions;
create policy "Review reactions are readable by everyone"
  on public.review_reactions for select
  to anon, authenticated
  using (true);

drop policy if exists "Users can create their own review reactions" on public.review_reactions;
create policy "Users can create their own review reactions"
  on public.review_reactions for insert
  to authenticated
  with check (
    auth.uid() = user_id
    and reaction_type in ('like', 'love', 'helpful')
  );

drop policy if exists "Users can update their own review reactions" on public.review_reactions;
create policy "Users can update their own review reactions"
  on public.review_reactions for update
  to authenticated
  using (auth.uid() = user_id)
  with check (
    auth.uid() = user_id
    and reaction_type in ('like', 'love', 'helpful')
  );

drop policy if exists "Users can delete their own review reactions" on public.review_reactions;
create policy "Users can delete their own review reactions"
  on public.review_reactions for delete
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "Review replies are readable by everyone" on public.review_replies;
create policy "Review replies are readable by everyone"
  on public.review_replies for select
  to anon, authenticated
  using (true);

drop policy if exists "Users can create their own review replies" on public.review_replies;
create policy "Users can create their own review replies"
  on public.review_replies for insert
  to authenticated
  with check (
    auth.uid() = user_id
    and length(trim(reply_text)) > 0
  );

grant select on public.review_reactions, public.review_replies to anon, authenticated;
grant insert, update, delete on public.review_reactions to authenticated;
grant insert on public.review_replies to authenticated;
