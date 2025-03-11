//
//  MoreView.swift
//  Finapp
//
//  Created by Sashank Singh on 03/10/25.
//

import Foundation
import SwiftUI
import SwiftData

struct MoreView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var cryptoAssets: [CryptoAsset]
    @Query private var stocks: [Stock]
    @State private var selectedTab = 0
    @State private var showAddAsset = false
    @State private var selectedTimePeriod: TimePeriod = .month
    @State private var riskProfile: RiskProfile = .moderate
    
    // Computed property for total value
    private var totalValue: Double {
        cryptoValue + stockValue
    }
    
    // Computed property for crypto value
    private var cryptoValue: Double {
        cryptoAssets.reduce(0.0) { $0 + $1.value }
    }
    
    // Computed property for stock value
    private var stockValue: Double {
        stocks.reduce(0.0) { $0 + $1.value }
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(spacing: 24) {
                        // Portfolio Card
                        PortfolioCard(totalValue: totalValue, cryptoValue: cryptoValue, stockValue: stockValue)
                        
                        // Performance Metrics
                        HStack {
                            performanceMetricView(title: "7D Change", value: "+5.2%", trend: .up)
                            Divider().background(Color.white.opacity(0.2)).frame(height: 40)
                            performanceMetricView(title: "30D Change", value: "+12.8%", trend: .up)
                            Divider().background(Color.white.opacity(0.2)).frame(height: 40)
                            performanceMetricView(title: "YTD", value: "+21.4%", trend: .up)
                        }
                        .padding(.vertical, 8)
                        
                        // Performance Chart
                        performanceChartView()
                        
                        // Investment Recommendations Section
                        investmentRecommendationsView()
                        
                        // Asset Type Selector
                        assetTypeSelector()
                        
                        // Asset List
                        assetListView()
                    }
                    .padding(.bottom, 100)
                }
                
                // Floating Action Button
                FloatingActionButton {
                    showAddAsset = true
                }
            }
            .background(AppTheme.backgroundColor.ignoresSafeArea())
            .navigationTitle("Assets")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showAddAsset) {
            AddAssetView(assetType: selectedTab == 0 ? .crypto : .stock)
        }
    }
    
    // Performance Chart View
    private func performanceChartView() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with Portfolio Value and Change
            VStack(alignment: .leading, spacing: 8) {
                Text("Portfolio Value")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                HStack(alignment: .bottom, spacing: 8) {
                    Text("$\(String(format: "%.2f", totalValue))")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    // Sample change percentage - replace with actual calculation
                    Text("+12.4%")
                        .font(.headline)
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            
            // Time period selector with modern style
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach([
                        ("24H", TimePeriod.week),
                        ("1W", TimePeriod.week),
                        ("1M", TimePeriod.month),
                        ("3M", TimePeriod.threeMonths),
                        ("1Y", TimePeriod.year),
                        ("ALL", TimePeriod.all)
                    ], id: \.0) { period, value in
                        Button(action: {
                            withAnimation { selectedTimePeriod = value }
                        }) {
                            Text(period)
                                .font(.subheadline)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    selectedTimePeriod == value ?
                                        Color.blue.opacity(0.3) :
                                        Color.gray.opacity(0.2)
                                )
                                .foregroundColor(
                                    selectedTimePeriod == value ?
                                        .white :
                                        .gray
                                )
                                .cornerRadius(20)
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Enhanced Chart View
            ChartView(height: 200)
                .padding(.top, 8)
            
            // Key Statistics
            VStack(alignment: .leading, spacing: 16) {
                Text("Key Statistics")
                    .font(.headline)
                    .foregroundColor(.white)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    StatisticCard(
                        title: "24h High",
                        value: "$69,420",
                        trend: .up
                    )
                    StatisticCard(
                        title: "24h Low",
                        value: "$65,400",
                        trend: .down
                    )
                    StatisticCard(
                        title: "Portfolio Beta",
                        value: "1.2",
                        trend: .neutral
                    )
                    StatisticCard(
                        title: "Sharpe Ratio",
                        value: "2.1",
                        trend: .up
                    )
                }
            }
            .padding()
            .background(Color.black.opacity(0.3))
            .cornerRadius(16)
        }
        .padding(.horizontal)
    }
    
    // Modern Chart View Component
    private struct ChartView: View {
        let height: CGFloat
        
        var body: some View {
            ZStack {
                // Chart background
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.3))
                
                // Sample chart data
                GeometryReader { geometry in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    
                    Path { path in
                        let points = [0.2, 0.4, 0.35, 0.5, 0.7, 0.6, 0.8, 0.9]
                        let stepX = width / CGFloat(points.count - 1)
                        
                        path.move(to: CGPoint(x: 0, y: height * (1 - CGFloat(points[0]))))
                        
                        for i in 1..<points.count {
                            let control1 = CGPoint(
                                x: stepX * CGFloat(i - 1) + stepX * 0.5,
                                y: height * (1 - CGFloat(points[i - 1]))
                            )
                            let control2 = CGPoint(
                                x: stepX * CGFloat(i) - stepX * 0.5,
                                y: height * (1 - CGFloat(points[i]))
                            )
                            let point = CGPoint(
                                x: stepX * CGFloat(i),
                                y: height * (1 - CGFloat(points[i]))
                            )
                            
                            path.addCurve(to: point, control1: control1, control2: control2)
                        }
                    }
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 2
                    )
                    
                    // Gradient fill
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.2),
                            Color.purple.opacity(0.1),
                            Color.clear
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .mask(
                        Path { path in
                            let points = [0.2, 0.4, 0.35, 0.5, 0.7, 0.6, 0.8, 0.9]
                            let stepX = width / CGFloat(points.count - 1)
                            
                            path.move(to: CGPoint(x: 0, y: height))
                            path.addLine(to: CGPoint(x: 0, y: height * (1 - CGFloat(points[0]))))
                            
                            for i in 1..<points.count {
                                let point = CGPoint(
                                    x: stepX * CGFloat(i),
                                    y: height * (1 - CGFloat(points[i]))
                                )
                                path.addLine(to: point)
                            }
                            
                            path.addLine(to: CGPoint(x: width, y: height))
                            path.closeSubpath()
                        }
                    )
                }
            }
            .frame(height: height)
        }
    }

    // Modern Statistic Card Component
    private struct StatisticCard: View {
        let title: String
        let value: String
        let trend: TrendDirection
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                HStack(alignment: .bottom, spacing: 4) {
                    Text(value)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Image(systemName: trend.icon)
                        .font(.caption)
                        .foregroundColor(trend.color)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(trend.color.opacity(0.2), lineWidth: 1)
                    )
            )
            .animation(.easeInOut, value: trend)
        }
    }

    // Enhanced TrendDirection
    enum TrendDirection {
        case up, down, neutral
        
        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .neutral: return "minus"
            }
        }
        
        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            case .neutral: return .gray
            }
        }
    }
    
    // Investment Recommendations View
    private func investmentRecommendationsView() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recommendations")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Button(action: {
                    // Action to update risk profile
                }) {
                    Text("Risk Profile: \(riskProfile.rawValue)")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(12)
                        .foregroundColor(.white)
                }
            }
            
            // Sample Recommendations
            VStack(spacing: 12) {
                recommendationCard(
                    title: "Diversify Portfolio",
                    description: "Your portfolio is heavily weighted in crypto. Consider adding more stock positions to balance risk.",
                    actionText: "View Suggestions",
                    iconName: "chart.pie.fill"
                )
                
                recommendationCard(
                    title: "New Opportunity",
                    description: "Based on your interest in tech stocks, consider adding NVDA which aligns with your risk profile.",
                    actionText: "Learn More",
                    iconName: "sparkles"
                )
            }
        }
        .padding(.horizontal)
        .padding(.top, 16)
    }
    
    // Asset Type Selector
    private func assetTypeSelector() -> some View {
        HStack(spacing: 0) {
            ForEach([0, 1], id: \.self) { index in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: index == 0 ? "bitcoinsign.circle.fill" : "chart.line.uptrend.xyaxis")
                        Text(index == 0 ? "Crypto" : "Stocks")
                            .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(selectedTab == index ? 
                        Color.blue.opacity(0.2) : 
                        Color.clear)
                    .foregroundColor(selectedTab == index ? 
                        .white : 
                        .gray)
                }
            }
        }
        .background(Color.black.opacity(0.3))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    // Asset List View
    private func assetListView() -> some View {
        LazyVStack(spacing: 16) {
            if selectedTab == 0 {
                if cryptoAssets.isEmpty {
                    emptyStateView(type: "crypto assets")
                } else {
                    ForEach(cryptoAssets) { asset in
                        AssetCardView(
                            symbol: asset.symbol,
                            name: asset.name,
                            amount: asset.amount,
                            value: asset.value,
                            iconName: asset.iconName,
                            onDelete: {
                                withAnimation {
                                    modelContext.delete(asset)
                                }
                            }
                        )
                    }
                }
            } else if selectedTab == 1 {
                if stocks.isEmpty {
                    emptyStateView(type: "stocks")
                } else {
                    ForEach(stocks) { stock in
                        AssetCardView(
                            symbol: stock.symbol,
                            name: stock.name,
                            amount: stock.shares,
                            value: stock.value,
                            iconName: "chart.line.uptrend.xyaxis.circle.fill",
                            onDelete: {
                                withAnimation {
                                    modelContext.delete(stock)
                                }
                            }
                        )
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    private func emptyStateView(type: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: selectedTab == 0 ? "bitcoinsign.circle" : "chart.line.uptrend.xyaxis")
                .font(.system(size: 64))
                .foregroundColor(.gray.opacity(0.3))
            
            VStack(spacing: 8) {
                Text("No \(type) yet")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.8))
                
                Text("Tap + to add your first asset")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    // Add this helper view for performance metrics
    private func performanceMetricView(title: String, value: String, trend: TrendDirection) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            HStack(spacing: 2) {
                Image(systemName: trend == .up ? "arrow.up" : "arrow.down")
                    .font(.caption2)
                    .foregroundColor(trend == .up ? .green : .red)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // Helper view for recommendation cards
    private func recommendationCard(title: String, description: String, actionText: String, iconName: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                
                Button(action: {
                    // Action for recommendation
                }) {
                    Text(actionText)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct AssetCardView: View {
    let symbol: String
    let name: String
    let amount: Double
    let value: Double
    let iconName: String
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Asset Icon
            Image(systemName: iconName)
                .font(.title)
                .foregroundColor(.blue)
                .frame(width: 44, height: 44)
                .background(Color.blue.opacity(0.1))
                .clipShape(Circle())
            
            // Asset Details
            VStack(alignment: .leading, spacing: 4) {
                Text(symbol)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(name)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Asset Value
            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(String(format: "%.2f", value))")
                    .font(.headline)
                    .foregroundColor(.white)
                Text("\(String(format: "%.4f", amount))")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// Asset Type Enum
enum AssetType {
    case crypto
    case stock
}

// Add Asset View
struct AddAssetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let assetType: AssetType
    
    @State private var symbol = ""
    @State private var name = ""
    @State private var amount = ""
    @State private var price = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Symbol", text: $symbol)
                    TextField("Name", text: $name)
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    TextField("Price", text: $price)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle(assetType == .crypto ? "Add Crypto" : "Add Stock")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addAsset()
                    }
                    .disabled(symbol.isEmpty || name.isEmpty || amount.isEmpty || price.isEmpty)
                }
            }
        }
    }
    
    private func addAsset() {
        guard let amountValue = Double(amount),
              let priceValue = Double(price) else { return }
        
        if assetType == .crypto {
            let asset = CryptoAsset(
                symbol: symbol.uppercased(),
                name: name,
                amount: amountValue,
                price: priceValue,
                iconName: "bitcoinsign.circle.fill"
            )
            modelContext.insert(asset)
        } else if assetType == .stock {
            let stock = Stock(
                symbol: symbol.uppercased(),
                name: name,
                shares: amountValue,
                price: priceValue
            )
            modelContext.insert(stock)
        }
        
        dismiss()
    }
}

// Add this enum for trend directions
enum TrendDirection {
    case up, down, neutral
    
    var icon: String {
        switch self {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .neutral: return "minus"
        }
    }
    
    var color: Color {
        switch self {
        case .up: return .green
        case .down: return .red
        case .neutral: return .gray
        }
    }
}

// Add this enum and state variable at the class level
enum TimePeriod {
    case week, month, threeMonths, year, all
}

// Add this enum and state variable at the class level
enum RiskProfile: String {
    case conservative = "Conservative"
    case moderate = "Moderate"
    case aggressive = "Aggressive"
}

struct PortfolioCard: View {
    let totalValue: Double
    let cryptoValue: Double
    let stockValue: Double

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Portfolio Overview")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                Spacer()
                Text("$\(String(format: "%.2f", totalValue))")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }
            // Portfolio Allocation Chart
            HStack(spacing: 0) {
                ForEach([
                    ("Crypto", cryptoValue, Color.purple),
                    ("Stocks", stockValue, Color.green)
                ], id: \.0) { assetType, value, color in
                    let percentage = totalValue > 0 ? value / totalValue : 0
                    VStack {
                        Rectangle()
                            .fill(color)
                            .frame(height: 24)
                            .overlay(
                                Text(percentage > 0.1 ? "\(Int(percentage * 100))%" : "")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            )
                        Text(assetType)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(width: UIScreen.main.bounds.width * 0.8 * max(0.05, percentage))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
        .padding(20)
        .background(
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
                GeometryReader { geometry in
                    Path { path in
                        let width = geometry.size.width
                        let height = geometry.size.height
                        for i in stride(from: 0, to: width, by: 20) {
                            path.move(to: CGPoint(x: i, y: 0))
                            path.addLine(to: CGPoint(x: i + 10, y: height))
                        }
                    }
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                }
            }
        )
        .shadow(color: Color.blue.opacity(0.3), radius: 20, x: 0, y: 10)
        .padding(.horizontal)
    }
}

#Preview {
    MoreView()
        .modelContainer(for: [CryptoAsset.self, Stock.self], inMemory: true)
}
