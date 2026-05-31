# MapKit Integration Setup

## Required Configuration

### 1. Info.plist Permissions
Add the following location permissions to your app's Info.plist:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access to track delivery vehicles and optimize food rescue routes.</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app needs location access to track delivery vehicles and optimize food rescue routes even when running in the background.</string>
```

### 2. Capabilities
Enable the following capabilities in your Xcode project:
- Location Services
- Maps

### 3. Privacy Manifest
The `PrivacyInfo.xcprivacy` file has been created to declare location data usage for App Store compliance.

## Features Implemented

### LocationManager Service
- **Real-time location tracking** with CoreLocation
- **Route calculation** using MapKit Directions
- **Optimized multi-stop routing** for pickup/delivery sequences
- **Location permission handling** with proper authorization flow

### RouteTrackingView
- **Interactive map** showing current location, pickups, and deliveries
- **Real-time route visualization** with polyline overlays
- **Status-based color coding** for different pickup/delivery states
- **Route statistics** including distance, time, and stop count
- **Dynamic route recalculation** as locations change

### RouteListView
- **List of all pickup routes** with status indicators
- **Navigation to detailed tracking** for each route
- **Route summary information** including stops and distance

## Usage

### Basic Integration
```swift
// The LocationManager is already integrated into RouteTrackingView
// Access through the Routes tab in the main TabView
```

### Tracking a Route
1. Navigate to the "Routes" tab
2. Select a pickup route from the list
3. The map will show:
   - Current device location (blue dot)
   - Pickup locations (shopping cart icons)
   - Delivery locations (house icons) 
   - Optimized route between all stops
4. Tap "Recalculate" to update route based on current location

### Status Indicators
- **Orange**: Proposed/Planned
- **Blue**: Confirmed
- **Yellow**: In Progress  
- **Green**: Completed
- **Red**: Cancelled

## Model Changes

### Updated Models
- **GroceryStore**: Now stores `latitude` and `longitude` as separate Double properties
- **FoodBank**: Now stores `latitude` and `longitude` as separate Double properties
- **PickupRoute**: Includes `totalDistance` and `estimatedDuration` for route metrics

### Integration with Existing Data
The system works with your existing SwiftData models:
- Routes are automatically populated from your PickupRoute entities
- Pickups and Deliveries reference their associated GroceryStore/FoodBank locations
- Real-time updates reflect in the map as route status changes

## Technical Notes

### Performance
- Location updates are filtered to 10-meter intervals to balance accuracy and battery life
- Route calculations are performed asynchronously to avoid blocking the UI
- Maps use standard elevation for better performance on older devices

### Privacy
- Location access is requested only when needed
- Active route location may sync through Firebase Realtime Database for app functionality
- Privacy manifest declares location and related operational data usage for App Store compliance

### Future Enhancements
- Background location tracking for active routes
- Turn-by-turn navigation integration
- Route optimization based on traffic conditions
- Integration with external fleet management systems
