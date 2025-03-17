////
////  HomeView.swift
////  Finapp
////
////  Created by Sashank Singh on 10/03/25.
////
//
//import Foundation
//import SwiftUI
//import SwiftData
//
//struct HomeView: View {
//    @Environment(\.modelContext) private var modelContext
//    @Query private var wallets: [Wallet]
//
//    var body: some View {
//        NavigationStack {
//            VStack(spacing: 20) {
//                if wallets.isEmpty {
//                    Text("No wallets available")
//                        .foregroundColor(AppTheme.secondaryTextColor)
//                        .padding()
//                } else {
//                    VStack(spacing: 10) {
//                        Text("Total Balance")
//                            .font(.headline)
//                            .foregroundColor(AppTheme.secondaryTextColor)
//                        Text("$\(String(format: "%.2f", wallets.reduce(0.0) { $0 + $1.balance }))")
//                            .font(.title)
//                            .fontWeight(.bold)
//                            .foregroundColor(.white)
//                        
//                        HStack(spacing: 20) {
//                            VStack {
//                                Text("Total Income")
//                                    .font(.subheadline)
//                                    .foregroundColor(AppTheme.secondaryTextColor)
//                                Text("$\(String(format: "%.2f", wallets.reduce(0.0) { $0 + $1.totalIncome }))")
//                                    .font(.title2)
//                                    .foregroundColor(.green)
//                            }
//                            VStack {
//                                Text("Total Expenses")
//                                    .font(.subheadline)
//                                    .foregroundColor(AppTheme.secondaryTextColor)
//                                Text("$\(String(format: "%.2f", wallets.reduce(0.0) { $0 + $1.totalExpenses }))")
//                                    .font(.title2)
//                                    .foregroundColor(.red)
//                            }
//                        }
//                        .padding(.top, 10)
//                    }
//                    .padding()
//                    .background(AppTheme.cardBackgroundColor)
//                    .cornerRadius(AppTheme.cornerRadius)
//                    .padding(.horizontal)
//                }
//            }
//            .frame(maxWidth: .infinity, maxHeight: .infinity)
//            .background(AppTheme.backgroundColor.ignoresSafeArea())
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .principal) {
//                    Text("Home")
//                        .font(.system(size: 24, weight: .black))
//                        .foregroundColor(.white)
//                }
//            }
//        }
//    }
//}
//
//#Preview {
//    HomeView()
//        .modelContainer(for: [Wallet.self, Transaction.self], inMemory: true)
//}
import SwiftUI
import SwiftData

// Move InsightsData enum to the top level (outside of any struct)
enum InsightsData: CaseIterable, Identifiable {
    case income, expenses, transactions, dailyAverage
    
    var id: String { title }
    
    var icon: String {
        switch self {
        case .income: "arrow.up.circle.fill"
        case .expenses: "arrow.down.circle.fill"
        case .transactions: "dollarsign.circle.fill"
        case .dailyAverage: "chart.pie.fill"
        }
    }
    
    var title: String {
        switch self {
        case .income: "Income"
        case .expenses: "Expenses"
        case .transactions: "Transactions"
        case .dailyAverage: "Avg. Daily"
        }
    }
    
    var color: Color {
        switch self {
        case .income: .green
        case .expenses: .red
        case .transactions: .blue
        case .dailyAverage: .orange
        }
    }
    
    func value(wallets: [Wallet], transactions: [Transaction]) -> Double {
        switch self {
        case .income: 
            return wallets.totalIncome
        case .expenses: 
            return wallets.totalExpenses
        case .transactions:
            // Count incoming (positive) and outgoing (negative) transactions
            let incomingCount = transactions.filter { $0.type == TransactionType.income.rawValue }.count
            let outgoingCount = transactions.filter { $0.type == TransactionType.expense.rawValue }.count
            // Return total count for display
            return Double(incomingCount + outgoingCount)
        case .dailyAverage: 
            return wallets.averageDailySpending
        }
    }
    
    func transactionCounts(transactions: [Transaction]) -> (incoming: Int, outgoing: Int)? {
        guard self == .transactions else { return nil }
        let incomingCount = transactions.filter { $0.type == TransactionType.income.rawValue }.count
        let outgoingCount = transactions.filter { $0.type == TransactionType.expense.rawValue }.count
        return (incoming: incomingCount, outgoing: outgoingCount)
    }
}

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var wallets: [Wallet]
    @State private var selectedTimeFrame: TimeFrame = .month
    
    enum TimeFrame: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
    }
    
    // Computed properties
    private var totalBalance: Double {
        wallets.reduce(0.0) { $0 + $1.balance }
    }
    
    private var allTransactions: [Transaction] {
        wallets.flatMap { $0.transactions }.sorted(by: { $0.date > $1.date })
    }
    
    private var spendingRatio: Double {
        let totalIncome = wallets.reduce(0.0) { $0 + $1.totalIncome }
        let totalExpenses = wallets.reduce(0.0) { $0 + $1.totalExpenses }
        return totalExpenses / max(totalIncome, 1)
    }
    
    private var categoryBreakdown: [(String, Double)] {
        let expenses = allTransactions.filter { $0.type == TransactionType.expense.rawValue }
        var categoryTotals: [String: Double] = [:]
        
        expenses.forEach { transaction in
            categoryTotals[transaction.category, default: 0] += transaction.amount
        }
        
        return categoryTotals.sorted { $0.value > $1.value }
    }
    
    private var monthlySpending: [(String, Double)] {
        let calendar = Calendar.current
        let expenses = allTransactions.filter { $0.type == TransactionType.expense.rawValue }
        var monthlyTotals: [String: Double] = [:]
        
        expenses.forEach { transaction in
            let month = calendar.component(.month, from: transaction.date)
            let monthName = calendar.monthSymbols[month - 1]
            monthlyTotals[monthName, default: 0] += transaction.amount
        }
        
        return monthlyTotals.sorted { $0.0 < $1.0 }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    TotalAssetsCard(
                        totalBalance: totalBalance,
                        walletCount: wallets.count,
                        spendingRatio: spendingRatio
                    )
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    HStack(spacing: 12) {
                        NavigationLink(destination: AddWalletView { name, color in
                            let newWallet = Wallet(
                                balance: 0.0,
                                currency: "$",
                                name: name,
                                totalIncome: 0.0,
                                totalExpenses: 0.0
                            )
                            modelContext.insert(newWallet)
                        }) {
                            ActionButton(
                                icon: "plus.circle.fill",
                                label: "New Wallet",
                                color: .blue,
                                isPressed: .constant(false)
                            )
                        }
                        
                        NavigationLink(destination: MonthlyReportView(showAllWallets: true)) {
                            ActionButton(
                                icon: "chart.line.uptrend.xyaxis",
                                label: "Reports",
                                color: .purple,
                                isPressed: .constant(false)
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ],
                        spacing: 12
                    ) {
                        ForEach(InsightsData.allCases) { data in
                            InsightCard(
                                icon: data.icon,
                                title: data.title,
                                value: data.value(wallets: wallets, transactions: allTransactions),
                                color: data.color,
                                transactions: allTransactions,
                                insightType: data
                            )
                            .background(AppTheme.cardBackgroundColor)
                            .cornerRadius(16)
                        }
                    }
                    .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        HStack {
                            Text("Recent Activity")
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                            NavigationLink("See All") {
                                TransactionListView(
                                    title: "All Transactions",
                                    transactions: allTransactions,
                                    wallet: Wallet.defaultWallet
                                )
                            }
                            .foregroundColor(.blue)
                        }
                        
                        if !allTransactions.isEmpty {
                            ForEach(allTransactions.prefix(3)) { transaction in
                                TransactionCard(
                                    amount: transaction.amount,
                                    category: transaction.category,
                                    date: transaction.date,
                                    type: transaction.type,
                                    note: transaction.note,
                                    currency: "$"
                                )
                            }
                        } else {
                            Text("No recent transactions")
                                .foregroundColor(.gray)
                                .padding(.vertical, 20)
                        }
                    }
                    .padding()
                    .background(AppTheme.cardBackgroundColor)
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    // Analytics Section
                    VStack(spacing: 16) {
                        HStack {
                            Text("Analytics & Insights")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Spacer()
                            Picker("Time Frame", selection: $selectedTimeFrame) {
                                ForEach(TimeFrame.allCases, id: \.self) { timeFrame in
                                    Text(timeFrame.rawValue).tag(timeFrame)
                                }
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 200)
                        }
                        .padding(.horizontal)
                        
                        // Category Breakdown Chart
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Spending by Category")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            ForEach(categoryBreakdown.prefix(5), id: \.0) { category, amount in
                                CategoryProgressBar(
                                    category: category,
                                    amount: amount,
                                    total: categoryBreakdown.reduce(0) { $0 + $1.1 }
                                )
                            }
                        }
                        .padding()
                        .background(AppTheme.cardBackgroundColor)
                        .cornerRadius(16)
                        .padding(.horizontal)
                        
                        // Monthly Comparison Chart
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Monthly Spending Trend")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            HStack(alignment: .bottom, spacing: 8) {
                                ForEach(monthlySpending.suffix(6), id: \.0) { month, amount in
                                    MonthlyBarChart(
                                        month: month,
                                        amount: amount,
                                        maxAmount: monthlySpending.map { $0.1 }.max() ?? 0
                                    )
                                }
                            }
                            .frame(height: 200)
                        }
                        .padding()
                        .background(AppTheme.cardBackgroundColor)
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 100)
            }
            .padding(.top, 40)
            .background(AppTheme.backgroundColor)
            .navigationTitle("Financial Dashboard")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Subviews
