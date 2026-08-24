# Web App — browser version

A self-contained, single-file web version of the app, built so you and
Sarthak can use it from Chrome/Safari today, without waiting on the Xcode
build or an Apple Developer account.

## Use it right now

**Live link (already deployed):**
https://claude.ai/code/artifact/d02a5342-a220-4985-b011-bf7f978ff5a1

Open that on your iPhone in Chrome or Safari. To make it feel like an app:
**Share → Add to Home Screen.** Send the same link to Sarthak so he can do
the same on his phone.

This link is private to your account until you share it — use the page's
share menu if you want to hand it to someone directly instead of just
sending the URL.

## What it is, technically

- One HTML file (`docs/index.html` in this repo) — no build step, no
  framework, no dependencies. Same visual language as the native app
  (calm, amount-forward, restrained color), same 50/50 balance formula,
  same JSON schema for export/import as the native iOS app — a file
  exported from one is importable into the other.
- Data is stored in the browser's local storage. Nothing leaves your
  phone. There is no server and no account, matching how you answered
  "no backend, local only" when this was set up.

## The one real limitation: no live sync between two browsers

Because there's no shared backend, **your data and Sarthak's data don't
merge automatically.** Each of you sees only what you've entered on your
own phone. This is a deliberate trade-off for zero setup and zero cost —
if you want them to actually merge automatically, that requires standing
up a small shared database (a follow-up, not what's built today).

**In the meantime, keep in sync manually** — this is quick:
1. On your phone: **Settings → Export Expenses** → this uses your
   phone's native "Save/Share" sheet (AirDrop it to Sarthak, or send via
   WhatsApp/Files/Mail — whatever's easiest).
2. Sarthak opens the file and imports it: **Settings → Import Expenses**
   → pick the file you sent.
3. Import is safe to repeat any time — it merges by matching each
   expense's ID and keeping whichever copy was edited most recently, so
   re-importing the same file twice never creates duplicates, and an
   older file can never overwrite a newer edit.

Do this every so often (e.g. after a trip, or every few days) and both of
your copies stay reasonably close to in sync, the same way the export/
import feature works on the native iOS app.

## Budget

**Settings → Set a Budget** (or the card right at the top of Home) lets
you set an amount and a specific date range — e.g. "₹10,000, this month"
or "₹5,000, June 1–15 for a trip." That top-of-Home card *is* the
headline number: with a budget set it shows what's left (or how far
over), with "of ₹Y budget" as a small caption and a progress bar; with no
budget set it falls back to showing total spent instead — either way, the
big "Add Expense" button stays right below it. There's one active budget
at a time; editing it replaces the current one, and "Remove Budget"
clears it. It counts every active expense (including Company) whose date
falls in that range.

## Company account

There's a third "paid by" option alongside Het and Sarthak: **Company** —
for business expenses paid directly by the company, not personally by
either of you. Pick it and an **Authorized By** field appears (Het or
Sarthak), since a company expense always needs someone accountable for
it. Company spend is tracked and shown (Home, Balance, filters) but is
**never split 50/50** — it's excluded from "who paid more"/fair share
entirely, since neither of you personally fronted that money.

Defaults for a new expense are **Company / Cash** (the common case) —
both are one tap away from Het/Sarthak/Online before you save.

## Discreet category label (CSC)

What used to be separate "Alcohol" and "Tobacco" categories are now one
merged category labeled **CSC**, with a neutral box icon — nothing in the
category list spells out what was actually bought. If you already had
expenses categorized the old way, they were relabeled to CSC
automatically the next time you opened the app.

## Loading your real Jaipur + SCS data

The app now **pre-loads** the same 70 verified transactions described in
`SampleData/SEED_DATA.md` automatically the first time it's opened in a
new browser (Sarthak's phone, a private tab, etc.) — no tap needed. You
can also load it manually any time via **Settings → Load Sample Data
(Jaipur + SCS)**, which is safe to tap more than once (never duplicates).
Same caveat applies: since this app has one flat ledger (no per-trip
grouping), the Balance tab shows the *combined* number (Het owes Sarthak
₹9,076), not the two separate trip settlements from your source
accounting document.

## Hosting it yourself elsewhere (optional)

The live link above already works and needs nothing from you. If you'd
rather have your own URL (e.g. a `github.io` address), `docs/index.html`
is ready for GitHub Pages:

1. On GitHub: this repo → **Settings → Pages**.
2. Source: **Deploy from a branch**. Branch: `claude/personal-expense-app-w8nhm3`
   (or `main`, once this is merged). Folder: **/docs**. Save.
3. Wait about a minute, then open the URL GitHub shows you.

Why not Streamlit, which you mentioned you've used before: Streamlit runs
your app on a server that all visitors share, which doesn't fit "each
phone keeps its own local data" — a plain static page (what's built here)
is the correct fit for that model, and it's equally free.

## If you outgrow "local only" later

If manually exporting/importing becomes annoying and you want your
expenses to actually sync live between your two phones' browsers, the
next step would be a small shared database (e.g. a free-tier Supabase or
Firebase project). That's a deliberate architecture change from what's
built today — say the word and it can be added.
