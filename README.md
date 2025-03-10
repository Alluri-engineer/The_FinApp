# Finapp - Personal Finance Wallet iOS App

A modern personal finance wallet app built with SwiftUI and SwiftData.

## Features

- **Wallet Dashboard**: View your total balance, income, and expenses
- **Transaction Management**: Track your income and expenses with categories
- **Transaction History**: View recent transactions and transaction details
- **Modern UI**: Dark-themed interface with smooth animations and transitions

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Installation

1. Clone the repository
2. Open `Finapp.xcodeproj` in Xcode
3. Build and run the app on your device or simulator

## Architecture

The app uses:
- **SwiftUI** for the user interface
- **SwiftData** for local data persistence
- **MVVM** architecture pattern

## Models

- **Wallet**: Represents the user's wallet with balance, income, and expenses
- **Transaction**: Represents a financial transaction with amount, category, type, and date

## Views

- **WalletView**: Main dashboard showing wallet balance, income, and expenses
- **AddTransactionView**: View for adding new income or expense transactions

## Components

- **TransactionCard**: Reusable component for displaying transactions
- **PrimaryButton**: Reusable button component with different styles

## Styling

The app uses a consistent dark theme with:
- Black backgrounds
- White text
- Purple accent colors
- Custom rounded corners and shadows

## License

This project is available under the MIT license. 