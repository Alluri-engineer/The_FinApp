import Foundation
import SwiftData

enum TransactionCategory: String, Codable {
    case salary = "Salary"
    case investment = "Investment"
    case gift = "Gift"
    case food = "Food"
    case transportation = "Transportation"
    case entertainment = "Entertainment"
    case utilities = "Utilities"
    case rent = "Rent"
    case shopping = "Shopping"
    case health = "Health"
    case education = "Education"
    case other = "Other"
}

enum TransactionType: String, Codable {
    case income = "Income"
    case expense = "Expense"
}

enum CardType: String, Codable {
    case debit = "DEBIT"
    case credit = "CREDIT"
}

@Model
final class Transaction {
    @Attribute(.unique) var id: UUID
    var amount: Double
    var date: Date
    var category: String
    var type: String
    var note: String
    
    // Inverse relationship to Wallet
    @Relationship(inverse: \Wallet.transactions) var wallet: Wallet?
    
    init(amount: Double, category: String, type: String, note: String = "") {
        self.id = UUID()
        self.amount = amount
        self.date = Date()
        self.category = category
        self.type = type
        self.note = note
        self.wallet = nil
    }
    
    init(amount: Double, date: Date, category: String, type: String, note: String = "") {
        self.id = UUID()
        self.amount = amount
        self.date = date
        self.category = category
        self.type = type
        self.note = note
        self.wallet = nil
    }
}

@Model
final class Wallet {
    @Attribute(.unique) var id: UUID
    var balance: Double
    var currency: String
    var name: String
    var cardType: String
    
    @Relationship(deleteRule: .cascade) var transactions: [Transaction] = []
    var totalIncome: Double
    var totalExpenses: Double
    
    init(balance: Double = 40278.00, 
         currency: String = "$", 
         name: String = "Puja Santosh Wallet",
         transactions: [Transaction] = [], 
         totalIncome: Double = 52700, 
         totalExpenses: Double = 12422,
         cardType: String = CardType.debit.rawValue) {
        self.id = UUID()
        self.balance = balance
        self.currency = currency
        self.name = name
        self.transactions = transactions
        self.totalIncome = totalIncome
        self.totalExpenses = totalExpenses
        self.cardType = cardType
        
        // Set the inverse relationship
        for transaction in transactions {
            transaction.wallet = self
        }
    }
    
    func addTransaction(_ transaction: Transaction) {
        transactions.append(transaction)
        transaction.wallet = self
        
        // Update totals based on transaction type
        if transaction.type == TransactionType.income.rawValue {
            totalIncome += transaction.amount
            balance += transaction.amount
        } else if transaction.type == TransactionType.expense.rawValue {
            totalExpenses += transaction.amount
            balance -= transaction.amount
        }
    }
    
    // Get recent transactions, sorted by date
    func recentTransactions(limit: Int = 10) -> [Transaction] {
        return transactions
            .sorted(by: { $0.date > $1.date })
            .prefix(limit)
            .map { $0 }
    }
    
    // Get income transactions
    func incomeTransactions() -> [Transaction] {
        return transactions.filter { $0.type == TransactionType.income.rawValue }
    }
    
    // Get expense transactions
    func expenseTransactions() -> [Transaction] {
        return transactions.filter { $0.type == TransactionType.expense.rawValue }
    }
} 