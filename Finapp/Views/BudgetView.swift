import SwiftUI
import SwiftData

// Budget model remains a simple struct since we'll compute 'spent' dynamically
struct Budget: Identifiable {
    let id = UUID()
    var category: String
    var allocated: Double // Monthly allocated amount
    var spent: Double = 0 // Placeholder, will be computed dynamically
}

extension String {
    static var expense: String { return "expense" }
    static var income: String { return "income" }
}

struct BudgetView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var wallets: [Wallet]
    @State private var budgets: [Budget] = []
    @State private var showingAddBudget = false
    @State private var selectedTimeFrame: TimeFrame = .month
    @State private var monthlySavingGoal: Double = 0
    @State private var showingSetSavingGoal = false

    enum TimeFrame: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
    }

    // MARK: - Computed Properties

    private var allTransactions: [Transaction] {
        wallets.flatMap { $0.transactions }
    }

    // Filter transactions by selected time frame
    private func isTransactionInTimeFrame(_ transaction: Transaction, timeFrame: TimeFrame) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        switch timeFrame {
        case .week:
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!
            return transaction.date >= weekStart && transaction.date < weekEnd
        case .month:
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart)!
            return transaction.date >= monthStart && transaction.date < monthEnd
        case .year:
            let yearStart = calendar.date(from: calendar.dateComponents([.year], from: now))!
            let yearEnd = calendar.date(byAdding: .year, value: 1, to: yearStart)!
            return transaction.date >= yearStart && transaction.date < yearEnd
        }
    }

    // Calculate spent amount per category
    private var categorySpent: [String: Double] {
        var spentByCategory: [String: Double] = [:]
        let filteredTransactions = allTransactions.filter { isTransactionInTimeFrame($0, timeFrame: selectedTimeFrame) }
        for transaction in filteredTransactions {
            if transaction.type == "expense" {
                spentByCategory[transaction.category, default: 0] += transaction.amount
            }
        }
        return spentByCategory
    }

    // Total budget (sum of adjusted allocated amounts)
    private var totalBudget: Double {
        budgets.map { adjustedAllocated(for: $0, timeFrame: selectedTimeFrame) }.reduce(0, +)
    }

    // Total spent (sum of spent amounts in budgeted categories)
    private var totalSpent: Double {
        budgets.map { categorySpent[$0.category] ?? 0 }.reduce(0, +)
    }

    // Calculate total income and expenses for savings
    private var totalIncome: Double {
        allTransactions.filter { isTransactionInTimeFrame($0, timeFrame: selectedTimeFrame) && $0.type == "income" }
            .map { $0.amount }.reduce(0, +)
    }

    private var totalExpenses: Double {
        allTransactions.filter { isTransactionInTimeFrame($0, timeFrame: selectedTimeFrame) && $0.type == "expense" }
            .map { $0.amount }.reduce(0, +)
    }

    private var currentSavings: Double {
        totalIncome - totalExpenses
    }

    // Adjust monthly allocated budget based on time frame
    private func adjustedAllocated(for budget: Budget, timeFrame: TimeFrame) -> Double {
        let monthlyAllocated = budget.allocated
        switch timeFrame {
        case .week:
            return monthlyAllocated / 4.0 // Approximate
        case .month:
            return monthlyAllocated
        case .year:
            return monthlyAllocated * 12.0
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Total Budget Card
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Total Budget")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Text("$\(String(format: "%.2f", totalBudget))")
                                .font(.system(size: 38))
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        ProgressBar(value: totalSpent, total: totalBudget, color: totalSpent > totalBudget ? .red : .blue)
                            .frame(height: 6)

                        HStack(spacing: 12) {
                            BudgetStatCard(title: "Spent", amount: totalSpent, color: .blue)
                            BudgetStatCard(title: "Remaining", amount: max(totalBudget - totalSpent, 0), color: .green)
                        }
                    }
                    .padding(16)
                    .background(Color(.systemGray6).opacity(0.7))
                    .cornerRadius(16)
                    .shadow(radius: 5)
                    .padding(.horizontal)

                    // Time Period Picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Time Period")
                            .font(.headline)
                            .foregroundColor(.white)
                        Picker("Time Frame", selection: $selectedTimeFrame) {
                            ForEach(TimeFrame.allCases, id: \.self) { timeFrame in
                                Text(timeFrame.rawValue).tag(timeFrame)
                            }
                        }
                        .pickerStyle(.segmented)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)

                    // Category Budgets
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Category Budgets")
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                            Button(action: { showingAddBudget = true }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus")
                                    Text("Add Budget")
                                }
                                .font(.subheadline.bold())
                                .foregroundColor(.blue)
                            }
                        }

                        if budgets.isEmpty {
                            EmptyBudgetView()
                        } else {
                            ForEach(budgets) { budget in
                                let spent = categorySpent[budget.category] ?? 0
                                let adjustedAllocated = adjustedAllocated(for: budget, timeFrame: selectedTimeFrame)
                                CategoryBudgetCard(category: budget.category, allocated: adjustedAllocated, spent: spent)
                            }
                        }
                    }
                    .padding(16)
                    .background(Color(.systemGray6).opacity(0.7))
                    .cornerRadius(16)
                    .shadow(radius: 5)
                    .padding(.horizontal)

                    // Saving Goal (only for month)
                    if selectedTimeFrame == .month {
                        SavingGoalCard(
                            monthlySavingGoal: monthlySavingGoal,
                            currentSavings: currentSavings,
                            onSetGoal: { showingSetSavingGoal = true }
                        )
                        .padding(.horizontal)
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .background(Color(.systemBackground))
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingAddBudget) {
                AddBudgetView(budgets: $budgets)
            }
            .sheet(isPresented: $showingSetSavingGoal) {
                SetSavingGoalView(monthlySavingGoal: $monthlySavingGoal)
            }
            .animation(.easeInOut, value: selectedTimeFrame) // Animate time frame changes
        }
    }
}