struct TotalAssetsCard: View {
    let totalBalance: Double
    let walletCount: Int
    let spendingRatio: Double
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.8),
                        Color.blue.opacity(0.6)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            
            VStack(spacing: 16) {
                Text("TOTAL ASSETS")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                
                Text("$\(String(format: "%.2f", totalBalance))")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
                
                HStack(spacing: 12) {
                    InsightPill(
                        title: "WALLETS",
                        value: "\(walletCount)",
                        icon: "creditcard.fill",
                        color: .green
                    )
                    
                    InsightPill(
                        title: "SPENDING RATIO",
                        value: "\(Int(spendingRatio * 100))%",
                        icon: spendingRatio > 0.5 ? "exclamationmark.triangle.fill" : "chart.bar.fill",
                        color: spendingRatio > 0.5 ? .red : .green
                    )
                }
            }
            .padding(24)
        }
        .frame(height: 180)
    }
}

struct ActionButtonsSection: View {
    let modelContext: ModelContext
    
    var body: some View {
        HStack(spacing: 16) {
            NavigationLink(destination: AddWalletView { name, color in
                let newWallet = Wallet(
                    balance: 0.0,
                    currency: "$",
                    name: name,
                    totalIncome: 0.0,
                    totalExpenses: 0.0
                )
                modelContext.insert(newWallet)
            }) {
                ActionButton(
                    icon: "plus.circle.fill",
                    label: "New Wallet",
                    color: .blue,
                    isPressed: .constant(false)
                )
            }
            
            NavigationLink(destination: MonthlyReportView(showAllWallets: true)) {
                ActionButton(
                    icon: "chart.line.uptrend.xyaxis",
                    label: "Reports",
                    color: .purple,
                    isPressed: .constant(false)
                )
            }
        }
        .padding(.horizontal)
    }
}

