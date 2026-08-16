# Advisor Activity Ledger

A standalone version of the advisor daily-activity dashboard — no Claude account needed to use it. Runs as a single static page (`index.html`), backed by a free Supabase database.

## Setup

1. **Create a free Supabase project** at [supabase.com](https://supabase.com).
2. In your new project, go to **SQL Editor → New query**, paste in the contents of `schema.sql`, and run it.
3. Go to **Project Settings → API**. Copy your **Project URL** and **anon public key**.
4. Open `index.html` and near the top, replace:
   ```js
   window.SUPABASE_URL = "YOUR_SUPABASE_URL";
   window.SUPABASE_ANON_KEY = "YOUR_SUPABASE_ANON_KEY";
   ```
   with your real values.
5. Push this folder to a GitHub repo, then in the repo go to **Settings → Pages**, set **Source** to your main branch (root), and save.
6. GitHub gives you a URL like `https://yourname.github.io/repo-name/` — that's the link to share with your team.

## How it works

- Each advisor picks their name and types their advisor code to log in — the same code doubles as their login, set when they first register.
- Every tap saves straight to Supabase, so any advisor's data is visible on the Team Board immediately, from any device.
- The **Manager** tab is protected by a separate PIN (set the first time someone opens it), and shows who hasn't logged anything today, per-advisor history, editable daily targets, and a CSV export.

## Known limitation

There are no real user accounts here — advisor identity is just an app-level check (the advisor code), not enforced by the database. Anyone with your Supabase anon key (visible in the page source) could call the Supabase API directly and bypass that check. This is fine for a low-stakes internal tool; if that's ever a concern, the next step up is real Supabase Auth.