// MARK: - Supporting Views

struct BudgetStatCard: View {
    let title: String
    let amount: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Text("$\(String(format: "%.2f", amount))")
                .font(.headline)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.systemGray5))
        .cornerRadius(12)
    }
}

struct EmptyBudgetView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.pie")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            Text("No budgets set")
                .font(.headline)
                .foregroundColor(.gray)
            Text("Tap the + button to add a budget category")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray5))
        .cornerRadius(12)
    }
}

struct ProgressBar: View {
    let value: Double
    let total: Double
    let color: Color

    private var percentage: Double {
        guard total > 0 else { return 0 }
        return min((value / total) * 100, 100)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .cornerRadius(4)
                Rectangle()
                    .fill(color)
                    .frame(width: geometry.size.width * CGFloat(percentage / 100))
                    .cornerRadius(4)
            }
        }
    }
}

struct CategoryBudgetCard: View {
    let category: String
    let allocated: Double
    let spent: Double

    private var percentage: Double {
        guard allocated > 0 else { return 0 }
        return (spent / allocated) * 100
    }

    private var statusColor: Color {
        if percentage >= 100 { return .red }
        else if percentage >= 80 { return .orange }
        else { return .blue }
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(category)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("$\(String(format: "%.2f", spent)) / $\(String(format: "%.2f", allocated))")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
                CircularProgressView(percentage: percentage, color: statusColor)
                    .frame(width: 44, height: 44)
            }
            ProgressBar(value: spent, total: allocated, color: statusColor)
                .frame(height: 6)
            HStack {
                Label(
                    "Remaining: $\(String(format: "%.2f", max(allocated - spent, 0)))",
                    systemImage: "arrow.down.circle.fill"
                )
                .font(.caption)
                .foregroundColor(.gray)
                Spacer()
                Text("\(Int(percentage))%")
                    .font(.caption.bold())
                    .foregroundColor(statusColor)
            }
        }
        .padding()
        .background(Color(.systemGray5))
        .cornerRadius(12)
    }
}

struct CircularProgressView: View {
    let percentage: Double
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 4)
            Circle()
                .trim(from: 0, to: CGFloat(min(percentage / 100, 1)))
                .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: percentage)
            Text("\(Int(percentage))%")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(color)
        }
    }
}

struct SavingGoalCard: View {
    let monthlySavingGoal: Double
    let currentSavings: Double
    let onSetGoal: () -> Void

    private var percentage: Double {
        guard monthlySavingGoal > 0 else { return 0 }
        return (currentSavings / monthlySavingGoal) * 100
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Monthly Saving Goal")
                        .font(.headline)
                        .foregroundColor(.white)
                    if monthlySavingGoal > 0 {
                        Text("$\(String(format: "%.2f", currentSavings)) / $\(String(format: "%.2f", monthlySavingGoal))")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    } else {
                        Text("Set a goal to track your savings")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                Spacer()
                if monthlySavingGoal > 0 {
                    CircularProgressView(percentage: percentage, color: .green)
                        .frame(width: 44, height: 44)
                }
            }
            if monthlySavingGoal > 0 {
                ProgressBar(value: currentSavings, total: monthlySavingGoal, color: .green)
                    .frame(height: 6)
                HStack {
                    Label(
                        "Remaining: $\(String(format: "%.2f", max(monthlySavingGoal - currentSavings, 0)))",
                        systemImage: "arrow.down.circle.fill"
                    )
                    .font(.caption)
                    .foregroundColor(.gray)
                    Spacer()
                    Text("\(Int(percentage))%")
                        .font(.caption.bold())
                        .foregroundColor(.green)
                }
                // Unique Twist: Congratulatory Message
                if currentSavings >= monthlySavingGoal {
                    Text("🎉 Goal Achieved! Great job saving!")
                        .font(.subheadline)
                        .foregroundColor(.green)
                        .transition(.opacity)
                }
            }
            Button(action: onSetGoal) {
                Text(monthlySavingGoal > 0 ? "Edit Goal" : "Set Goal")
                    .font(.subheadline.bold())
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemGray5))
        .cornerRadius(12)
        .shadow(radius: 5)
    }
}

struct AddBudgetView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var budgets: [Budget]
    @State private var category = ""
    @State private var amount = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Category Name", text: $category)
                    TextField("Monthly Budget Amount", text: $amount)
                        .keyboardType(.decimalPad)
                } header: {
                    Text("Budget Details")
                } footer: {
                    Text("Set a monthly budget amount for this category")
                }
            }
            .navigationTitle("New Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if let amount = Double(amount), !category.isEmpty {
                            budgets.append(Budget(category: category, allocated: amount))
                            dismiss()
                        }
                    }
                    .disabled(category.isEmpty || amount.isEmpty)
                }
            }
        }
    }
}

struct SetSavingGoalView: View {
    @Binding var monthlySavingGoal: Double
    @State private var goalAmount = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Monthly Saving Goal", text: $goalAmount)
                        .keyboardType(.decimalPad)
                } header: {
                    Text("Set your monthly saving goal")
                }
            }
            .navigationTitle("Saving Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let amount = Double(goalAmount) {
                            monthlySavingGoal = amount
                            dismiss()
                        }
                    }
                    .disabled(goalAmount.isEmpty)
                }
            }
        }
    }
}

#Preview {
    BudgetView()
        .modelContainer(for: [Wallet.self, Transaction.self], inMemory: true)
}