import SwiftUI
import SwiftData

struct AddTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let wallet: Wallet
    let transactionType: String
    
    @State private var amount: String = ""
    @State private var category: String = ""
    @State private var note: String = ""
    @State private var selectedDate: Date = Date()
    @State private var showDatePicker: Bool = false
    @State private var showCategoryList: Bool = false
    @State private var isCustomCategory: Bool = false
    @State private var animateButton: Bool = false
    
    // Predefined categories based on transaction type
    private var predefinedCategories: [String] {
        if transactionType == TransactionType.income.rawValue {
            return ["Salary", "Other Income"]
        } else {
            return ["Rent", "Shopping", "Other Expense"]
        }
    }
    
    private var buttonTitle: String {
        return transactionType == TransactionType.income.rawValue ? "Add Income" : "Add Expense"
    }
    
    private var buttonColor: Color {
        return transactionType == TransactionType.income.rawValue ? Color.green : Color.red
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Amount Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Amount")
                            .font(.headline)
                            .foregroundColor(AppTheme.primaryTextColor)
                        
                        HStack {
                            Text(wallet.currency)
                                .font(.title)
                                .foregroundColor(AppTheme.primaryTextColor)
                            
                            TextField("0.00", text: $amount)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(AppTheme.primaryTextColor)
                        }
                        .padding()
                        .background(AppTheme.buttonBackgroundColor)
                        .cornerRadius(AppTheme.cornerRadius)
                    }
                    .padding(.horizontal)
                    
                    // Date Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Date")
                            .font(.headline)
                            .foregroundColor(AppTheme.primaryTextColor)
                        
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showDatePicker.toggle()
                            }
                        }) {
                            HStack {
                                Text(formattedDate)
                                    .foregroundColor(AppTheme.primaryTextColor)
                                
                                Spacer()
                                
                                Image(systemName: "calendar")
                                    .foregroundColor(AppTheme.primaryTextColor)
                            }
                            .padding()
                            .background(AppTheme.buttonBackgroundColor)
                            .cornerRadius(AppTheme.cornerRadius)
                        }
                        
                        if showDatePicker {
                            DatePicker("", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.graphical)
                                .padding()
                                .background(AppTheme.buttonBackgroundColor)
                                .cornerRadius(AppTheme.cornerRadius)
                                .transition(.scale.combined(with: .opacity))
                                .onChange(of: selectedDate) { _, _ in
                                    withAnimation {
                                        showDatePicker = false
                                    }
                                }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Category Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(.headline)
                            .foregroundColor(AppTheme.primaryTextColor)
                        
                        if isCustomCategory {
                            // Custom category input
                            TextField("Enter custom category", text: $category)
                                .padding()
                                .background(AppTheme.buttonBackgroundColor)
                                .cornerRadius(AppTheme.cornerRadius)
                                .foregroundColor(AppTheme.primaryTextColor)
                            
                            Button(action: {
                                withAnimation {
                                    isCustomCategory = false
                                    showCategoryList = true
                                }
                            }) {
                                Text("Choose from list")
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.accentColor)
                                    .padding(.top, 4)
                            }
                        } else {
                            // Category selector button
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    showCategoryList.toggle()
                                }
                            }) {
                                HStack {
                                    Text(category.isEmpty ? "Select a category" : category)
                                        .foregroundColor(AppTheme.primaryTextColor)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(AppTheme.primaryTextColor)
                                        .rotationEffect(Angle(degrees: showCategoryList ? 180 : 0))
                                }
                                .padding()
                                .background(AppTheme.buttonBackgroundColor)
                                .cornerRadius(AppTheme.cornerRadius)
                            }
                            
                            if showCategoryList {
                                VStack(spacing: 0) {
                                    // List of predefined categories
                                    ForEach(predefinedCategories, id: \.self) { cat in
                                        Button(action: {
                                            withAnimation {
                                                category = cat
                                                showCategoryList = false
                                            }
                                        }) {
                                            HStack {
                                                Text(cat)
                                                    .foregroundColor(AppTheme.primaryTextColor)
                                                
                                                Spacer()
                                                
                                                if category == cat {
                                                    Image(systemName: "checkmark")
                                                        .foregroundColor(AppTheme.accentColor)
                                                }
                                            }
                                            .padding()
                                            .background(category == cat ? AppTheme.accentColor.opacity(0.1) : Color.clear)
                                        }
                                        
                                        if cat != predefinedCategories.last {
                                            Divider()
                                                .padding(.horizontal)
                                        }
                                    }
                                    
                                    Divider()
                                        .padding(.horizontal)
                                    
                                    // Custom category option
                                    Button(action: {
                                        withAnimation {
                                            isCustomCategory = true
                                            showCategoryList = false
                                            category = ""
                                        }
                                    }) {
                                        HStack {
                                            Text("Add custom category")
                                                .foregroundColor(AppTheme.accentColor)
                                            
                                            Spacer()
                                            
                                            Image(systemName: "plus.circle")
                                                .foregroundColor(AppTheme.accentColor)
                                        }
                                        .padding()
                                    }
                                }
                                .background(AppTheme.buttonBackgroundColor)
                                .cornerRadius(AppTheme.cornerRadius)
                                .transition(.scale.combined(with: .opacity))
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Note Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Note (Optional)")
                            .font(.headline)
                            .foregroundColor(AppTheme.primaryTextColor)
                        
                        TextField("Add a note", text: $note)
                            .padding()
                            .background(AppTheme.buttonBackgroundColor)
                            .cornerRadius(AppTheme.cornerRadius)
                            .foregroundColor(AppTheme.primaryTextColor)
                    }
                    .padding(.horizontal)
                    
                    // Add Button
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            animateButton = true
                            
                            // Add transaction after a short delay for animation
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                addTransaction()
                            }
                        }
                    }) {
                        Text(buttonTitle)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(buttonColor)
                            .cornerRadius(30)
                            .scaleEffect(animateButton ? 0.95 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: animateButton)
                    }
                    .padding(.horizontal)
                    .disabled(amount.isEmpty || category.isEmpty)
                    .opacity(amount.isEmpty || category.isEmpty ? 0.5 : 1)
                }
                .padding(.vertical)
            }
            .background(AppTheme.backgroundColor.ignoresSafeArea())
            .navigationTitle(transactionType == TransactionType.income.rawValue ? "Add Income" : "Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(AppTheme.primaryTextColor)
                    }
                }
            }
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: selectedDate)
    }
    
    private func addTransaction() {
        guard let amountValue = Double(amount), !category.isEmpty else { return }
        
        let transaction = Transaction(
            amount: amountValue,
            date: selectedDate,
            category: category,
            type: transactionType,
            note: note
        )
        
        // Add transaction to wallet
        wallet.addTransaction(transaction)
        
        // Recalculate wallet totals to ensure accuracy
        recalculateTotals()
        
        // Save changes to the database
        do {
            try modelContext.save()
            print("Successfully saved transaction to database")
            dismiss()
        } catch {
            print("Failed to save transaction: \(error)")
        }
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
    }
}

#Preview {
    AddTransactionView(
        wallet: Wallet(),
        transactionType: TransactionType.income.rawValue
    )
    .modelContainer(for: [Wallet.self, Transaction.self, CryptoAsset.self], inMemory: true)
} 
