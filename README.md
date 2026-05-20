# FoodRecovery

A multi-platform SwiftUI app (iOS, macOS, visionOS) that coordinates food waste recovery logistics — connecting grocery stores and restaurants with local food banks through automated scheduling, route optimization, and AI-assisted email processing.

---

## Features

### Regional Operations
- Configure a regional operation with a defined service radius (up to 50 miles) and operating hours
- Manage multiple food banks, grocery stores, and restaurants within the region
- Dashboard with live capacity utilization, donation metrics, and route status

### Food Donation Workflow
- Grocery stores and restaurants are onboarded with contact info, location, and donation preferences
- Incoming donation emails are parsed using intelligent pattern matching (OpenAI-ready) to extract food type, quantity, and expiration dates
- Donations are matched to food banks based on priority needs and available capacity

### Intelligent Scheduling & Route Optimization
- Daily pickup/delivery schedules are generated automatically, prioritizing donations expiring within 48 hours
- Nearest-neighbor routing algorithm with time-window constraints minimizes drive time
- Turn-by-turn route tracking via MapKit with real-time location updates

### Restaurant Tax Benefit Tracking
- Records fair market value and cost basis for each donation
- Calculates enhanced deductions (IRC § 170(e)(3)) for tax documentation
- Flags donations requiring IRS Form 8283 (over $500 fair market value)

### Automated Notifications
- Email confirmations sent to stores, food banks, and operations staff
- SMS/iMessage updates via the native MessageUI framework
- WhatsApp fallback for international contacts

---

## Requirements

| Platform | Minimum Version |
|---|---|
| iOS / iPadOS | 18.5 |
| macOS | 14.0 |
| visionOS | 2.5 |
| Xcode | 16.4+ |
| Swift | 5.0 |

---

## Setup

### 1. Clone and open
```bash
git clone https://github.com/clarkdjcr/FoodRecovery.git
open FoodRecovery/FoodRecovery.xcodeproj
```

### 2. Configure credentials
Edit `FoodRecovery/Configuration/AppConfiguration.swift`:
```swift
static let openAIAPIKey = "your-openai-api-key"   // optional — falls back to pattern matching
static let smtpUsername  = "you@gmail.com"
static let smtpPassword  = "your-app-specific-password"
static let defaultToEmail = "you@example.com"
```

### 3. Build & run
Select a simulator or connected device and press **Run** (⌘R). Demo data is loaded automatically on first launch.

---

## Architecture

```
FoodRecovery/
├── Configuration/       AppConfiguration.swift
├── Models/              SwiftData models (RegionalOperation, FoodBank, GroceryStore,
│                        Restaurant, Donation, Pickup, Delivery, PickupRoute, …)
├── ViewModels/          RegionalOperationViewModel
├── Views/
│   ├── Components/      AppTheme, ModernFormComponents
│   ├── RegionalDashboardView
│   ├── RegionalSetupView
│   ├── FoodBankOnboardingView
│   ├── GroceryStoreRegistrationView
│   ├── RestaurantOnboardingView
│   ├── EmailProcessingView
│   ├── RouteListView
│   ├── RouteTrackingView
│   └── TaxBenefitCalculatorView
└── Services/
    ├── EmailProcessingService   AI-assisted donation email parsing
    ├── EmailService             SMTP confirmation emails
    ├── SchedulingService        Daily route generation
    ├── RouteOptimizationService Nearest-neighbor TSP with time windows
    ├── LocationManager          CoreLocation + MapKit directions
    ├── InstantMessagingService  SMS / WhatsApp notifications
    └── PhoneValidationService
```

**Persistence:** SwiftData with on-disk storage (all models declared in `FoodRecoveryApp.swift`).

---

## Privacy

- Location is used only to optimize pickup/delivery routes (`NSLocationWhenInUseUsageDescription`)
- No location data is transmitted to third parties
- All data is stored on-device via SwiftData
- See `FoodRecovery/PrivacyInfo.xcprivacy` for the full privacy manifest

---

## License

MIT License — see [LICENSE](LICENSE) for details.
