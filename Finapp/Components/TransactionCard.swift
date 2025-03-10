import SwiftUI

struct TransactionCard: View {
    let amount: Double
    let category: String
    let date: Date
    let type: String
    let note: String
    var currency: String = "$"  // Default currency symbol
    
    private var isIncome: Bool {
        return type == TransactionType.income.rawValue
    }
    
    private var amountColor: Color {
        return isIncome ? Color.green : Color.red
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Transaction Info - Now with more space since icon is removed
            VStack(alignment: .leading, spacing: 4) {
                Text(category)
                    .font(.headline)
                    .foregroundColor(AppTheme.primaryTextColor)
                
                if !note.isEmpty {
                    Text(note)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.secondaryTextColor)
                        .lineLimit(1)
                }
                
                Text(formattedDate)
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryTextColor)
            }
            
            Spacer()
            
            // Amount
            Text("\(isIncome ? "+" : "-")\(currency)\(String(format: "%.2f", amount))")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(amountColor)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(AppTheme.cardBackgroundColor)
        .cornerRadius(AppTheme.cornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    VStack {
        TransactionCard(
            amount: 1500.00,
            category: "Salary",
            date: Date(),
            type: TransactionType.income.rawValue,
            note: "Monthly salary"
        )
        
        TransactionCard(
            amount: 45.75,
            category: "Shopping",
            date: Date().addingTimeInterval(-86400),
            type: TransactionType.expense.rawValue,
            note: "Grocery shopping"
        )
        
        TransactionCard(
            amount: 200.00,
            category: "Other Expense",
            date: Date().addingTimeInterval(-172800),
            type: TransactionType.expense.rawValue,
            note: "Coffee with friends"
        )
        
        TransactionCard(
            amount: 350.00,
            category: "Other Income",
            date: Date().addingTimeInterval(-259200),
            type: TransactionType.income.rawValue,
            note: "Performance bonus"
        )
    }
    .padding()
    .background(AppTheme.backgroundColor)
} 