import SwiftUI
import SwiftData

struct WalletView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var wallets: [Wallet]
    
    @State private var isEditingBalance: Bool = false
    @State private var editedBalance: String = ""
    @State private var showAddIncome: Bool = false
    @State private var showAddExpense: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var transactionToDelete: Transaction? = nil
    @State private var isInitializing: Bool = true
    @State private var animateBalance: Bool = false
    @State private var showMonthlyReport: Bool = false
    @State private var isEditingWalletName: Bool = false
    @State private var editedWalletName: String = ""
    @State private var cardRotation: Double = 0
    @State private var isCardPressed: Bool = false
    @State private var cardGlowOpacity: Double = 0
    @State private var showEditTransactionSheet: Bool = false
    @State private var transactionToEdit: Transaction? = nil
    @State private var showActionSheet: Bool = false
    @State private var rainbowPhase: Double = 0
    
    private var wallet: Wallet {
        if wallets.isEmpty {
            print("Creating new wallet with default transactions")
            let newWallet = Wallet(
                balance: 40278.00,
                currency: "$",
                name: "Puja Santosh Wallet",
                totalIncome: 52700,
                totalExpenses: 12422
            )
            
            // Create default transactions
            let transactions = [
                Transaction(amount: 5000.00, category: TransactionCategory.salary.rawValue, type: TransactionType.income.rawValue, note: "Monthly salary"),
                Transaction(amount: 1000.00, category: TransactionCategory.investment.rawValue, type: TransactionType.income.rawValue, note: "Stock dividends"),
                Transaction(amount: 500.00, category: TransactionCategory.gift.rawValue, type: TransactionType.income.rawValue, note: "Birthday gift"),
                Transaction(amount: 120.50, category: TransactionCategory.food.rawValue, type: TransactionType.expense.rawValue, note: "Grocery shopping"),
                Transaction(amount: 45.00, category: TransactionCategory.transportation.rawValue, type: TransactionType.expense.rawValue, note: "Uber ride"),
                Transaction(amount: 15.99, category: TransactionCategory.entertainment.rawValue, type: TransactionType.expense.rawValue, note: "Movie ticket")
            ]
            
            // Add transactions to wallet
            for transaction in transactions {
                newWallet.addTransaction(transaction)
            }
            
            // Insert the wallet into the model context
            modelContext.insert(newWallet)
            
            // Save changes to the database
            do {
                try modelContext.save()
                print("Successfully saved new wallet to database")
            } catch {
                print("Failed to save wallet: \(error)")
            }
            
            return newWallet
        }
        return wallets[0]
    }
    
    // Function to recalculate totals
    private func recalculateTotals() {
        var totalInc: Double = 0
        var totalExp: Double = 0
        
        for transaction in wallet.transactions {
            if transaction.type == TransactionType.income.rawValue {
                totalInc += transaction.amount
            } else if transaction.type == TransactionType.expense.rawValue {
                totalExp += transaction.amount
            }
        }
        
        wallet.totalIncome = totalInc
        wallet.totalExpenses = totalExp
        wallet.balance = totalInc - totalExp
        
        saveContext()
    }
    
    // Function to provide haptic feedback
    private func hapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
    
    // Computed property to determine if spending is high (more than 50% of income)
    private var isHighSpending: Bool {
        return wallet.totalExpenses > (wallet.totalIncome * 0.5)
    }
    
    // Computed property for card gradient based on spending
    private var cardGradient: LinearGradient {
        if isHighSpending {
            // Red gradient for high spending
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "FF0000"), // Bright red
                    Color(hex: "CC0000"), // Medium red
                    Color(hex: "990000"), // Dark red
                    Color(hex: "800000")  // Deep red
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            // Titanium gradient for normal spending
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "C0C0C0"), // Silver
                    Color(hex: "A9A9A9"), // Dark gray
                    Color(hex: "B8B8B8"), // Light gray
                    Color(hex: "A0A0A0")  // Medium gray
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 24) {
                        // Credit Card Style Wallet
                        creditCardView
                            .padding(.horizontal)
                            .padding(.top, 20)
                            .onLongPressGesture(minimumDuration: 1.2, pressing: { isPressing in
                                // Provide visual feedback while pressing
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    isCardPressed = isPressing
                                    cardGlowOpacity = isPressing ? 0.8 : 0
                                }
                                
                                // Provide haptic feedback when press starts
                                if isPressing {
                                    hapticFeedback()
                                }
                            }) {
                                // Action when long press is completed (after 1.2 seconds)
                                hapticFeedback() // Additional feedback when gesture completes
                                
                                // Show monthly report
                                showMonthlyReport = true
                                
                                // Reset card state after a delay
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    withAnimation {
                                        isCardPressed = false
                                        cardGlowOpacity = 0
                                    }
                                }
                            }
                        
                        // Action Buttons with Diffusion
                        HStack(spacing: 16) {
                            // Add Button with Blue Diffusion
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    showAddIncome = true
                                }
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 16))
                                    Text("ADD")
                                        .font(.system(size: 16, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    ZStack {
                                        // Diffused glow
                                        RoundedRectangle(cornerRadius: 30)
                                            .fill(Color.blue.opacity(0.3))
                                            .blur(radius: 8)
                                        
                                        // Button background
                                        RoundedRectangle(cornerRadius: 30)
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        Color.blue.opacity(0.7),
                                                        Color.blue.opacity(0.5)
                                                    ]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                    }
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 30)
                                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                )
                                .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 2)
                            }
                            .scaleEffect(showAddIncome ? 0.95 : 1.0)
                            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: showAddIncome)
                            
                            // Burn Button with Pink Diffusion
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    showAddExpense = true
                                }
                            }) {
                                HStack {
                                    Image(systemName: "flame.fill")
                                        .font(.system(size: 16))
                                    Text("BURN")
                                        .font(.system(size: 16, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    ZStack {
                                        // Diffused glow
                                        RoundedRectangle(cornerRadius: 30)
                                            .fill(Color.pink.opacity(0.3))
                                            .blur(radius: 8)
                                        
                                        // Button background
                                        RoundedRectangle(cornerRadius: 30)
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        Color.pink.opacity(0.7),
                                                        Color.pink.opacity(0.5)
                                                    ]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                    }
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 30)
                                        .stroke(Color.pink.opacity(0.3), lineWidth: 1)
                                )
                                .shadow(color: Color.pink.opacity(0.3), radius: 5, x: 0, y: 2)
                            }
                            .scaleEffect(showAddExpense ? 0.95 : 1.0)
                            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: showAddExpense)
                        }
                        .padding(.horizontal)
                        
                        // Recent Transactions Section
                        VStack(spacing: 16) {
                            HStack {
                                Text("Recent")
                                    .font(.headline)
                                    .foregroundColor(AppTheme.primaryTextColor)
                                
                                Spacer()
                            }
                            
                            Divider()
                                .background(AppTheme.secondaryTextColor)
                            
                            // Recent Transactions List
                            if wallet.recentTransactions().isEmpty {
                                Text("No recent transactions")
                                    .foregroundColor(AppTheme.secondaryTextColor)
                                    .padding()
                            } else {
                                VStack(spacing: 12) {
                                    ForEach(wallet.recentTransactions(limit: 5)) { transaction in
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
                                                // Edit transaction
                                                showEditTransaction(transaction)
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
                                            hapticFeedback()
                                            
                                            // Show action sheet for edit/delete
                                            showTransactionActionSheet(transaction)
                                        }
                                        .transition(.scale.combined(with: .opacity))
                                    }
                                }
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: wallet.transactions.count)
                            }
                        }
                        .padding()
                        .background(AppTheme.cardBackgroundColor)
                        .cornerRadius(AppTheme.cornerRadius)
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
                .background(AppTheme.backgroundColor.ignoresSafeArea())
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("Finance")
                            .font(.system(size: 24, weight: .black))
                            .foregroundColor(.white)
                    }
                }
                .sheet(isPresented: $showAddIncome) {
                    AddTransactionView(
                        wallet: wallet,
                        transactionType: TransactionType.income.rawValue
                    )
                }
                .sheet(isPresented: $showAddExpense) {
                    AddTransactionView(
                        wallet: wallet,
                        transactionType: TransactionType.expense.rawValue
                    )
                }
                .sheet(isPresented: $showMonthlyReport) {
                    MonthlyReportView(wallet: wallet)
                }
                .sheet(isPresented: $showEditTransactionSheet) {
                    if let transaction = transactionToEdit {
                        EditTransactionView(wallet: wallet, transaction: transaction)
                    }
                }
                .actionSheet(isPresented: $showActionSheet) {
                    ActionSheet(
                        title: Text("Transaction Options"),
                        message: Text("What would you like to do with this transaction?"),
                        buttons: [
                            .default(Text("Edit")) {
                                if let transaction = transactionToEdit {
                                    showEditTransaction(transaction)
                                }
                            },
                            .destructive(Text("Delete")) {
                                if let transaction = transactionToEdit {
                                    transactionToDelete = transaction
                                    showDeleteConfirmation = true
                                }
                            },
                            .cancel()
                        ]
                    )
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
                            .foregroundColor(AppTheme.primaryTextColor)
                        
                        Text("Are you sure you want to delete this transaction? This action cannot be undone.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(AppTheme.secondaryTextColor)
                        
                        HStack(spacing: 16) {
                            Button(action: {
                                withAnimation {
                                    showDeleteConfirmation = false
                                    transactionToDelete = nil
                                }
                            }) {
                                Text("Cancel")
                                    .font(.headline)
                                    .foregroundColor(AppTheme.primaryTextColor)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(AppTheme.buttonBackgroundColor)
                                    .cornerRadius(30)
                            }
                            
                            Button(action: {
                                if let index = wallet.transactions.firstIndex(where: { $0.id == transaction.id }) {
                                    // First dismiss the confirmation dialog
                                    showDeleteConfirmation = false
                                    
                                    // Use a slight delay to ensure UI updates properly
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
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
                                        transactionToDelete = nil
                                        
                                        // Animate balance update
                                        animateBalance = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                            animateBalance = false
                                        }
                                    }
                                } else {
                                    // If transaction not found, just dismiss the dialog
                                    showDeleteConfirmation = false
                                    transactionToDelete = nil
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
                    .background(AppTheme.cardBackgroundColor)
                    .cornerRadius(AppTheme.cornerRadius)
                    .padding(.horizontal, 20)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .onAppear {
                if isInitializing {
                    // Force access to wallet property to ensure it's created if needed
                    _ = self.wallet
                    isInitializing = false
                    
                    // Recalculate totals to ensure accuracy
                    recalculateTotals()
                    
                    // Start a slow rainbow animation instead of rotation
                    withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
                        rainbowPhase = 360
                    }
                }
            }
        }
    }
    
    // Credit Card View
    private var creditCardView: some View {
        ZStack {
            // Edge glow diffusion effect (visible only when pressed)
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            isHighSpending ? Color.red.opacity(0.6) : Color.blue.opacity(0.6),
                            isHighSpending ? Color.red.opacity(0.4) : Color.blue.opacity(0.4)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .blur(radius: 15)
                .padding(-10) // Make it extend beyond the card
                .opacity(isCardPressed ? 0.8 : 0)
                .animation(.easeInOut(duration: 0.3), value: isCardPressed)
            
            // Card background with dynamic gradient based on spending
            RoundedRectangle(cornerRadius: 20)
                .fill(cardGradient)
                .overlay(
                    // Metallic finish pattern
                    ZStack {
                        // Horizontal brushed metal lines
                        VStack(spacing: 1) {
                            ForEach(0..<80, id: \.self) { _ in
                                Rectangle()
                                    .fill(Color.white.opacity(0.05))
                                    .frame(height: 1)
                            }
                        }
                        
                        // Subtle reflective highlights
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: 0))
                            path.addLine(to: CGPoint(x: 300, y: 0))
                            path.addLine(to: CGPoint(x: 0, y: 100))
                            path.closeSubpath()
                        }
                        .fill(Color.white.opacity(0.1))
                        
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: 220))
                            path.addLine(to: CGPoint(x: 300, y: 220))
                            path.addLine(to: CGPoint(x: 300, y: 150))
                            path.closeSubpath()
                        }
                        .fill(Color.white.opacity(0.1))
                        
                        // Metallic shimmer effect (no rainbow for titanium)
                        if !isHighSpending {
                            // Subtle titanium shimmer
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.0),
                                            Color.white.opacity(0.1),
                                            Color.white.opacity(0.2),
                                            Color.white.opacity(0.0)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .hueRotation(.degrees(rainbowPhase / 10))
                                .blendMode(.overlay)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                )
                .overlay(
                    // Card border with metallic effect
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.5),
                                    isHighSpending ? Color.red.opacity(0.3) : Color(hex: "A0A0A0").opacity(0.3),
                                    Color.white.opacity(0.5)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 10)
                .scaleEffect(isCardPressed ? 0.95 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isCardPressed)
            
            // Card content
            VStack(spacing: 0) {
                // Top section with wallet name
                HStack(alignment: .top) {
                    if isEditingWalletName {
                        TextField("Wallet Name", text: $editedWalletName)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.7))
                            .cornerRadius(8)
                            .onSubmit {
                                if !editedWalletName.isEmpty {
                                    wallet.name = editedWalletName
                                    isEditingWalletName = false
                                    saveContext()
                                }
                            }
                    } else {
                        Text(wallet.name)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.black)
                            .shadow(color: .white.opacity(0.5), radius: 1, x: 0, y: 0)
                            .onLongPressGesture(minimumDuration: 0.5) {
                                hapticFeedback()
                                editedWalletName = wallet.name
                                isEditingWalletName = true
                            }
                    }
                    
                    Spacer()
                    
                    // Card type label that changes based on spending
                    Text(isHighSpending ? "DANGER" : "TITANIUM")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.black.opacity(0.7))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.5))
                        )
                }
                .padding(.bottom, 40)
                
                // Middle section with card number simulation
                HStack(spacing: 8) {
                    ForEach(0..<4, id: \.self) { index in
                        Text("••••")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.black.opacity(0.8))
                    }
                }
                .padding(.bottom, 40)
                
                // Bottom section with balance
                HStack(alignment: .bottom) {
                    // Card holder info
                    VStack(alignment: .leading, spacing: 4) {
                        Text("BALANCE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.black.opacity(0.6))
                        
                        Text("\(wallet.currency)\(String(format: "%.2f", wallet.balance))")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.black)
                            .scaleEffect(animateBalance ? 1.05 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: animateBalance)
                    }
                    
                    Spacer()
                    
                    // Spending indicator
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("SPENDING")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.black.opacity(0.6))
                        
                        Text("\(Int(wallet.totalExpenses / wallet.totalIncome * 100))%")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(isHighSpending ? .red : .black)
                    }
                }
            }
            .padding(24)
            .scaleEffect(isCardPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isCardPressed)
        }
        .frame(height: 220)
    }
    
    // Function to show edit transaction sheet
    private func showEditTransaction(_ transaction: Transaction) {
        transactionToEdit = transaction
        showEditTransactionSheet = true
    }
    
    // Function to show action sheet for transaction
    private func showTransactionActionSheet(_ transaction: Transaction) {
        // First set the transaction, then show the sheet
        transactionToEdit = transaction
        
        // Use a slight delay to ensure proper state update
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            showActionSheet = true
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
    WalletView()
        .modelContainer(for: [Wallet.self, Transaction.self, CryptoAsset.self], inMemory: true)
} 


