import SwiftUI

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    let isOutlined: Bool
    
    init(title: String, isOutlined: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isOutlined = isOutlined
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(isOutlined ? AppTheme.accentColor : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    Group {
                        if isOutlined {
                            RoundedRectangle(cornerRadius: 30)
                                .stroke(AppTheme.accentColor, lineWidth: 1)
                                .background(Color.clear)
                        } else {
                            RoundedRectangle(cornerRadius: 30)
                                .fill(AppTheme.accentColor)
                        }
                    }
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VStack(spacing: 20) {
        PrimaryButton(title: "Withdraw") {}
        PrimaryButton(title: "Deposit", isOutlined: true) {}
    }
    .padding()
    .background(AppTheme.backgroundColor)
} 