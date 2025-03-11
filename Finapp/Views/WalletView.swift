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
    @State private var selectedWalletIndex: Int = 0
    @State private var showAddWalletSheet: Bool = false
    @State private var walletColors: [String: CardColor] = [:]

    private var selectedWallet: Wallet {
        if wallets.isEmpty {
            return createDefaultWallet()
        }
        return wallets[selectedWalletIndex]
    }

    private func createDefaultWallet() -> Wallet {
        print("Creating new wallet")
        let newWallet = Wallet(
            balance: 0.0,
            currency: "$",
            name: "My Wallet",
            totalIncome: 0.0,
            totalExpenses: 0.0,
            cardType: CardType.debit.rawValue
        )
        modelContext.insert(newWallet)
        walletColors[newWallet.name] = CardColor.allCases.randomElement() ?? .silver
        saveContext()
        return newWallet
    }

    private func toggleCardType(for wallet: Wallet) {
        wallet.cardType = wallet.cardType == CardType.debit.rawValue ? CardType.credit.rawValue : CardType.debit.rawValue
        saveContext()
        hapticFeedback()
    }

    private var isHighSpending: Bool {
        return selectedWallet.totalExpenses > (selectedWallet.totalIncome * 0.5)
    }

    private var cardGradient: LinearGradient {
        let baseColor = walletColors[selectedWallet.name]?.color ?? (isHighSpending ? .red : .gray)
        if isHighSpending {
            return LinearGradient(
                gradient: Gradient(colors: [
                    .red,
                    Color.red.opacity(0.8),
                    Color.red.opacity(0.6),
                    Color.red.opacity(0.4)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            let isCredit = selectedWallet.cardType == CardType.credit.rawValue
            return LinearGradient(
                gradient: Gradient(colors: [
                    isCredit ? Color.purple : baseColor,
                    (isCredit ? Color.purple : baseColor).opacity(0.9),
                    (isCredit ? Color.purple : baseColor).opacity(0.8),
                    (isCredit ? Color.purple : baseColor).opacity(0.7)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private func recalculateTotals(for wallet: Wallet) {
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

    private func hapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    private func saveContext() {
        do {
            try modelContext.save()
            print("Successfully saved changes to database")
        } catch {
            print("Failed to save changes: \(error)")
        }
    }

    private func showEditTransaction(_ transaction: Transaction) {
        transactionToEdit = transaction
        showEditTransactionSheet = true
    }

    private func showTransactionActionSheet(_ transaction: Transaction) {
        transactionToEdit = transaction
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            showActionSheet = true
        }
    }

    private func addNewWallet(name: String, color: CardColor) {
        let newWallet = Wallet(balance: 0.0, currency: "$", name: name, totalIncome: 0.0, totalExpenses: 0.0)
        modelContext.insert(newWallet)
        walletColors[name] = color
        saveContext()
        selectedWalletIndex = wallets.count - 1
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(spacing: 24) {
                        TabView(selection: $selectedWalletIndex) {
                            ForEach(wallets.indices, id: \.self) { index in
                                creditCardView(for: wallets[index])
                                    .tag(index)
                                    .frame(width: UIScreen.main.bounds.width - 40)
                                    .padding(.horizontal, 20)
                            }
                        }
                        .frame(height: 220)
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                        .padding(.top, 20)

                        HStack(spacing: 16) {
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
                                        RoundedRectangle(cornerRadius: 30)
                                            .fill(Color.blue.opacity(0.3))
                                            .blur(radius: 8)
                                        RoundedRectangle(cornerRadius: 30)
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.blue.opacity(0.5)]),
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
                                        RoundedRectangle(cornerRadius: 30)
                                            .fill(Color.pink.opacity(0.3))
                                            .blur(radius: 8)
                                        RoundedRectangle(cornerRadius: 30)
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [Color.pink.opacity(0.7), Color.pink.opacity(0.5)]),
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

                        VStack(spacing: 16) {
                            HStack {
                                Text("Recent Transactions")
                                    .font(.headline)
                                    .foregroundColor(AppTheme.primaryTextColor)
                                Spacer()
                            }
                            Divider().background(AppTheme.secondaryTextColor)
                            if selectedWallet.recentTransactions().isEmpty {
                                Text("No recent transactions")
                                    .foregroundColor(AppTheme.secondaryTextColor)
                                    .padding()
                            } else {
                                VStack(spacing: 12) {
                                    ForEach(selectedWallet.recentTransactions(limit: 5)) { transaction in
                                        TransactionCard(
                                            amount: transaction.amount,
                                            category: transaction.category,
                                            date: transaction.date,
                                            type: transaction.type,
                                            note: transaction.note,
                                            currency: selectedWallet.currency
                                        )
                                        .contextMenu {
                                            Button(action: { showEditTransaction(transaction) }) {
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
                                            hapticFeedback()
                                            showTransactionActionSheet(transaction)
                                        }
                                        .transition(.scale.combined(with: .opacity))
                                    }
                                }
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedWallet.transactions.count)
                            }
                        }
                        .padding()
                        .background(AppTheme.cardBackgroundColor)
                        .cornerRadius(AppTheme.cornerRadius)
                        .padding(.horizontal)

                        Spacer(minLength: 100)
                    }
                    .padding(.vertical)
                }
                .background(AppTheme.backgroundColor) // Removed .ignoresSafeArea() to respect the tab bar
                .padding(.top)
                .padding(.bottom)
                .padding(.trailing)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        HStack {
                            Spacer()
                            Text("Home")
                                .font(.system(size: 24, weight: .black))
                                .foregroundColor(.white)
                            Spacer()
                        }
                    }
                }
                .sheet(isPresented: $showAddIncome) {
                    AddTransactionView(wallet: selectedWallet, transactionType: TransactionType.income.rawValue)
                }
                .sheet(isPresented: $showAddExpense) {
                    AddTransactionView(wallet: selectedWallet, transactionType: TransactionType.expense.rawValue)
                }
                .sheet(isPresented: $showMonthlyReport) {
                    MonthlyReportView(showAllWallets: false, selectedWallet: selectedWallet)
                }
                .sheet(isPresented: $showEditTransactionSheet) {
                    if let transaction = transactionToEdit {
                        EditTransactionView(wallet: selectedWallet, transaction: transaction)
                    }
                }
                .overlay {
                    if showAddWalletSheet {
                        Color.black.opacity(0.5)
                            .ignoresSafeArea()
                            .onTapGesture { showAddWalletSheet = false }
                        AddWalletView { name, color in
                            addNewWallet(name: name, color: color)
                            showAddWalletSheet = false
                        }
                        .frame(width: 300, height: 200)
                        .background(Color.black)
                        .cornerRadius(20)
                        .shadow(radius: 10)
                        .transition(.scale)
                    }
                }
                .actionSheet(isPresented: $showActionSheet) {
                    ActionSheet(
                        title: Text("Transaction Options"),
                        message: Text("What would you like to do with this transaction?"),
                        buttons: [
                            .default(Text("Edit")) { if let transaction = transactionToEdit { showEditTransaction(transaction) } },
                            .destructive(Text("Delete")) { if let transaction = transactionToEdit { transactionToDelete = transaction; showDeleteConfirmation = true } },
                            .cancel()
                        ]
                    )
                }

                if showDeleteConfirmation, let transaction = transactionToDelete {
                    ZStack {
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
                                .foregroundColor(.gray)
                            
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
                                        .background(Color.gray.opacity(0.3))
                                        .cornerRadius(30)
                                }
                                
                                Button(action: {
                                    withAnimation {
                                        // Delete the transaction
                                        if let index = selectedWallet.transactions.firstIndex(where: { $0.id == transaction.id }) {
                                            // Update wallet totals
                                            if transaction.type == TransactionType.income.rawValue {
                                                selectedWallet.totalIncome -= transaction.amount
                                                selectedWallet.balance -= transaction.amount
                                            } else if transaction.type == TransactionType.expense.rawValue {
                                                selectedWallet.totalExpenses -= transaction.amount
                                                selectedWallet.balance += transaction.amount
                                            }
                                            
                                            // Remove transaction from wallet
                                            selectedWallet.transactions.remove(at: index)
                                            
                                            // Delete from model context
                                            modelContext.delete(transaction)
                                            
                                            // Save changes
                                            saveContext()
                                            
                                            // Trigger balance animation
                                            animateBalance = true
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                animateBalance = false
                                            }
                                        }
                                        
                                        // Reset state
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
                        .frame(maxWidth: 300)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                    }
                }
                
                FloatingActionButton {
                    showAddWalletSheet = true
                }
            }
            .onAppear {
                if isInitializing {
                    if wallets.isEmpty { _ = createDefaultWallet() }
                    recalculateTotals(for: selectedWallet)
                    isInitializing = false
                    withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
                        rainbowPhase = 360
                    }
                }
            }
        }
    }

    private func creditCardView(for wallet: Wallet) -> some View {
        ZStack {
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
                .padding(-10)
                .opacity(isCardPressed ? 0.8 : 0)
                .animation(.easeInOut(duration: 0.3), value: isCardPressed)

            RoundedRectangle(cornerRadius: 20)
                .fill(cardGradient)
                .overlay(
                    ZStack {
                        VStack(spacing: 1) {
                            ForEach(0..<80, id: \.self) { _ in
                                Rectangle()
                                    .fill(Color.white.opacity(0.05))
                                    .frame(height: 1)
                            }
                        }

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

                        if !isHighSpending {
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
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.5),
                                    isHighSpending ? Color.red.opacity(0.3) : Color.gray.opacity(0.3),
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
                .onLongPressGesture(minimumDuration: 1.2, pressing: { isPressing in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isCardPressed = isPressing
                        cardGlowOpacity = isPressing ? 0.8 : 0
                    }
                    if isPressing {
                        hapticFeedback()
                    }
                }) {
                    hapticFeedback()
                    showMonthlyReport = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation {
                            isCardPressed = false
                            cardGlowOpacity = 0
                        }
                    }
                }

            VStack(spacing: 0) {
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
                                    walletColors[editedWalletName] = walletColors.removeValue(forKey: wallet.name)
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
                    Button(action: {
                        toggleCardType(for: wallet)
                    }) {
                        Text(wallet.cardType)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.black.opacity(0.7))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(0.5))
                            )
                    }
                }
                .padding(.bottom, 40)

                HStack(spacing: 8) {
                    ForEach(0..<4, id: \.self) { _ in
                        Text("••••")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.black.opacity(0.8))
                    }
                }
                .padding(.bottom, 40)

                HStack(alignment: .bottom) {
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
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("SPENDING")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.black.opacity(0.6))
                        Text("\(Int(wallet.totalExpenses / max(wallet.totalIncome, 1) * 100))%")
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
        .onTapGesture {
            selectedWalletIndex = wallets.firstIndex(of: wallet) ?? 0
        }
    }
}

