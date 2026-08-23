# Device Sync Setup

The app syncs expenses **directly between the two iPhones** over your
local Wi-Fi network using Apple's MultipeerConnectivity framework. There is
no server, no internet involved, and no account of any kind. Sync only
happens while you trigger it — there is no background/automatic sync.

## What you need

- Both iPhones on the **same Wi-Fi network** (or close enough for
  peer-to-peer Wi-Fi/Bluetooth if MultipeerConnectivity falls back to
  that — normal same-network Wi-Fi is the reliable case).
- The app **open in the foreground on both phones** at the same time.
- Local Network permission granted on both phones (see below).

## First-time: Local Network permission

The first time you open **Settings → Device Sync** (or the app tries to
find nearby devices), iOS will show a system prompt:

> "ExpenseApp" would like to find and connect to devices on your local
> network.

**Tap Allow.** The app explains why before this happens:

> "We use your local network only to sync expenses directly between your
> two iPhones. No expense data is sent to the internet."

If you tap **Don't Allow** by mistake, sync will silently fail to find
devices. Fix it in **Settings app → ExpenseApp → Local Network → on**.

## Pairing the two phones (do this once)

1. On **both** phones: open the app → **Settings → Device Sync**.
2. On **both** phones: tap **Find Nearby Device**.
3. Within a few seconds, each phone should see the other listed under
   "Nearby Devices" (labeled with its device name, e.g. "Sarthak's
   iPhone" — see "Device name" in Settings → Personal to change this).
4. On **one** phone, tap the other device's name to invite it to connect.
5. On the **other** phone, a confirmation appears:
   > "Connect with Het's iPhone? This will let Het's iPhone exchange
   > expenses directly with this iPhone over your local Wi-Fi network."

   Tap **Connect**. (Tap **Decline** to refuse — nothing happens if you
   decline.)
6. Both phones now show **Connected to <name>**.

You only need to do the invite/confirm handshake once per session; if you
close and reopen the app you'll repeat "Find Nearby Device" → tap the
peer, but the app remembers nothing across launches — there's no saved
pairing, by design (this keeps the trust model simple: you always
explicitly confirm who you're syncing with).

## Syncing

1. With both phones connected (see above), tap **Sync Now** on either
   phone.
2. Both phones exchange their full expense list (including any deletions,
   as "tombstones" so they don't come back).
3. Each phone merges what it received: for any expense that exists on
   both phones, whichever version was edited most recently (by
   timestamp) wins — so an edit always beats a stale copy, and a delete
   always stays deleted once it's synced.
4. You'll see **"Records sent: N / Records received: M"** and the balance
   and transaction list update immediately.

You can tap **Sync Now** as many times as you like — syncing twice in a
row does not create duplicates or double-count anything (every expense is
tracked by a stable ID, not appended).

## What sync does *not* do

- **No background sync.** If the app isn't open and in the foreground on
  both phones, nothing syncs. There is no push notification, no silent
  background refresh — this is a deliberate simplicity/reliability
  trade-off for a free, serverless app (see `BUILD_PLAN.md`).
- **No cloud copy, ever.** If you lose both phones simultaneously without
  ever exporting a backup, your data is gone. Use **Settings → Export
  Expenses** periodically for a JSON backup you control.
- **No conflict picker.** Conflicts are resolved automatically
  (latest-edit-wins) — there's no UI to manually choose between two
  conflicting versions. This is intentional for v1 simplicity.

## Common problems

| Symptom | Likely cause / fix |
|---|---|
| "Not searching" / no devices ever appear | Both phones need to be on the same Wi-Fi network and have the app open. Check Local Network permission (Settings app → ExpenseApp). |
| Invite sent but never confirmed | The other person needs to tap **Connect** on the confirmation alert — it doesn't auto-accept. |
| "Sync couldn't finish. Your local expenses are safe. Try again." | A transient network hiccup. Nothing was lost — tap **Sync Now** again once both phones show Connected. |
| Peer disappears mid-sync | One phone left Wi-Fi range or backgrounded the app. Reopen the app, foreground it, and re-pair via **Find Nearby Device**. |
| Synced but numbers look wrong on one phone | Pull to the **Balance** tab — the balance recalculates from the full merged expense list, so it should match once both phones show "Records received" > 0. If it still looks wrong, check whether a filter is active on the Transactions tab (filters don't affect the Balance tab, but can make the list look incomplete). |
