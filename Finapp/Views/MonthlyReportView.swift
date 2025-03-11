import SwiftUI
import SwiftData

struct MonthlyReportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Query private var allWallets: [Wallet]
    
    let showAllWallets: Bool
    var selectedWallet: Wallet?
    
    private var title: String {
        showAllWallets ? "All Accounts Report" : selectedWallet?.name ?? "Account Report"
    }
    
    init(showAllWallets: Bool = false, selectedWallet: Wallet? = nil) {
        self.showAllWallets = showAllWallets
        self.selectedWallet = selectedWallet
    }
    
    // Update to use either selected wallet or all wallets
    private var walletsToShow: [Wallet] {
        if showAllWallets {
            return allWallets
        } else if let wallet = selectedWallet {
            return [wallet]
        }
        return []
    }
    
    @State private var animateChart: Bool = false
    @State private var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var currentPage: Int = 0
    @State private var showIncomeDetails: Bool = false
    @State private var showExpenseDetails: Bool = false
    
    // Get the current month and year
    private let currentMonth = Calendar.current.component(.month, from: Date())
    private let currentYear = Calendar.current.component(.year, from: Date())
    
    // Number of months to show per page
    private let monthsPerPage = 4
    
    // Total number of months to track (current + 6 previous)
    private let totalMonthsToTrack = 7
    
    // Get month name
    private func monthName(month: Int) -> String {
        let dateFormatter = DateFormatter()
        return dateFormatter.monthSymbols[month - 1]
    }
    
    // Get short month name
    private func shortMonthName(month: Int) -> String {
        let dateFormatter = DateFormatter()
        return dateFormatter.shortMonthSymbols[month - 1]
    }
    
    // Generate monthly data for the selected month and year
    private func monthlyData(month: Int, year: Int) -> (income: Double, expense: Double) {
        var totalIncome: Double = 0
        var totalExpense: Double = 0
        
        let calendar = Calendar.current
        
        var startComponents = DateComponents()
        startComponents.year = year
        startComponents.month = month
        startComponents.day = 1
        
        var endComponents = DateComponents()
        endComponents.year = year
        endComponents.month = month + 1
        endComponents.day = 0
        
        guard let startDate = calendar.date(from: startComponents),
              let endDate = calendar.date(from: endComponents) else {
            return (0, 0)
        }
        
        for wallet in walletsToShow {
            for transaction in wallet.transactions {
                if transaction.date >= startDate && transaction.date <= endDate {
                    if transaction.type == TransactionType.income.rawValue {
                        totalIncome += transaction.amount
                    } else if transaction.type == TransactionType.expense.rawValue {
                        totalExpense += transaction.amount
                    }
                }
            }
        }
        
        return (income: totalIncome, expense: totalExpense)
    }
    
    // Generate data for all months to display
    private var allMonthsData: [(month: Int, year: Int, income: Double, expense: Double)] {
        var data: [(month: Int, year: Int, income: Double, expense: Double)] = []
        
        // Start from current month and go back totalMonthsToTrack months
        var currentComponents = DateComponents()
        currentComponents.year = currentYear
        currentComponents.month = currentMonth
        
        guard let currentDate = Calendar.current.date(from: currentComponents) else {
            return data
        }
        
        for i in 0..<totalMonthsToTrack {
            guard let date = Calendar.current.date(byAdding: .month, value: -i, to: currentDate) else {
                continue
            }
            
            let month = Calendar.current.component(.month, from: date)
            let year = Calendar.current.component(.year, from: date)
            let monthData = monthlyData(month: month, year: year)
            
            data.append((month: month, year: year, income: monthData.income, expense: monthData.expense))
        }
        
        // Don't reverse the array - we want current month first (at index 0)
        return data
    }
    
    // Get visible months based on current page
    private var visibleMonths: [(month: Int, year: Int, income: Double, expense: Double)] {
        let startIndex = currentPage * monthsPerPage
        let endIndex = min(startIndex + monthsPerPage, allMonthsData.count)
        
        if startIndex >= allMonthsData.count {
            return []
        }
        
        return Array(allMonthsData[startIndex..<endIndex])
    }
    
    // Find maximum value for scaling the chart
    private var maxValue: Double {
        let maxIncome = visibleMonths.map { $0.income }.max() ?? 0
        let maxExpense = visibleMonths.map { $0.expense }.max() ?? 0
        return max(maxIncome, maxExpense, 1) // Ensure we don't divide by zero
    }
    
    // Get transactions for the selected month
    private var selectedMonthTransactions: [Transaction] {
        let calendar = Calendar.current
        
        var startComponents = DateComponents()
        startComponents.year = selectedYear
        startComponents.month = selectedMonth
        startComponents.day = 1
        
        var endComponents = DateComponents()
        endComponents.year = selectedYear
        endComponents.month = selectedMonth + 1
        endComponents.day = 0
        
        guard let startDate = calendar.date(from: startComponents),
              let endDate = calendar.date(from: endComponents) else {
            return []
        }
        
        let allTransactions = walletsToShow.flatMap { wallet in
            wallet.transactions.filter { transaction in
                transaction.date >= startDate && transaction.date <= endDate
            }
        }
        
        return allTransactions.sorted(by: { $0.date > $1.date })
    }
    
    // Get data for the selected month
    private var selectedMonthData: (income: Double, expense: Double, balance: Double) {
        let data = monthlyData(month: selectedMonth, year: selectedYear)
        return (income: data.income, expense: data.expense, balance: data.income - data.expense)
    }
    
    // Calculate total pages
    private var totalPages: Int {
        return (allMonthsData.count + monthsPerPage - 1) / monthsPerPage
    }
    
    // Get income transactions for the selected month
    private var selectedMonthIncomeTransactions: [Transaction] {
        return selectedMonthTransactions.filter { $0.type == TransactionType.income.rawValue }
    }
    
    // Get expense transactions for the selected month
    private var selectedMonthExpenseTransactions: [Transaction] {
        return selectedMonthTransactions.filter { $0.type == TransactionType.expense.rawValue }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Monthly Balance Card
                VStack(spacing: 16) {
                    Text("Monthly Balance")
                        .font(.headline)
                        .foregroundColor(.white)
                        .opacity(0.9)
                    
                    Text("\(walletsToShow[0].currency)\(String(format: "%.2f", selectedMonthData.balance))")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(selectedMonthData.balance >= 0 ? .green : .red)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
                .padding(.horizontal)
                .padding(.top, 16)
                
                // Income & Expenses Cards
                HStack(spacing: 16) {
                    // Income Card
                    Button(action: {
                        showIncomeDetails = true
                    }) {
                        VStack(spacing: 8) {
                            Text("Income")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                
                            Text("\(walletsToShow[0].currency)\(String(format: "%.2f", selectedMonthData.income))")
                                .font(.title2)
                                .foregroundColor(.green)
                                
                            Image(systemName: "arrow.up.circle.fill")
                                .foregroundColor(.green)
                                .font(.title2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(16)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    // Expenses Card
                    Button(action: {
                        showExpenseDetails = true
                    }) {
                        VStack(spacing: 8) {
                            Text("Expenses")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                
                            Text("\(walletsToShow[0].currency)\(String(format: "%.2f", selectedMonthData.expense))")
                                .font(.title2)
                                .foregroundColor(.red)
                                
                            Image(systemName: "arrow.down.circle.fill")
                                .foregroundColor(.red)
                                .font(.title2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(16)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                
                // Monthly Overview Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Monthly Overview")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    
                    // Monthly Chart
                    modernCard {
                        VStack(spacing: 16) {
                            HStack {
                                Text("Monthly Overview")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                // Page indicator
                                if totalPages > 1 {
                                    HStack(spacing: 4) {
                                        ForEach(0..<totalPages, id: \.self) { page in
                                            Circle()
                                                .fill(page == currentPage ? Color.white : Color.gray.opacity(0.3))
                                                .frame(width: 8, height: 8)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 16)
                            
                            // Chart Legend
                            HStack(spacing: 16) {
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(Color.green.opacity(0.7))
                                        .frame(width: 8, height: 8)
                                    
                                    Text("Income")
                                        .font(.caption)
                                        .foregroundColor(Color.gray.opacity(0.8))
                                }
                                
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(Color.red.opacity(0.7))
                                        .frame(width: 8, height: 8)
                                    
                                    Text("Expense")
                                        .font(.caption)
                                        .foregroundColor(Color.gray.opacity(0.8))
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.horizontal)
                            
                            // Chart
                            TabView(selection: $currentPage) {
                                ForEach(0..<totalPages, id: \.self) { page in
                                    modernChartView(for: page)
                                        .tag(page)
                                }
                            }
                            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                            .frame(height: 400)
                            .onChange(of: currentPage) { _, _ in
                                // Reset animation when changing page
                                animateChart = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    animateChart = true
                                }
                            }
                        }
                        .padding(.bottom, 16)
                    }
                    .padding(.horizontal)
                }
                
                Spacer(minLength: 40)
            }
        }
        .background(AppTheme.backgroundColor.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Empty toolbar to override any existing items
        }
        .sheet(isPresented: $showIncomeDetails) {
            TransactionListView(
                title: "Income Details",
                transactions: selectedMonthIncomeTransactions,
                wallet: walletsToShow[0]
            )
        }
        .sheet(isPresented: $showExpenseDetails) {
            TransactionListView(
                title: "Expense Details",
                transactions: selectedMonthExpenseTransactions,
                wallet: walletsToShow[0]
            )
        }
        .onAppear {
            // Start chart animation after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                animateChart = true
            }
        }
    }
    
    // Modern chart view for a specific page
    private func modernChartView(for page: Int) -> some View {
        let pageData = getPageData(for: page)
        
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 24) {
                ForEach(pageData.indices, id: \.self) { index in
                    let data = pageData[index]
                    let isSelected = data.month == selectedMonth && data.year == selectedYear
                    
                    MonthlyDataCard(
                        data: data,
                        isSelected: isSelected,
                        animateChart: animateChart,
                        maxValue: maxValue,
                        index: index,
                        wallet: walletsToShow[0],
                        onTap: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedMonth = data.month
                                selectedYear = data.year
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            // Align to leading (left) to ensure current month is visible first
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // Get data for a specific page
    private func getPageData(for page: Int) -> [(month: Int, year: Int, income: Double, expense: Double)] {
        let startIndex = page * monthsPerPage
        let endIndex = min(startIndex + monthsPerPage, allMonthsData.count)
        
        if startIndex >= allMonthsData.count {
            return []
        }
        
        return Array(allMonthsData[startIndex..<endIndex])
    }
    
    // Modern card view
    private func modernCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.5), radius: 10, x: 0, y: 5)
            )
    }
}

// Monthly data card component
struct MonthlyDataCard: View {
    let data: (month: Int, year: Int, income: Double, expense: Double)
    let isSelected: Bool
    let animateChart: Bool
    let maxValue: Double
    let index: Int
    let wallet: Wallet
    let onTap: () -> Void
    
    private func shortMonthName(month: Int) -> String {
        let dateFormatter = DateFormatter()
        return dateFormatter.shortMonthSymbols[month - 1]
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Month label
            Text(shortMonthName(month: data.month))
                .font(.system(size: 16, weight: isSelected ? .bold : .regular))
                .foregroundColor(isSelected ? .white : .gray)
            
            // Modern chart
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.5))
                    .frame(width: 140, height: 220)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                
                ChartBars(
                    income: data.income,
                    expense: data.expense,
                    maxValue: maxValue,
                    animateChart: animateChart,
                    index: index
                )
                
                // Balance indicator
                BalanceIndicator(
                    balance: data.income - data.expense,
                    currency: wallet.currency,
                    animateChart: animateChart
                )
            }
            
            // Income and expense values
            DataValues(
                income: data.income,
                expense: data.expense,
                currency: wallet.currency
            )
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isSelected ? 
                      Color.white.opacity(0.03) : 
                      Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? Color.white.opacity(0.1) : Color.clear, lineWidth: 1)
                )
        )
        .onTapGesture(perform: onTap)
    }
}

