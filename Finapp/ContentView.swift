//
//  ContentView.swift
//  Finapp
//
//  Created by Alluri santosh Varma on 3/7/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 1 // Start with WalletView (middle tab)
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tag(0)
                
                WalletView()
                    .tag(1)
                
                BudgetView()
                    .tag(2)
                
                MoreView()
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // Custom Tab Bar
            HStack(spacing: 0) {
                // Home Tab
                TabBarButton(
                    icon: "house",
                    selectedIcon: "house.fill",
                    title: "Home",
                    isSelected: selectedTab == 0
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = 0
                    }
                }
                .frame(maxWidth: .infinity)
                
                // Wallet Tab (Middle)
                ZStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 56, height: 56)
                        .shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 4)
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = 1
                        }
                    }) {
                        VStack(spacing: 2) {
                            Image(systemName: selectedTab == 1 ? "creditcard.fill" : "creditcard")
                                .font(.system(size: 22, weight: .semibold))
                            Text("Wallet")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(.white)
                    }
                }
                .offset(y: -16)
                
                // Budget Tab
                TabBarButton(
                    icon: "chart.bar",
                    selectedIcon: "chart.bar.fill",
                    title: "Budget",
                    isSelected: selectedTab == 2
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = 2
                    }
                }
                .frame(maxWidth: .infinity)
                
                // Portfolio Tab
                TabBarButton(
                    icon: "chart.pie",
                    selectedIcon: "chart.pie.fill",
                    title: "Portfolio",
                    isSelected: selectedTab == 3
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = 3
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .frame(height: 68)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: -3)
            )
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

struct TabBarButton: View {
    let icon: String
    let selectedIcon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: isSelected ? selectedIcon : icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(isSelected ? .blue : .gray)
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
                
                Text(title)
                    .font(.system(size: 11, weight: isSelected ? .medium : .regular))
                    .foregroundColor(isSelected ? .blue : .gray)
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
            }
            .padding(.top, 8)
        }
    }
}

struct FloatingActionButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.blue)
                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 100) // Adjust to stay above tab bar
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Wallet.self, Transaction.self, CryptoAsset.self, Stock.self], inMemory: true)
        .preferredColorScheme(.dark)
}
