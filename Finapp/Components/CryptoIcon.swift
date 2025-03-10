import SwiftUI

struct CryptoIcon: View {
    let symbol: String
    let iconName: String
    let size: CGFloat
    
    init(symbol: String, iconName: String, size: CGFloat = 40) {
        self.symbol = symbol
        self.iconName = iconName
        self.size = size
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.black)
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: iconColor.opacity(0.3), radius: 10, x: 0, y: 0)
            
            Image(systemName: iconName)
                .resizable()
                .scaledToFit()
                .frame(width: size * 0.5, height: size * 0.5)
                .foregroundColor(iconColor)
        }
    }
    
    private var iconColor: Color {
        switch symbol {
        case "ADA":
            return Color.blue
        case "HEX":
            return Color.orange
        case "Ocean":
            return Color.cyan
        default:
            return Color.white
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        CryptoIcon(symbol: "ADA", iconName: "circle.hexagongrid.fill")
        CryptoIcon(symbol: "HEX", iconName: "hexagon.fill")
        CryptoIcon(symbol: "Ocean", iconName: "circle.grid.3x3.fill")
    }
    .padding()
    .background(AppTheme.backgroundColor)
} 