struct InsightsGrid: View {
    let wallets: [Wallet]
    let allTransactions: [Transaction]
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ForEach(InsightsData.allCases) { data in
                InsightCard(
                    icon: data.icon,
                    title: data.title,
                    value: data.value(wallets: wallets, transactions: allTransactions),
                    color: data.color,
                    transactions: allTransactions,
                    insightType: data
                )
                .background(AppTheme.cardBackgroundColor)
                .cornerRadius(AppTheme.cornerRadius)
            }
        }
        .padding(.horizontal)
    }
}

struct RecentActivitySection: View {
    let transactions: [Transaction]
    
    var body: some View {
        VStack(spacing: 16) {
            headerSection
            Divider().background(AppTheme.secondaryTextColor)
            transactionsList
        }
        .padding()
        .background(AppTheme.cardBackgroundColor)
        .cornerRadius(AppTheme.cornerRadius)
        .padding(.horizontal)
    }
    
    private var headerSection: some View {
        HStack {
            Text("Recent Activity")
                .font(.headline)
                .foregroundColor(AppTheme.primaryTextColor)
            Spacer()
            NavigationLink("See All") {
                TransactionListView(
                    title: "All Transactions",
                    transactions: transactions,
                    wallet: Wallet.defaultWallet
                )
            }
            .font(.subheadline)
            .foregroundColor(.blue)
        }
    }
    
