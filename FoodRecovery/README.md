# Food Waste Recovery Platform

A comprehensive regional food waste reduction platform with AI-powered email processing for single truck operations serving up to 5 food banks within a 35-mile radius.

## Features

### 🏢 Regional Setup
- Configure single truck operation with up to 5 food banks within 35-mile radius
- Set service area, operating hours, and contact information
- Map-based region center selection

### 🏠 Food Bank Onboarding
- Complete onboarding forms with location, capacity, and daily usage
- Contact information and operating hours
- Special requirements and capacity tracking
- Real-time utilization monitoring

### 🛒 Grocery Store Registration
- Store registration with location and contact details
- Email setup for donation notifications
- Preferred pickup time configuration
- Integration with AI email processing

### 🤖 AI-Powered Email Processing
- OpenAI integration for extracting food donation details
- Automatic extraction of:
  - Food type (produce, dairy, meat, bakery, frozen, canned, prepared, other)
  - Quantity in pounds
  - Expiration dates
  - Description and special notes
- Confidence scoring for AI extractions
- Automatic store matching based on email addresses

### 📅 Intelligent Scheduling System
- Automated pickup time generation based on store preferences
- Delivery time optimization for food bank operating hours
- 4-hour operational window management
- Urgent donation prioritization (expiring within 2 days)

### 📧 Automated Email Confirmations
- Pickup confirmations sent to grocery stores
- Delivery confirmations sent to food banks
- Route summaries for operations team
- Real-time status updates

### ✅ Confirmation Tracking System
- Two-way approval workflow (stores and food banks)
- Status tracking for all pickups and deliveries
- Real-time updates and notifications
- Completion tracking with timestamps

### 🗺️ Dynamic Route Optimization
- AI-powered route optimization for confirmed pickups and deliveries
- Time window constraints and priority handling
- Distance and duration calculations
- Real-time route adjustments

### 📊 Regional Dashboard
- Single truck schedule overview
- Confirmed pickups and deliveries
- Food bank capacity and utilization
- Statistics and performance metrics
- Recent activity tracking

## Technical Architecture

### Data Models
- **RegionalOperation**: Core operation configuration
- **FoodBank**: Food bank details and capacity management
- **GroceryStore**: Store information and donation preferences
- **Donation**: Individual donation records with AI-extracted data
- **Pickup**: Pickup scheduling and status tracking
- **Delivery**: Delivery scheduling and status tracking
- **PickupRoute**: Route optimization and management

### Services
- **EmailProcessingService**: OpenAI integration for email parsing
- **RouteOptimizationService**: Dynamic route optimization algorithms
- **SchedulingService**: Intelligent scheduling and time management
- **EmailService**: Automated email notifications and confirmations

### UI Components
- **RegionalSetupView**: Operation configuration interface
- **FoodBankOnboardingView**: Food bank registration and management
- **GroceryStoreRegistrationView**: Store registration interface
- **EmailProcessingView**: AI email processing interface
- **RegionalDashboardView**: Main dashboard with analytics

## Setup Instructions

### 1. API Configuration
Update `AppConfiguration.swift` with your API keys:
```swift
static let openAIAPIKey = "your-openai-api-key-here"
static let smtpUsername = "your-email@gmail.com"
static let smtpPassword = "your-app-password"
```

### 2. OpenAI Setup
1. Get an OpenAI API key from https://platform.openai.com/
2. Update the API key in `AppConfiguration.swift`
3. Ensure you have sufficient credits for API usage

### 3. Email Setup
1. Configure SMTP settings for email notifications
2. Use app-specific passwords for Gmail
3. Test email functionality before production use

### 4. Database Setup
The app uses SwiftData for local storage. No additional setup required.

## Usage Workflow

### 1. Initial Setup
1. Create a regional operation using the Setup tab
2. Configure service area and operating parameters
3. Add food banks using the Food Banks tab
4. Register grocery stores using the Stores tab

### 2. Daily Operations
1. Process donation emails using AI Processing tab
2. Generate daily schedules from the Dashboard
3. Monitor confirmations and route status
4. Track completion and performance metrics

### 3. Email Processing
1. Grocery stores send donation emails to configured addresses
2. Use AI Processing tab to extract donation details
3. System automatically matches stores and creates donation records
4. Schedule pickups and deliveries based on extracted data

## Key Benefits

- **Efficiency**: Automated scheduling and route optimization
- **Accuracy**: AI-powered email processing reduces manual errors
- **Transparency**: Real-time tracking and status updates
- **Scalability**: Designed for single truck operations with growth potential
- **User-Friendly**: Intuitive interface for all stakeholders

## Future Enhancements

- Multi-truck support for larger operations
- Mobile app for drivers
- Integration with food bank management systems
- Advanced analytics and reporting
- Weather and traffic integration for route optimization
- Inventory management for food banks

## Support

For technical support or feature requests, please contact the development team.
