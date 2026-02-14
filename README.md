# Ledgerly

A calm, premium personal finance tracker for iOS focused on clarity and daily habits.

## Features

- **One-tap logging** – Record income/expense in seconds
- **Clean analytics** – Beautiful charts and insights
- **Budget control** – Monthly budgets per category with gentle overspend warnings
- **Weekly/Monthly money review** – Auto-generated recap cards
- **Offline-first** – 100% functional without internet
- **SwiftData persistence** – All data stored locally

## Requirements

- iOS 17+
- Xcode 15+
- Swift 5.9+

## Setup & Run

1. Open `DF868w.xcodeproj` in Xcode
2. Select your development team in Signing & Capabilities (for device run)
3. Select a simulator or device
4. Build and run (⌘R)

**Deployment target**: The app requires iOS 17+ for SwiftData and Observation. If the project shows iOS 15.6, update the deployment target in the target's General settings to 17.0.

## Architecture

- **MVVM** – View / ViewModel / Services
- **SwiftData** – Persistence layer
- **SwiftUI** – UI framework

### Folder structure

```
DF868w/
├── App/                 # App entry, AppStore
├── DesignSystem/        # Theme, components (GlassCard, PrimaryButton, etc.)
├── Models/              # SwiftData models (Transaction, Category, Budget, Goal, Template, Preferences, PaymentMethod)
├── Persistence/         # ModelContainer, SeedData
├── Services/            # CurrencyFormatter, TransactionService, BudgetService, ChartDataBuilder, ExportImportService, NotificationService, WidgetDataService
├── Features/
│   ├── Dashboard/       # Balance card, Quick Add, Weekly Review
│   ├── Transactions/    # List, form, detail
│   ├── Insights/        # Charts, Budgets, Goals
│   ├── Onboarding/      # 4-screen flow
│   └── Settings/        # Currency, categories, templates, export/import
```

### Data models

- **Transaction** – type, amount, category, date, note, payment method, tags
- **Category** – name, icon, color
- **Budget** – category, month, limit
- **Goal** – name, target amount, target date, current amount
- **Template** – one-tap transaction presets
- **Preferences** – currency, theme, reminders, haptics

## Tests

### Unit tests
- Budget calculations correctness
- Month grouping correctness
- CSV export formatting
- JSON backup/restore round trip
- Currency formatting

Run: `xcodebuild test -scheme DF868w -destination 'platform=iOS Simulator,name=iPhone 16'` (or use Xcode's Test action)

### UI tests
- Add expense and verify
- Apply filter
- Export backup

Run: Same as unit tests with the UI test target.

## QA Checklist

- [ ] **iPhone SE** – Layout, no clipping, scroll works
- [ ] **iPhone 15 Pro Max** – Large screen layout
- [ ] **iPad Air 11"** – Adaptive layout, NavigationSplitView where applicable
- [ ] **Dark mode** – All screens readable
- [ ] **Reminder permission flow** – Enable reminder, grant/deny notification
- [ ] **Export/Import** – JSON backup, CSV export, restore
- [ ] **Widgets** – Month Summary and Quick Add widgets (requires adding LedgerlyWidgets extension target)
- [ ] **Performance** – Test with 5k transactions (seed via import)
- [ ] **Accessibility** – VoiceOver, Dynamic Type, Reduce Motion

## Widgets (Optional)

To add the widgets:

1. File → New → Target → Widget Extension
2. Name it "LedgerlyWidgets"
3. Replace the generated Swift with the contents of `LedgerlyWidgets/LedgerlyWidgets.swift`
4. Add App Group `group.ioi.df868w.ledgerly` to both app and widget targets
5. Add the `ledgerly://` URL scheme in the main app target's Info for Quick Add widget deep link

## URL Scheme

For the Quick Add widget to open the app: add URL scheme `ledgerly` in the app target's Info (URL Types). The widget uses `ledgerly://add-expense`.

## Default Categories

- Groceries, Transport, Coffee, Rent, Health, Shopping
- Entertainment, Education, Travel, Bills
- Salary, Freelance, Other

## License

Private / Personal use.
