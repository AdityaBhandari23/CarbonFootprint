# Personal Carbon Footprint Tracker 🌱

A comprehensive Flutter application for tracking and analyzing your daily carbon footprint. This self-contained, fully offline application helps users log activities, calculate their environmental impact, and visualize their progress toward sustainable living.

## 📱 Features

### Dashboard 📊
- **Real-time Summary**: View your total, weekly, and monthly carbon footprint
- **Interactive Charts**: Daily carbon footprint visualization using fl_chart
- **Motivational Elements**: Progress indicators and encouraging messages based on your performance
- **Period Selector**: Toggle between 7-day and 30-day views
- **Category Breakdown**: Pie chart showing carbon footprint by activity type

### Log Activity 📝
- **Smart Form**: Intuitive dropdowns for activity types and subtypes
- **Real-time Calculation**: Instant carbon footprint calculation as you type
- **Date Selection**: Log activities for any date
- **Input Validation**: Comprehensive form validation
- **Activity Categories**: Transport, Food, Home Energy, Shopping, and Waste

### History 📜
- **Comprehensive Listing**: View all logged activities with detailed information
- **Advanced Filtering**: Filter by activity type and date range
- **Activity Details**: Tap any activity to see full details in a modal
- **Delete Functionality**: Remove activities with confirmation dialog
- **Summary Statistics**: Real-time totals for filtered activities

## 🏗️ Architecture

### Data Models
- **Activity**: Core data model with id, type, subtype, value, carbonFootprint, and date
- **CarbonFactor**: Emission factor model for different activity types

### Services
- **DatabaseService**: SQLite database management using sqflite
- **CarbonFactorsService**: Loads and manages emission factors from JSON assets

### Database Design
- **Offline-first**: All data stored locally using SQLite
- **CRUD Operations**: Complete Create, Read, Update, Delete functionality
- **Efficient Queries**: Optimized for date ranges and filtering

## 📊 Carbon Emission Factors

The app includes comprehensive emission factors for:

### Transport 🚗
- Car trips (Petrol, Diesel, Electric)
- Public transport (Bus, Train)
- Aviation (Domestic, International flights)

### Food 🍽️
- Meat meals (Beef, Lamb, Pork, Chicken)
- Seafood meals
- Vegetarian and Vegan options

### Home Energy 🏠
- Electricity usage
- Natural gas
- Heating oil
- Coal heating

### Shopping 🛒
- Clothing
- Electronics
- Books/Paper products

### Waste 🗑️
- General waste
- Recycling
- Food waste

## 🛠️ Technical Implementation

### Core Technologies
- **Flutter**: Cross-platform mobile development
- **SQLite (sqflite)**: Local database storage
- **fl_chart**: Interactive data visualization
- **Material Design 3**: Modern UI/UX

### State Management
- **StatefulWidget with setState**: Following project requirements, no external state management libraries

### Key Features
- **Offline Functionality**: No internet connection required
- **Real-time Updates**: Live calculations and chart updates
- **Data Persistence**: All data saved locally using SQLite
- **Interactive UI**: Touch-friendly with smooth animations

## 📁 Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   ├── activity.dart        # Activity data model
│   └── carbon_factor.dart   # Carbon factor model
├── services/
│   ├── database_service.dart      # SQLite database management
│   └── carbon_factors_service.dart # JSON asset management
├── screens/
│   ├── main_screen.dart           # Navigation container
│   ├── dashboard_screen.dart      # Charts and summary
│   ├── log_activity_screen.dart   # Activity logging form
│   └── history_screen.dart        # Activity history and management
├── widgets/                  # Reusable UI components
└── assets/
    └── data/
        └── carbon_factors.json    # Emission factor data
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)
- Android Studio / VS Code with Flutter extensions

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd CarbonFootPrint
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the application**
   ```bash
   flutter run
   ```

### Building for Release

```bash
# Android APK
flutter build apk --release

# iOS (requires macOS and Xcode)
flutter build ios --release
```

## 📱 Usage Guide

### Logging Activities
1. Navigate to the "Log Activity" tab
2. Select an activity type (e.g., Transport)
3. Choose a specific activity (e.g., Car Trip - Petrol)
4. Enter the value (e.g., 50 km)
5. See real-time carbon footprint calculation
6. Save the activity

### Viewing Dashboard
1. Navigate to the "Dashboard" tab
2. View summary cards showing total footprint
3. Check motivational progress indicator
4. Explore interactive charts
5. Switch between 7-day and 30-day views

### Managing History
1. Navigate to the "History" tab
2. View all logged activities
3. Use filters to find specific activities
4. Tap any activity for detailed information
5. Delete activities if needed

## 🎯 Carbon Footprint Targets

The app uses a weekly target of 100 kg CO2e based on sustainable living guidelines:
- **🌟 Excellent**: < 50 kg CO2e/week
- **👍 Good**: 50-100 kg CO2e/week  
- **💡 Needs Improvement**: 100-200 kg CO2e/week
- **⚡ Action Required**: > 200 kg CO2e/week

## 📊 Data Visualization

### Dashboard Charts
- **Line Chart**: Daily carbon footprint trends
- **Pie Chart**: Category breakdown
- **Progress Bars**: Weekly targets
- **Summary Cards**: Key metrics

### Interactive Features
- Tap chart points for detailed tooltips
- Period selection (7 days / 30 days)
- Real-time data updates
- Smooth animations

## 🔒 Privacy & Security

- **Offline-First**: All data remains on your device
- **No Cloud Sync**: Complete privacy protection
- **Local Storage**: SQLite database for data persistence
- **No Analytics**: No usage tracking or data collection

## 🧪 Testing

The application has been designed with testability in mind:

```bash
# Run unit tests
flutter test

# Run integration tests
flutter drive --target=test_driver/app.dart
```

## 🤝 Contributing

This is a portfolio project, but contributions are welcome:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Carbon emission factors sourced from EPA and climate research organizations
- Flutter community for excellent packages (sqflite, fl_chart)
- Material Design team for UI/UX guidelines

## 📞 Support

For questions or support, please open an issue in the GitHub repository.

---

**Built with 💚 for a sustainable future** 