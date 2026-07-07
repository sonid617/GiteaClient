# GiteaClient — Handoff

iOS app for browsing Gitea self-hosted Git servers. SwiftUI, iOS 16+, no third-party dependencies.

---

## Quick start

```bash
cd ~/Downloads/GiteaClient
xcodegen generate          # regenerate .xcodeproj after any file additions
open GiteaClient.xcodeproj
```

Build target: **GiteaClient** → any iPhone 16 simulator.

> Run `xcodegen generate` whenever you add or delete Swift files outside Xcode — it's the only thing that updates the .xcodeproj file list.

---

## Architecture

```
GiteaClient/
├── App/
│   ├── GiteaClientApp.swift   – @main, injects AppState
│   └── AppState.swift         – singleton EnvironmentObject; holds api client + currentUser
├── Models/                    – Codable Gitea API response structs
├── Services/
│   ├── GiteaAPIClient.swift   – all HTTP, token auth header
│   └── KeychainHelper.swift   – token + serverURL persistence
├── ViewModels/                – @MainActor ObservableObjects per feature
└── Views/
    ├── Components/
    │   ├── DesignSystem.swift  – Color extensions, avatarColor(), languageColor(), DesignCard, SectionLabel
    │   ├── AppHeader.swift     – LargeHeader, CompactHeader, InboxHeader, ProfileHeader, CustomTabBar, AppTab enum
    │   └── ...
    ├── Auth/                   – LoginView, ServerURLView
    ├── Main/                   – MainTabView (ZStack opacity tabs)
    ├── Explore/                – ExploreView
    ├── Repositories/           – RepositoryListView, RepositoryDetailView, FileExplorerView, FileContentView, ReadmeView, ReleasesView
    ├── Issues/                 – IssueListView, IssueDetailView
    ├── Notifications/          – NotificationsView
    ├── Profile/                – ProfileView
    └── PullRequests/           – PullRequestListView, PRDetailView
```

### Navigation pattern

No native `TabView` or `NavigationBar`. Everything is custom:

- **MainTabView** — `ZStack` with one view per tab, toggled via `opacity` + `allowsHitTesting`. This preserves each tab's `NavigationStack` state across switches.
- **CustomTabBar** — pinned via `.safeAreaInset(edge: .bottom, spacing: 0)`.
- **Per-screen**: `VStack(spacing: 0) { CustomHeader; Content }` + `.toolbar(.hidden, for: .navigationBar)` + `.navigationBarBackButtonHidden(true)`.
- Back navigation: `@Environment(\.dismiss)` inside `CompactHeader`.

### Auth flow

```
AppScreen.serverURL → AppScreen.login → AppScreen.main
```

`AppState.restoreSession()` runs on launch; if Keychain has `serverURL` + `token` it skips straight to `.main`. Login creates a Gitea API token via `POST /users/{user}/tokens`, stores it in Keychain.

### API client

`GiteaAPIClient` — init with `serverURL` + `token`. All calls are `async throws`. Auth header: `Authorization: token {token}`.

---

## Design system

Defined in `DesignSystem.swift`:

| Token | Light | Dark |
|-------|-------|------|
| `Color.appBg` | `#F5F4F2` | `#17191A` |
| `Color.appCard` | `#FFFFFF` | `#212325` |
| `Color.appCardAlt` | `#F0EFEC` | `#2A2D2F` |
| `Color.appBorder` | 12% black | 12% white |
| Accent | `#1F8A6F` | `#4FCBA6` |

Header types (all in `AppHeader.swift`):
- `LargeHeader` — explore/repos tabs (large title + inline search)
- `CompactHeader` — detail screens (back button, centered title, optional trailing button)
- `InboxHeader` — notifications tab (All/Unread filter chips)
- `ProfileHeader` — profile tab (Sign Out button)

---

## Pending / known gaps

- [ ] **Settings screen** — user asked for a Settings section in ProfileView; not yet implemented. Suggested items: default branch, app theme override, notification poll interval, about/version.
- [ ] **Build verification** — full `xcodebuild` hasn't been confirmed clean after the redesign. Run it once before shipping.
- [ ] **App icon** — custom logo asset (`Gemini_Generated_Image_4kpvyy4kpvyy4kpv.png`) was generated but not yet imported into `Assets.xcassets/AppIcon`.
- [ ] **GitHub repo** — project has not been pushed to GitHub yet. No `.gitignore` exists.

---

## Creating the GitHub repo

```bash
cd ~/Downloads/GiteaClient
git init
# create .gitignore for Xcode first (see below)
git add .
git commit -m "Initial commit"
gh repo create GiteaClient --public --source=. --push
```

Recommended `.gitignore` entries: `*.xcodeproj/xcuserdata/`, `DerivedData/`, `.DS_Store`, `*.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist`.

---

## project.yml (xcodegen)

Key settings:
- `PRODUCT_BUNDLE_IDENTIFIER: com.giteaclient.app`
- `ASSETCATALOG_COMPILER_SKIP_APP_STORE_DEPLOYMENT: YES` — suppresses "no simulator runtimes" actool error
- `DEVELOPMENT_TEAM: ""` — fill in your Apple Developer Team ID to enable device signing
