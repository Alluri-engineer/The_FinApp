import Foundation
import SwiftData

@Model
final class CryptoAsset {
    @Attribute(.unique) var id: UUID
    var symbol: String
    var name: String
    var amount: Double
    var price: Double
    var iconName: String
    
    // Fix the incorrect relationship inverse
    // @Relationship(inverse: \Wallet.transactions) var wallet: Wallet?
    var wallet: Wallet?
    
    var value: Double {
        return amount * price
    }
    
    init(symbol: String, name: String, amount: Double, price: Double, iconName: String) {
        self.id = UUID()
        self.symbol = symbol
        self.name = name
        self.amount = amount
        self.price = price
        self.iconName = iconName
        self.wallet = nil
    }
} 