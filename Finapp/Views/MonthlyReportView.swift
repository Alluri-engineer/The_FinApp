import SwiftUI
import SwiftData

struct MonthlyReportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    let wallet: Wallet
    
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
        
        // Get start and end date for the month
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
        
        // Calculate income and expense for this month
        for transaction in wallet.transactions {
            if transaction.date >= startDate && transaction.date <= endDate {
                if transaction.type == TransactionType.income.rawValue {
                    totalIncome += transaction.amount
                } else if transaction.type == TransactionType.expense.rawValue {
                    totalExpense += transaction.amount
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
        
        // Get start and end date for the month
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
        
        return wallet.transactions.filter { transaction in
            transaction.date >= startDate && transaction.date <= endDate
        }.sorted(by: { $0.date > $1.date })
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
                
                VStack(spacing: 20) {
                    // Header with month selector
                    VStack(spacing: 8) {
                        Text("\(monthName(month: selectedMonth)) \(String(selectedYear))")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.top)
                        
                        Text("Financial Summary")
                            .font(.subheadline)
                            .foregroundColor(Color.gray.opacity(0.7))
                    }
                    .padding(.top, 8)
                    
                    // Monthly Balance Card
                    modernCard {
                        VStack(spacing: 16) {
                            Text("Monthly Balance")
                                .font(.headline)
                                .foregroundColor(Color.gray.opacity(0.8))
                            
                            Text("\(wallet.currency)\(String(format: "%.2f", selectedMonthData.balance))")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(selectedMonthData.balance >= 0 ? Color.green : Color.red)
                                .contentTransition(.numericText())
                                .shadow(color: selectedMonthData.balance >= 0 ? Color.green.opacity(0.5) : Color.red.opacity(0.5), radius: 4, x: 0, y: 0)
                            
                            HStack(spacing: 20) {
                                // Income Card
                                Button(action: {
                                    showIncomeDetails = true
                                }) {
                                    VStack(spacing: 8) {
                                        Text("Income")
                                            .font(.subheadline)
                                            .foregroundColor(Color.gray.opacity(0.8))
                                        
                                        Text("\(wallet.currency)\(String(format: "%.2f", selectedMonthData.income))")
                                            .font(.headline)
                                            .foregroundColor(Color.green)
                                            .contentTransition(.numericText())
                                        
                                        Image(systemName: "arrow.up.forward.circle.fill")
                                            .font(.caption)
                                            .foregroundColor(Color.green.opacity(0.7))
                                            .padding(.top, 4)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.green.opacity(0.08))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.green.opacity(0.15), lineWidth: 1)
                                            )
                                    )
                                }
                                .buttonStyle(ScaleButtonStyle())
                                
                                // Expense Card
                                Button(action: {
                                    showExpenseDetails = true
                                }) {
                                    VStack(spacing: 8) {
                                        Text("Expenses")
                                            .font(.subheadline)
                                            .foregroundColor(Color.gray.opacity(0.8))
                                        
                                        Text("\(wallet.currency)\(String(format: "%.2f", selectedMonthData.expense))")
                                            .font(.headline)
                                            .foregroundColor(Color.red)
                                            .contentTransition(.numericText())
                                        
                                        Image(systemName: "arrow.down.forward.circle.fill")
                                            .font(.caption)
                                            .foregroundColor(Color.red.opacity(0.7))
                                            .padding(.top, 4)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.red.opacity(0.08))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.red.opacity(0.15), lineWidth: 1)
                                            )
                                    )
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                        }
                        .padding()
                    }
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
                    
                    Spacer()
                }
                .padding(.top)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                    }
                }
            }
            .sheet(isPresented: $showIncomeDetails) {
                TransactionListView(
                    title: "Income Details",
                    transactions: selectedMonthIncomeTransactions,
                    wallet: wallet
                )
            }
            .sheet(isPresented: $showExpenseDetails) {
                TransactionListView(
                    title: "Expense Details",
                    transactions: selectedMonthExpenseTransactions,
                    wallet: wallet
                )
            }
            .onAppear {
                // Start chart animation after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    animateChart = true
                }
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
                        wallet: wallet,
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

