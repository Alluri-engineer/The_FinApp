# Finapp - Personal Finance Wallet iOS App

A modern personal finance wallet app built with SwiftUI and SwiftData.
<img width="468" alt="Screenshot 2025-03-31 at 4 18 34 AM" src="https://github.com/user-attachments/assets/4b18c333-010a-4343-8945-50eff500f63e" />

<img width="468" alt="Screenshot 2025-03-31 at 4 18 41 AM" src="https://github.com/user-attachments/assets/670804fc-ab03-47f6-bc21-660084e73be3" />
<img width="304" alt="Screenshot 2025-03-31 at 4 22 51 AM" src="https://github.com/user-attachments/assets/f80a4be2-f5d0-4c75-8606-321d64bb9db3" />
<img width="506" alt="Screenshot 2025-03-31 at 4 23 36 AM" src="https://github.com/user-attachments/assets/ff808f99-ebb2-40e7-a71e-42d3e081facb" />
<img width="500" alt="Screenshot 2025-03-31 at 4 23 45 AM" src="https://github.com/user-attachments/assets/4a3b7292-773f-4642-af52-220e41a8b40b" />
<img width="497" alt="Screenshot 2025-03-31 at 4 23 52 AM" src="https://github.com/user-attachments/assets/5ab53ced-5dc7-431a-8bc6-9b5ab9e93cbe" />


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
