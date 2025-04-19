# CloutMarket

CloutMarket is an iOS app that enables content creators to monetize their photos and videos by selling them directly to consumers in an easy-to-use marketplace.

## Features

- **User Authentication**: Email/password login and registration
- **Content Upload**: Upload photos and videos with pricing
- **Marketplace**: Browse and search for content by other creators
- **Purchase System**: Buy content securely using Stripe integration
- **Content Download**: Access purchased content
- **Wallet**: Track earnings, connect Stripe for payouts, and withdraw funds
- **User Profile**: Manage account settings

## Architecture

CloutMarket is built using the MVVM (Model-View-ViewModel) architecture pattern:

- **Models**: Core data structures that represent entities in the app
- **Views**: SwiftUI-based user interface components
- **ViewModels**: Business logic layer that connects models to views
- **Services**: API and data access layer that interacts with Firebase and Stripe

## Technical Stack

- **Frontend**: SwiftUI
- **Backend**: Firebase (Auth, Firestore, Storage)
- **Payment Processing**: Stripe
- **Dependencies**: Swift Package Manager

## Project Structure

```
CloutMarket/
├── Models/               # Data models
├── ViewModels/           # Business logic
├── Views/                # UI components
├── Services/             # API services
├── Utilities/            # Helper functions
├── Resources/            # Assets and resources
└── CloutMarketApp.swift  # App entry point
```

## Prerequisites

- Xcode 14.0+
- iOS 15.0+
- Swift 5.7+
- Firebase account
- Stripe account

## Setup

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/cloutmarket.git
cd cloutmarket
```

### 2. Firebase Setup

1. Create a new Firebase project at [firebase.google.com](https://firebase.google.com)
2. Add an iOS app to your Firebase project
3. Download the `GoogleService-Info.plist` file
4. Replace the placeholder file in the project with your downloaded file
5. Enable Authentication (Email/Password), Firestore, and Storage in the Firebase console

### 3. Stripe Setup

1. Create a Stripe account at [stripe.com](https://stripe.com)
2. Get your API keys from the Stripe Dashboard
3. Update the API keys in `StripeService.swift`

### 4. Install Dependencies

Open the project in Xcode and let SPM install the dependencies automatically.

### 5. Run the App

Build and run the app in Xcode using an iOS simulator or physical device.

## Backend API (Server-side)

For full functionality, CloutMarket requires a server-side component to handle:

- Stripe payment intent creation
- Secure handling of Stripe API keys
- Webhook processing for payment events
- Connecting Stripe accounts for payouts

A basic implementation would use Node.js with Express and the Stripe API.

## Mock Data

The app includes placeholder mock data for testing purposes. In a production environment, you would:

1. Remove mock implementations in the services
2. Connect to your Firebase and Stripe backends
3. Implement proper error handling and retry logic

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- [Firebase](https://firebase.google.com)
- [Stripe](https://stripe.com)
- [SwiftUI](https://developer.apple.com/xcode/swiftui/) 