// MARK: - Card Color Enum
enum CardColor: String, CaseIterable, Identifiable {
    case silver, gold, black
    
    var id: String { rawValue }
    
    var color: Color {
        switch self {
        case .silver: return .gray
        case .gold: return .yellow
        case .black: return .black
        }
    }
}

// MARK: - Add Wallet View
struct AddWalletView: View {
    @State private var walletName: String = ""
    @State private var selectedColor: CardColor = CardColor.allCases.filter { $0 != .black }.randomElement() ?? .silver
    
    let onAdd: (String, CardColor) -> Void

    var body: some View {
        VStack(spacing: 15) {
            Text("Add New Wallet")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(AppTheme.primaryTextColor)
                .padding(.bottom, 5)
            
            TextField("Enter Wallet Name", text: $walletName)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 8).fill(AppTheme.cardBackgroundColor))
                .foregroundColor(AppTheme.primaryTextColor)
                .frame(width: 250)
                .shadow(radius: 3)
            
            HStack(spacing: 10) {
                ForEach(CardColor.allCases.filter { $0 != .black }) { color in
                    Circle()
                        .fill(color.color)
                        .frame(width: 30, height: 30)
                        .overlay(
                            Circle()
                                .stroke(selectedColor == color ? AppTheme.primaryTextColor : Color.clear, lineWidth: 2)
                        )
                        .shadow(radius: selectedColor == color ? 3 : 0)
                        .onTapGesture {
                            withAnimation {
                                selectedColor = color
                            }
                        }
                }
            }
            
