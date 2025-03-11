import Foundation
import SwiftData

@Model
final class Stock {
    @Attribute(.unique) var id: UUID
    var symbol: String
    var name: String
    var shares: Double
    var price: Double
    var iconName: String
    
    var value: Double {
        return shares * price
    }
    
    init(symbol: String, name: String, shares: Double, price: Double, iconName: String = "chart.line.uptrend.xyaxis") {
        self.id = UUID()
        self.symbol = symbol
        self.name = name
        self.shares = shares
        self.price = price
        self.iconName = iconName
    }
} 