// Chart bars component
struct ChartBars: View {
    let income: Double
    let expense: Double
    let maxValue: Double
    let animateChart: Bool
    let index: Int
    
    var body: some View {
        VStack(spacing: 0) {
            // Income visualization
            ZStack(alignment: .bottom) {
                // Income background
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.green.opacity(0.03))
                    .frame(width: 100, height: 80)
                
                // Income bar
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.green.opacity(0.2),
                                Color.green.opacity(0.5)
                            ]),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(
                        width: 100,
                        height: animateChart ? CGFloat(income / maxValue * 80) : 0
                    )
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(Double(index) * 0.1), value: animateChart)
                
                // Income glow
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.green.opacity(0.2))
                    .frame(
                        width: 100,
                        height: animateChart ? CGFloat(income / maxValue * 80) : 0
                    )
                    .blur(radius: 8)
                    .opacity(0.7)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(Double(index) * 0.1), value: animateChart)
            }
            .padding(.bottom, 10)
            
            // Expense visualization
            ZStack(alignment: .top) {
                // Expense background
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.red.opacity(0.03))
                    .frame(width: 100, height: 80)
                
                // Expense bar
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.red.opacity(0.5),
                                Color.red.opacity(0.2)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(
                        width: 100,
                        height: animateChart ? CGFloat(expense / maxValue * 80) : 0
                    )
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(Double(index) * 0.1 + 0.1), value: animateChart)
                
                // Expense glow
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.red.opacity(0.2))
                    .frame(
                        width: 100,
                        height: animateChart ? CGFloat(expense / maxValue * 80) : 0
                    )
                    .blur(radius: 8)
                    .opacity(0.7)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(Double(index) * 0.1 + 0.1), value: animateChart)
            }
        }
    }
}