            Button(action: {
                if !walletName.isEmpty {
                    onAdd(walletName, selectedColor)
                }
            }) {
                Text("Add Wallet")
                    .font(.system(size: 16, weight: .semibold))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(LinearGradient(
                        gradient: Gradient(colors: [AppTheme.buttonBackgroundColor, AppTheme.secondaryTextColor]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(radius: 3)
            }
            .padding(.top, 5)
        }
        .padding(15)
        .background(AppTheme.backgroundColor)
        .cornerRadius(15)
        .padding()
    }
}

// Update the EditTransactionView
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
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
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
                        
                        Spacer(minLength: 32)
                        
                        // Save button with improved visibility
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
                                .cornerRadius(12)
                                .shadow(color: (transaction.type == TransactionType.income.rawValue ? Color.green : Color.red).opacity(0.3),
                                        radius: 5, x: 0, y: 2)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 24))
                    }
                }
            }
            .sheet(isPresented: $showingCategoryPicker) {
                CategoryPickerView(selectedCategory: $category, transactionType: transaction.type)
            }
        }
    }
    
    private func saveTransaction() {
        guard let amountValue = Double(amount.replacingOccurrences(of: ",", with: ".")) else {
            return
        }
        
        let amountDifference = amountValue - transaction.amount
        
        transaction.amount = amountValue
        transaction.category = category
        transaction.note = note
        transaction.date = date
        
        if transaction.type == TransactionType.income.rawValue {
            wallet.totalIncome += amountDifference
            wallet.balance += amountDifference
        } else if transaction.type == TransactionType.expense.rawValue {
            wallet.totalExpenses += amountDifference
            wallet.balance -= amountDifference
        }
        
        do {
            try modelContext.save()
            print("Successfully saved transaction changes")
            dismiss()
        } catch {
            print("Failed to save transaction changes: \(error)")
        }
    }
}

// Update the CategoryPickerView
struct CategoryPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCategory: String
    let transactionType: String
    
    private var categories: [String] {
        if transactionType == TransactionType.income.rawValue {
            return [
                TransactionCategory.salary.rawValue,
                TransactionCategory.investment.rawValue,
                TransactionCategory.gift.rawValue,
                TransactionCategory.other.rawValue
            ]
        } else {
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
                        .padding(.vertical, 8)
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("Select Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 24))
                    }
                }
            }
        }
    }
}

#Preview {
    WalletView()
        .modelContainer(for: [Wallet.self, Transaction.self], inMemory: true)
}