// Edit Transaction View
struct EditTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let wallet: Wallet
    let transaction: Transaction
    
    @State private var amount: String
    @State private var category: String
    @State private var note: String
    @State private var date: Date
    @State private var showingCategoryPicker: Bool = false
    
    init(wallet: Wallet, transaction: Transaction) {
        self.wallet = wallet
        self.transaction = transaction
        
        // Initialize state variables with transaction values
        _amount = State(initialValue: String(format: "%.2f", transaction.amount))
        _category = State(initialValue: transaction.category)
        _note = State(initialValue: transaction.note)
        _date = State(initialValue: transaction.date)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.black.ignoresSafeArea()
                
                // Diffused background elements
                ZStack {
                    Circle()
                        .fill(transaction.type == TransactionType.income.rawValue ? 
                              Color.green.opacity(0.08) : Color.red.opacity(0.08))
                        .frame(width: 350, height: 350)
                        .blur(radius: 100)
                        .offset(x: -120, y: -250)
                    
                    Circle()
                        .fill(Color.purple.opacity(0.03))
                        .frame(width: 250, height: 250)
                        .blur(radius: 80)
                        .offset(x: 50, y: -100)
                }
                .ignoresSafeArea()
                
                // Form content
                VStack(spacing: 24) {
                    // Transaction type header
                    Text(transaction.type == TransactionType.income.rawValue ? "Edit Income" : "Edit Expense")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top)
                    
                    // Amount field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Amount")
                            .font(.headline)
                            .foregroundColor(Color.gray.opacity(0.8))
                        
                        HStack {
                            Text(wallet.currency)
                                .font(.title3)
                                .foregroundColor(.white)
                            
                            TextField("0.00", text: $amount)
                                .font(.title3)
                                .foregroundColor(.white)
                                .keyboardType(.decimalPad)
                                .padding()
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Category field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(.headline)
                            .foregroundColor(Color.gray.opacity(0.8))
                        
                        Button(action: {
                            showingCategoryPicker = true
                        }) {
                            HStack {
                                Text(category)
                                    .font(.title3)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.down")
                                    .foregroundColor(Color.gray.opacity(0.8))
                            }
                            .padding()
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Date picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Date")
                            .font(.headline)
                            .foregroundColor(Color.gray.opacity(0.8))
                        
                        DatePicker("", selection: $date, displayedComponents: [.date])
                            .datePickerStyle(GraphicalDatePickerStyle())
                            .accentColor(transaction.type == TransactionType.income.rawValue ? .green : .red)
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal)
                    
                    // Note field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Note")
                            .font(.headline)
                            .foregroundColor(Color.gray.opacity(0.8))
                        
                        TextField("Add a note", text: $note)
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Save button
                    Button(action: {
                        saveTransaction()
                    }) {
                        Text("Save Changes")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                transaction.type == TransactionType.income.rawValue ? 
                                Color.green : Color.red
                            )
                            .cornerRadius(30)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
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
            .sheet(isPresented: $showingCategoryPicker) {
                CategoryPickerView(
                    selectedCategory: $category,
                    transactionType: transaction.type
                )
            }
        }
    }
    
    private func saveTransaction() {
        // Convert amount string to Double
        guard let amountValue = Double(amount.replacingOccurrences(of: ",", with: ".")) else {
            return
        }
        
        // Calculate the difference in amount
        let amountDifference = amountValue - transaction.amount
        
        // Update transaction properties
        transaction.amount = amountValue
        transaction.category = category
        transaction.note = note
        transaction.date = date
        
        // Update wallet totals
        if transaction.type == TransactionType.income.rawValue {
            wallet.totalIncome += amountDifference
            wallet.balance += amountDifference
        } else if transaction.type == TransactionType.expense.rawValue {
            wallet.totalExpenses += amountDifference
            wallet.balance -= amountDifference
        }
        
        // Save changes
        do {
            try modelContext.save()
            print("Successfully saved transaction changes")
            dismiss()
        } catch {
            print("Failed to save transaction changes: \(error)")
        }
    }
}

// Category Picker View
struct CategoryPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCategory: String
    let transactionType: String
    
    private var categories: [String] {
        if transactionType == TransactionType.income.rawValue {
            // Income categories
            return [
                TransactionCategory.salary.rawValue,
                TransactionCategory.investment.rawValue,
                TransactionCategory.gift.rawValue,
                TransactionCategory.other.rawValue
            ]
        } else {
            // Expense categories
            return [
                TransactionCategory.food.rawValue,
                TransactionCategory.transportation.rawValue,
                TransactionCategory.entertainment.rawValue,
                TransactionCategory.utilities.rawValue,
                TransactionCategory.rent.rawValue,
                TransactionCategory.shopping.rawValue,
                TransactionCategory.health.rawValue,
                TransactionCategory.education.rawValue,
                TransactionCategory.other.rawValue
            ]
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack {
                    List {
                        ForEach(categories, id: \.self) { category in
                            Button(action: {
                                selectedCategory = category
                                dismiss()
                            }) {
                                HStack {
                                    Text(category)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    if category == selectedCategory {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(transactionType == TransactionType.income.rawValue ? .green : .red)
                                    }
                                }
                            }
                            .listRowBackground(Color.black.opacity(0.6))
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("Select Category")
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
        }
    }
}

#Preview {
    MonthlyReportView(wallet: Wallet())
        .modelContainer(for: [Wallet.self, Transaction.self, CryptoAsset.self], inMemory: true)
} 