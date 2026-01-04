//
//  PaywallView.swift
//  Park Safe
//
//  Created by Sandeep Acharya on 04/01/26.
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @ObservedObject var subscriptionManager = SubscriptionManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var isPurchasing = false
    @State private var showError = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.2),
                        Color(red: 0.15, green: 0.1, blue: 0.25)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Features list
                        featuresSection
                        
                        // Pricing
                        pricingSection
                        
                        // Subscribe button
                        subscribeButton
                        
                        // Restore purchases
                        restoreButton
                        
                        // Terms
                        termsSection
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.white.opacity(0.7))
                            .font(.title2)
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(subscriptionManager.errorMessage ?? "An error occurred")
            }
            .onChange(of: subscriptionManager.errorMessage) { _, newValue in
                showError = newValue != nil
            }
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Pro badge
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.orange, .yellow],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.white)
            }
            .shadow(color: .orange.opacity(0.5), radius: 20)
            
            Text("Continue Using ParkSafe")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            if subscriptionManager.isTrialExpired {
                Text("Your 7-day trial has ended")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            } else {
                Text("\(subscriptionManager.trialDaysRemaining) days left in your trial")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - Features
    
    private var featuresSection: some View {
        VStack(spacing: 12) {
            ForEach(ProFeature.allCases, id: \.self) { feature in
                FeatureRow(feature: feature)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Pricing
    
    private var pricingSection: some View {
        VStack(spacing: 8) {
            if let product = subscriptionManager.monthlyProduct {
                Text(product.displayPrice)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("per month")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            } else {
                Text("$2.99")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("per month")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Text("Cancel anytime")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
                .padding(.top, 4)
        }
        .padding(.vertical)
    }
    
    // MARK: - Subscribe Button
    
    private var subscribeButton: some View {
        Button {
            Task {
                await subscribe()
            }
        } label: {
            HStack {
                if isPurchasing || subscriptionManager.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Subscribe Now")
                        .fontWeight(.bold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [.orange, .pink],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(16)
            .shadow(color: .orange.opacity(0.4), radius: 10, y: 5)
        }
        .disabled(isPurchasing || subscriptionManager.isLoading || subscriptionManager.monthlyProduct == nil)
    }
    
    // MARK: - Restore Button
    
    private var restoreButton: some View {
        Button {
            Task {
                await subscriptionManager.restorePurchases()
                if subscriptionManager.isPro {
                    dismiss()
                }
            }
        } label: {
            Text("Restore Purchases")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
    }
    
    // MARK: - Terms
    
    private var termsSection: some View {
        VStack(spacing: 8) {
            Text("Subscription automatically renews unless cancelled at least 24 hours before the end of the current period. Manage subscriptions in Settings.")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
            
            HStack(spacing: 16) {
                Link("Terms of Use", destination: URL(string: "https://apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                Link("Privacy Policy", destination: URL(string: "https://apple.com/privacy/")!)
            }
            .font(.caption2)
            .foregroundColor(.white.opacity(0.5))
        }
        .padding(.top)
    }
    
    // MARK: - Actions
    
    private func subscribe() async {
        guard let product = subscriptionManager.monthlyProduct else { return }
        
        isPurchasing = true
        defer { isPurchasing = false }
        
        do {
            let success = try await subscriptionManager.purchase(product)
            if success {
                dismiss()
            }
        } catch {
            subscriptionManager.errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let feature: ProFeature
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: feature.iconName)
                .font(.title2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange, .yellow],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(feature.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(feature.description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Pro Badge View (for use elsewhere in app)

struct ProBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "crown.fill")
                .font(.caption2)
            Text("PRO")
                .font(.caption2)
                .fontWeight(.bold)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            LinearGradient(
                colors: [.orange, .yellow],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(8)
    }
}

// MARK: - Upgrade Button (for use in locked features)

struct UpgradeButton: View {
    @State private var showPaywall = false
    var label: String = "Upgrade to Pro"
    
    var body: some View {
        Button {
            showPaywall = true
        } label: {
            HStack {
                Image(systemName: "crown.fill")
                Text(label)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [.orange, .pink],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
}

#Preview {
    PaywallView()
}
