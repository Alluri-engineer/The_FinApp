import SwiftUI
import SwiftData

struct AssetDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var asset: CryptoAsset
    
    var body: some View {
        VStack {
            Text("Asset Detail")
                .font(.title)
            
            Text("This view is deprecated and will be removed in a future update.")
                .foregroundColor(.red)
            
            Button("Go Back") {
                dismiss()
            }
            .padding()
        }
        .padding()
    }
}

#Preview {
    let asset = CryptoAsset(
        symbol: "BTC",
        name: "Bitcoin",
        amount: 1.0,
        price: 50000.0,
        iconName: "bitcoinsign.circle.fill"
    )
    
    return AssetDetailView(asset: asset)
} 