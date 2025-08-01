# VoltStar

A macOS menu bar application for monitoring your Polestar electric vehicle in real-time.

![Alt text](assets.screen2.png?raw=true "Title")

## Features

- **Menu Bar Integration**: Lightweight menu bar app showing configurable vehicle status
- **Real-time Data**: Battery percentage, range (km/miles), charging status, and estimated charge time
- **Multiple Display Options**: Choose what to display in the menu bar:
  - Battery percentage
  - Range in kilometers
  - Range in miles  
  - Estimated charging time
- **Vehicle Information**: Shows your car's image and model name
- **Secure Authentication**: Uses OAuth2/OIDC with PKCE for secure Polestar API access
- **Auto-refresh**: Updates vehicle data every 5 minutes
- **Launch at Startup**: Optional automatic startup with macOS
- **Settings Panel**: Easy configuration of credentials and display preferences

## Requirements

- macOS 13.0 or later
- Xcode 15.0 or later (for building from source)
- Valid Polestar account credentials
- Vehicle VIN number

## Installation

### From Source

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd voltstarP
   ```

2. Open the project in Xcode:
   ```bash
   open Voltstar.xcodeproj
   ```

3. Build and run the project (⌘+R)

## Setup

1. Launch the Voltstar app
2. Click on the menu bar icon
3. Click "Settings"
4. Enter your Polestar credentials:
   - Email address
   - Password
   - Vehicle VIN number
5. Choose your preferred menu bar display option
6. Optionally enable "Launch at Startup"
7. Click "Save"

The app will authenticate with Polestar's servers and begin displaying your vehicle data.

## Development

### Running Tests

To run the test suite:

```bash
# Run all tests
xcodebuild test -scheme Voltstar -destination 'platform=macOS'

# Run unit tests only
xcodebuild test -scheme Voltstar -destination 'platform=macOS' -only-testing VoltstarTests

# Run UI tests only
xcodebuild test -scheme Voltstar -destination 'platform=macOS' -only-testing VoltstarUITests
```

Or use Xcode:
- Press ⌘+U to run all tests
- Use the Test Navigator (⌘+6) to run specific test suites

### Project Structure

```
MyStar/
├── MyStar/
│   ├── MyStarApp.swift          # Main app entry point and menu bar setup
│   ├── ContentView.swift        # Main UI and settings panel
│   ├── PolestarAPI.swift        # API client for Polestar services
│   ├── Assets.xcassets/         # App icons and assets
│   └── MyStar.entitlements     # App entitlements
├── MyStarTests/                 # Unit tests
├── MyStarUITests/              # UI tests
└── MyStar.xcodeproj/           # Xcode project
```

### Architecture

- **SwiftUI**: Modern declarative UI framework
- **ObservableObject**: Reactive state management for API data
- **OAuth2/OIDC**: Secure authentication with PKCE flow
- **GraphQL**: API communication with Polestar backend
- **UserDefaults**: Local storage for user preferences and credentials
- **Timer**: Periodic data refresh mechanism

## API Integration

The app integrates with Polestar's official API endpoints:
- Authentication via `polestarid.eu.polestar.com`
- Vehicle data via `pc-api.polestar.com/eu-north-1/mystar-v2/`

Authentication uses the OAuth2 authorization code flow with PKCE for enhanced security.

## Privacy & Security

- Credentials are stored securely in UserDefaults
- OAuth2 with PKCE prevents code interception attacks
- All API communication uses HTTPS
- No data is transmitted to third parties

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request


## Disclaimer

This project is not affiliated with Polestar. Use at your own risk. The developers are not responsible for any issues that may arise from using this application.
