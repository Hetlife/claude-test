# Seed data — Jaipur trip + SCS expenses

`expenses_seed.json` is a real backup file in the app's own export/import
format (`schemaVersion: 1`), built from the two files you shared:
`final_expense_accounting.txt` and `raw_expense_data_for_ai.txt`. It contains
all **70 transactions** (57 Jaipur + 13 SCS) and is meant to be loaded through
**Settings → Import Expenses** so you can test the real app with real
numbers, without hand-entering 70 rows.

## How to load it

1. Get `expenses_seed.json` onto the iPhone (AirDrop it to yourself, or add
   it to iCloud Drive/Files).
2. Open the app → **Settings → Import Expenses** → pick the file.
3. Import reuses the same safe merge as device sync (`SyncEngine.merge`), so
   it's safe to import more than once — it will never create duplicates or
   overwrite anything newer.

## What was verified

The 70 rows were parsed from the **"RAW TRANSACTION LIST WITH PARSED
PAYER"** section of `final_expense_accounting.txt` (the already
payer-resolved list), not the messier raw notes file. A generator script
summed the parsed data and asserted it matches the accounting document
exactly before writing the file:

- Jaipur: 57 transactions, ₹81,460 total — Het ₹35,339 / Sarthak (incl.
  unnamed) ₹46,121 ✓.
- SCS: 13 transactions, ₹16,570 total — Het ₹4,600 / Sarthak (incl.
  unnamed) ₹11,970 ✓.

"Unnamed" transactions (no payer stated in the source) were assigned to
Sarthak, per the source document's own stated rule, and are flagged in each
record's `notes` field so you can find them again in the app.

## Important caveat — this app doesn't separate trips (v1)

The source document keeps Jaipur and SCS as two **separate** 50/50 pools
with two separate settlements:
- Jaipur: Het owes Sarthak ₹5,391
- SCS: Het owes Sarthak ₹3,685

The app's v1 data model has **one flat ledger** — there's no trip/project
grouping (the product spec explicitly says not to add that until the basic
system is stable). So once all 70 rows are imported, the **Balance** tab
will show the *combined* 50/50 result across everything:

**Het owes Sarthak ₹9,076** (₹98,030 total, Het paid ₹39,939, Sarthak paid
₹58,091, fair share ₹49,015 each) — this matches the source document's own
"COMBINED POSITION — FOR REFERENCE ONLY" section exactly, but it is *not*
the same as the two separate trip settlements. If you need the Jaipur and
SCS numbers kept apart, only import one file's worth at a time (split
`expenses_seed.json` yourself, or ask for it to be split into two files),
or wait for a future version with trip/project grouping.

## Assumptions made (source data didn't specify these)

- **Payment method**: not present in either source file, so every seeded
  row defaults to **Cash**. Edit individual expenses in the app if you know
  better.
- **Category**: inferred from the description text with simple keyword
  matching (e.g. "taxi"/"cab" → Transport, "beer"/"whisky"/"bottle" →
  Alcohol, "water"/"zepto" → Groceries, "police" → Other). This is a
  best-effort guess, not authoritative — re-categorize anything that looks
  wrong.
- **Dates**: the source data has no per-transaction dates, only a
  transaction order. Jaipur rows were spread 15 minutes apart starting
  2026-06-12; SCS rows the same starting 2026-07-20. These are placeholders
  so the app's date grouping/sorting has something sensible to show — they
  are not the real dates the expenses occurred.
- The two blank SCS descriptions (rows 11–12 in the source) were given the
  placeholder description "SCS payment".

This file is your own private financial data and is not referenced by any
app source code — it's a plain JSON backup, exactly like a normal export
from **Settings → Export Expenses** would produce.
