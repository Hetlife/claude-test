# BUILD PLAN — Personal Expense App (Het + Sarthak)

## 0. Environment inspection

This session runs in a **Linux container** with no macOS, no Xcode, and no
Swift toolchain installed (`swift`, `xcodebuild` are not present; only
`python3`, `git`, `zip`). There is no simulator and no physical device
attached.

**Consequence:** the project cannot be compiled, unit-tested, or run in
this environment. `xcodebuild`/`swift test` cannot be executed here. This
is documented up front per the task's own instructions ("do not claim
success for a test that was not actually performed").

**What this build plan does instead:**
- Produce a complete, valid Xcode project (hand-authored `project.pbxproj`
  via a deterministic Python generator, since `xcodegen`/`tuist` are also
  unavailable) with every source file wired into the correct targets.
- Write production Swift/SwiftUI code by hand, keeping each unit small and
  syntactically conservative to minimize risk in the absence of a compiler.
- Write full XCTest coverage for every pure/testable unit (models,
  `BalanceCalculator`, `SyncEngine` merge logic, `ExpenseRepository`,
  `ExportImportService`). These tests are believed correct but are
  **unverified by an actual test run** — this is called out again in
  `TEST_REPORT.md`.
- Perform a manual static-review pass (structure, naming, import
  correctness, brace/paren balance, API usage against known Apple APIs) in
  place of a compiler.
- Two-phone sync (Phase 10) cannot be physically tested — no devices are
  attached to this session. The merge algorithm itself is covered by pure
  unit tests that don't require MultipeerConnectivity or real devices.

The first thing the user should do after downloading the project is open
it in Xcode and build it — see `BUILD_AND_INSTALL.md`. Any compiler errors
that turn up should be reported back; the architecture is intentionally
simple so such fixes should be small and localized.

## 1. Architecture

```
ExpenseApp/
  ExpenseApp.xcodeproj/          Xcode project (hand-generated pbxproj)
  ExpenseApp/                    App target sources
    ExpenseAppApp.swift          @main App entry, SwiftData container setup
    Info.plist                   Bonjour + Local Network usage strings
    Assets.xcassets              AppIcon, AccentColor
    Models/
      Payer.swift                Het | Sarthak enum
      PaymentMethod.swift        cash | online enum
      ExpenseCategory.swift      category enum with SF Symbol + display name
      ExpenseRecord.swift        plain Codable DTO — the sync/business-logic
                                  representation, has no SwiftData dependency
      Expense.swift              @Model SwiftData persistence entity +
                                  conversion to/from ExpenseRecord
    Persistence/
      PersistenceController.swift   ModelContainer setup (app + in-memory test)
      ExpenseRepository.swift       CRUD + tombstone delete, protocol-based
    Services/
      BalanceCalculator.swift       pure 50/50 balance engine (no SwiftUI, no
                                     SwiftData — operates on [ExpenseRecord])
      ExportImportService.swift     JSON export/import, schema validation,
                                     reuses SyncEngine.merge for safe import
    Sync/
      SyncMessage.swift          versioned Codable wire protocol
      SyncEngine.swift           pure merge function (UUID + updatedAt LWW)
      PeerSyncManager.swift      MultipeerConnectivity session/transport
    Views/
      RootTabView.swift, HomeView.swift, TransactionsView.swift,
      AddExpenseView.swift, ExpenseDetailView.swift, BalanceView.swift,
      SettingsView.swift, SyncView.swift, OnboardingView.swift
      Components/                small reusable view pieces
    Utilities/
      CurrencyFormatter.swift, Haptics.swift, DeviceIdentity.swift
  ExpenseAppTests/               XCTest unit test target
    BalanceCalculatorTests.swift
    ExpenseRepositoryTests.swift
    SyncEngineTests.swift
    ExportImportServiceTests.swift
    ExpenseRecordTests.swift
```

Key architectural decision: **business logic never touches SwiftUI or
SwiftData directly.** `ExpenseRecord` is a plain `Codable` struct used by
`BalanceCalculator`, `SyncEngine`, and `ExportImportService`. The SwiftData
`@Model` class `Expense` is only a storage entity; `ExpenseRepository`
converts between the two at the persistence boundary. This makes the
balance/sync logic unit-testable without a persistence stack or a UI, and
keeps `Sync/` reusable for both peer-to-peer sync and JSON import (same
merge algorithm, two entry points).

## 2. Persistence choice

**SwiftData** (iOS 17+), per spec's first preference. It is fully native,
integrates directly with SwiftUI (`@Query`, `.modelContainer`), requires no
schema/migration boilerplate for this small model, and is fully local — no
CloudKit sync container is configured (this is critical: SwiftData
supports an *optional* CloudKit backing, which is deliberately **not**
enabled here, since the spec forbids any cloud/hosted backend and requires
MultipeerConnectivity direct sync instead).

Deployment target: **iOS 17.0** (required for SwiftData).

## 3. Local-network sync strategy

- `MCNearbyServiceAdvertiser` + `MCNearbyServiceBrowser` + `MCSession`,
  service type `expenseapp-sync` (15 chars, valid Bonjour token — max is 15).
- Manual, foreground-only pairing: both apps must be open; connection is
  confirmed via `MCSession` invite/accept, not auto-join.
- On connect, both sides send a `.hello`, then a full `.expenseBatch` of
  every local `ExpenseRecord` (active + tombstoned), chunked at a fixed
  batch size to respect the message-size guidance in the spec, followed by
  `.syncComplete`. Given the dataset size (two people's personal expenses),
  a full-state exchange is simpler and strictly safer than delta sync — it
  cannot miss an update — while remaining fast enough in practice.
- Each side merges the incoming batch into its local store via
  `SyncEngine.merge`: per-UUID, later `updatedAt` wins; ties keep the local
  record (deterministic, per spec §11). Deletions are tombstones
  (`deletedAt` set), so a delete always propagates correctly and never
  "un-deletes" on the peer.
- No background sync is implemented or claimed anywhere in the UI/copy —
  foreground manual sync only, per spec §12.

## 4. Milestones

1. Data model + persistence + repository tests
2. BalanceCalculator + tests
3. Core UI (Home, Transactions, Add/Edit, Balance, Settings)
4. Search & filters
5. Sync engine + SyncView + merge tests
6. Local network Info.plist config + permission copy
7. Export/Import + tests
8. Accessibility/dark-mode/haptics polish
9. Xcode project generation
10. Static validation pass (no compiler available)
11. Documentation + packaging (zip)

## 5. Known limitations (stated up front)

- **Not compiled or run in this environment.** Must be opened in Xcode on
  a Mac before first use; report any compiler errors.
- **Two-phone sync not physically tested** — no devices available in this
  session. Merge logic is unit-tested in isolation.
- Free Apple ID signing expires periodically and requires rebuild/reinstall
  — documented in `BUILD_AND_INSTALL.md`, not glossed over.
- "This Trip" custom period grouping from the design doc is intentionally
  simplified to **This Month / All Time** in v1 — there is no trip/project
  entity in the v1 data model (spec explicitly says not to add it until
  the basic system is stable), so a "This Trip" filter would have nothing
  real to key off of.