    private var transactionsList: some View {
        ForEach(transactions.prefix(3)) { transaction in
            TransactionCard(
                amount: transaction.amount,
                category: transaction.category,
                date: transaction.date,
                type: transaction.type,
                note: transaction.note,
                currency: "$"
            )
            .padding(.horizontal, 8)
        }
    }
}

// MARK: - Helper Extensions
extension Array where Element == Wallet {
    var totalIncome: Double { reduce(0.0) { $0 + $1.totalIncome } }
    var totalExpenses: Double { reduce(0.0) { $0 + $1.totalExpenses } }
    
    var averageDailySpending: Double {
        guard !isEmpty else { return 0 }
        let days = Double(Calendar.current.numberOfDaysBetween(
            from: first?.transactions.first?.date ?? Date(),
            to: Date()
        ))
        return totalExpenses / Swift.max(days, 1)
    }
}

extension Wallet {
    static var defaultWallet: Wallet {
        Wallet(
            balance: 0.0,
            currency: "$",
            name: "Default",
            totalIncome: 0.0,
            totalExpenses: 0.0
        )
    }
}

// MARK: - Components
struct InsightPill: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(color.opacity(0.8))
                Text(value)
                    .font(.system(size: 14, weight: .black))
                    .foregroundColor(color)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct ActionButton: View {
    let icon: String
    let label: String
    let color: Color
    @Binding var isPressed: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16))
            Text(label)
                .font(.system(size: 16, weight: .bold))
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(buttonBackground)
        .overlay(buttonBorder)
        .shadow(color: color.opacity(0.3), radius: 5, x: 0, y: 2)
        .scaleEffect(isPressed ? 0.95 : 1.0)
    }
    
    private var buttonBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30)
                .fill(color.opacity(0.3))
                .blur(radius: 8)
            RoundedRectangle(cornerRadius: 30)
                .fill(LinearGradient(
                    gradient: Gradient(colors: [color.opacity(0.7), color.opacity(0.5)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
        }
    }
    
    private var buttonBorder: some View {
        RoundedRectangle(cornerRadius: 30)
            .stroke(color.opacity(0.3), lineWidth: 1)
    }
}

struct InsightCard: View {
    let icon: String
    let title: String
    let value: Double
    let color: Color
    let transactions: [Transaction]
    let insightType: InsightsData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 18))
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            if title == "Transactions", let counts = insightType.transactionCounts(transactions: transactions) {
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up")
                            .foregroundColor(.red)
                        Text("\(counts.outgoing)")
                            .foregroundColor(.red)
                            .font(.system(size: 20, weight: .bold))
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down")
                            .foregroundColor(.green)
                        Text("\(counts.incoming)")
                            .foregroundColor(.green)
                            .font(.system(size: 20, weight: .bold))
                    }
                }
            } else {
                Text("$\(String(format: "%.2f", value))")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
    }
}

extension Calendar {
    func numberOfDaysBetween(from: Date, to: Date) -> Int {
        let fromDate = startOfDay(for: from)
        let toDate = startOfDay(for: to)
        let components = dateComponents([.day], from: fromDate, to: toDate)
        return abs(components.day ?? 0)
    }
}

struct CategoryProgressBar: View {
    let category: String
    let amount: Double
    let total: Double
    
    private var percentage: Double {
        (amount / total) * 100
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(category)
                    .font(.subheadline)
                    .foregroundColor(.white)
                Spacer()
                Text("$\(String(format: "%.2f", amount))")
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: geometry.size.width * CGFloat(percentage / 100), height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
        }
    }
}

struct MonthlyBarChart: View {
    let month: String
    let amount: Double
    let maxAmount: Double
    
    private var heightPercentage: CGFloat {
        CGFloat(amount / maxAmount)
    }
    
    var body: some View {
        VStack {
            ZStack(alignment: .bottom) {
                Rectangle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [.blue.opacity(0.7), .purple.opacity(0.7)]),
                        startPoint: .bottom,
                        endPoint: .top
                    ))
                    .frame(width: 30, height: 160 * heightPercentage)
                    .cornerRadius(8)
            }
            .frame(height: 160)
            
            Text(month.prefix(3))
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

// MARK: - Preview
#Preview {
    HomeView()
        .modelContainer(for: [Wallet.self, Transaction.self], inMemory: true)
}
