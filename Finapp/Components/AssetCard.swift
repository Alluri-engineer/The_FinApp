import SwiftUI

struct AssetCard: View {
    let symbol: String
    let name: String
    let amount: Double
    let value: Double
    let iconName: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Asset Icon
            CryptoIcon(symbol: symbol, iconName: iconName)
            
            // Asset Info
            VStack(alignment: .leading, spacing: 4) {
                Text(symbol)
                    .font(.headline)
                    .foregroundColor(AppTheme.primaryTextColor)
                
                Text(name)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.secondaryTextColor)
            }
            
            Spacer()
            
            // Asset Amount and Value
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.1f", amount))
                    .font(.headline)
                    .foregroundColor(AppTheme.primaryTextColor)
                
                Text("$ \(String(format: "%.3f", value))")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.secondaryTextColor)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(AppTheme.cardBackgroundColor)
        .cornerRadius(AppTheme.cornerRadius)
    }
}

#Preview {
    VStack {
        AssetCard(
            symbol: "ADA",
            name: "Cardano",
            amount: 67.5,
            value: 2760.75,
            iconName: "circle.hexagongrid.fill"
        )
        
        AssetCard(
            symbol: "HEX",
            name: "Hex Token",
            amount: 7.8,
            value: 4053,
            iconName: "hexagon.fill"
        )
    }
    .padding()
    .background(AppTheme.backgroundColor)
} 