// Balance indicator component
struct BalanceIndicator: View {
    let balance: Double
    let currency: String
    let animateChart: Bool
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                Text("\(currency)\(String(format: "%.0f", balance))")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(balance >= 0 ? Color.green : Color.red)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black.opacity(0.8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )
                    )
                    .opacity(animateChart ? 1 : 0)
                    .animation(.easeIn.delay(0.5), value: animateChart)
                
                Spacer()
            }
            .padding(.bottom, 8)
        }
    }
}

// Data values component
struct DataValues: View {
    let income: Double
    let expense: Double
    let currency: String
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.green.opacity(0.7))
                    .frame(width: 8, height: 8)
                
                Text("\(currency)\(String(format: "%.0f", income))")
                    .font(.caption)
                    .foregroundColor(Color.green.opacity(0.8))
            }
            
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.red.opacity(0.7))
                    .frame(width: 8, height: 8)
                
                Text("\(currency)\(String(format: "%.0f", expense))")
                    .font(.caption)
                    .foregroundColor(Color.red.opacity(0.8))
            }
        }
    }
}

// Scale button style for interactive buttons
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// Transaction List View for Income/Expense details
struct TransactionListView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let title: String
    let transactions: [Transaction]
    let wallet: Wallet
    
    @State private var showDeleteConfirmation: Bool = false
    @State private var transactionToDelete: Transaction? = nil
    @State private var showEditTransaction: Bool = false
    @State private var transactionToEdit: Transaction? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Pure black background
                Color.black
                    .ignoresSafeArea()
                
                // Diffused background elements
                ZStack {
                    // Green diffused circle
                    Circle()
                        .fill(Color.green.opacity(0.08))
                        .frame(width: 350, height: 350)
                        .blur(radius: 100)
                        .offset(x: -120, y: -250)
                    
                    // Red diffused circle
                    Circle()
                        .fill(Color.red.opacity(0.08))
                        .frame(width: 350, height: 350)
                        .blur(radius: 100)
                        .offset(x: 120, y: 250)
                    
                    // Additional subtle diffusion
                    Circle()
                        .fill(Color.purple.opacity(0.03))
                        .frame(width: 250, height: 250)
                        .blur(radius: 80)
                        .offset(x: 50, y: -100)
                }
                .ignoresSafeArea()
                
                if transactions.isEmpty {
                    VStack {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.system(size: 60))
                            .foregroundColor(Color.white.opacity(0.3))
                            .padding(.bottom, 16)
                        
                        Text("No transactions found")
                            .font(.title3)
                            .foregroundColor(Color.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(transactions) { transaction in
                                TransactionCard(
                                    amount: transaction.amount,
                                    category: transaction.category,
                                    date: transaction.date,
                                    type: transaction.type,
                                    note: transaction.note,
                                    currency: wallet.currency
                                )
                                .contextMenu {
                                    Button(action: {
                                        transactionToEdit = transaction
                                        showEditTransaction = true
                                    }) {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    
                                    Button(role: .destructive, action: {
                                        transactionToDelete = transaction
                                        showDeleteConfirmation = true
                                    }) {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .onLongPressGesture(minimumDuration: 0.5) {
                                    // Provide haptic feedback
                                    let generator = UIImpactFeedbackGenerator(style: .medium)
                                    generator.impactOccurred()
                                    
                                    // Show action sheet
                                    transactionToEdit = transaction
                                    showEditTransaction = true
                                }
                                .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding()
                    }
                }
                
                // Delete Confirmation Dialog
                if showDeleteConfirmation, let transaction = transactionToDelete {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .transition(.opacity)
                    
                    VStack(spacing: 20) {
                        Text("Delete Transaction")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Are you sure you want to delete this transaction? This action cannot be undone.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color.gray.opacity(0.8))
                        
                        HStack(spacing: 16) {
                            Button(action: {
                                withAnimation {
                                    showDeleteConfirmation = false
                                    transactionToDelete = nil
                                }
                            }) {
                                Text("Cancel")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.black.opacity(0.6))
                                    .cornerRadius(30)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 30)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                            }
                            
                            Button(action: {
                                if let index = wallet.transactions.firstIndex(where: { $0.id == transaction.id }) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        // Update wallet totals
                                        if transaction.type == TransactionType.income.rawValue {
                                            wallet.totalIncome -= transaction.amount
                                            wallet.balance -= transaction.amount
                                        } else if transaction.type == TransactionType.expense.rawValue {
                                            wallet.totalExpenses -= transaction.amount
                                            wallet.balance += transaction.amount
                                        }
                                        
                                        // Remove from wallet's transactions array
                                        wallet.transactions.remove(at: index)
                                        
                                        // Delete from the model context
                                        modelContext.delete(transaction)
                                        
                                        // Save changes
                                        saveContext()
                                        
                                        // Reset state
                                        showDeleteConfirmation = false
                                        transactionToDelete = nil
                                        
                                        // Dismiss the sheet after a short delay
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            dismiss()
                                        }
                                    }
                                }
                            }) {
                                Text("Delete")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.red)
                                    .cornerRadius(30)
                            }
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(20)
                    .padding(.horizontal, 20)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color.white.opacity(0.7))
                    }
                }
            }
            .sheet(isPresented: $showEditTransaction, onDismiss: {
                transactionToEdit = nil
            }) {
                if let transaction = transactionToEdit {
                    EditTransactionView(wallet: wallet, transaction: transaction)
                }
            }
        }
    }
    
    // Helper function to save the model context
    private func saveContext() {
        do {
            try modelContext.save()
            print("Successfully saved changes to database")
        } catch {
            print("Failed to save changes: \(error)")
        }
    }
}

#Preview {
    NavigationStack {
        MonthlyReportView(showAllWallets: true)
    }
} 