## FakeLife Xcode Project Setup

To run the FakeLife app, follow these steps:

1. Open Xcode and create a new iOS app project:
   - Choose "App" template
   - Name it "FakeLife"
   - Use SwiftUI for the interface
   - Choose your desired team and bundle identifier

2. Once created, import the Swift files from the repository:
   - Copy these directories into your new project:
     - FakeLife/Models/
     - FakeLife/ViewModels/
     - FakeLife/Views/
     - FakeLife/Services/
   - Copy FakeLife/FakeLifeApp.swift to your project

3. Add Firebase and Stripe SDKs using Swift Package Manager:
   - Go to File > Add Packages
   - Add https://github.com/firebase/firebase-ios-sdk.git
     - Select FirebaseAuth, FirebaseFirestore, and FirebaseStorage products
   - Add https://github.com/stripe/stripe-ios.git
     - Select Stripe and StripePaymentSheet products

4. Set up Firebase:
   - Create a Firebase project at firebase.google.com
   - Register your iOS app in the Firebase console
   - Download GoogleService-Info.plist and add it to your project
   - Enable Authentication, Firestore, and Storage in the Firebase console

5. Run the app!

Note: The app includes mock implementations for Firebase and Stripe services, so you can test functionality without setting up real backend services. 