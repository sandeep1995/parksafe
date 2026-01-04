//
//  SubscriptionManager.swift
//  Park Safe
//
//  Created by Sandeep Acharya on 04/01/26.
//

import Foundation
import StoreKit
import Combine

enum SubscriptionProduct: String, CaseIterable {
    case monthlyPro = "com.parksafe.pro.monthly"
    
    var displayName: String {
        switch self {
        case .monthlyPro:
            return "Pro Monthly"
        }
    }
}

enum SubscriptionStatus {
    case notSubscribed
    case subscribed
    case expired
    case revoked
}

@MainActor
class SubscriptionManager: ObservableObject {
    let objectWillChange = ObservableObjectPublisher()
    
    static let shared = SubscriptionManager()
    
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published private(set) var subscriptionStatus: SubscriptionStatus = .notSubscribed {
        didSet { objectWillChange.send() }
    }
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    
    private var updateListenerTask: Task<Void, Error>?
    
    var isPro: Bool {
        subscriptionStatus == .subscribed
    }
    
    var monthlyProduct: Product? {
        products.first { $0.id == SubscriptionProduct.monthlyPro.rawValue }
    }
    
    private init() {
        // Start listening for transactions after init completes
        Task { @MainActor [weak self] in
            self?.updateListenerTask = self?.listenForTransactions()
            await self?.loadProducts()
            await self?.updateSubscriptionStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Load Products
    
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let productIDs = SubscriptionProduct.allCases.map { $0.rawValue }
            products = try await Product.products(for: productIDs)
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
            print("Failed to load products: \(error)")
        }
    }
    
    // MARK: - Purchase
    
    func purchase(_ product: Product) async throws -> Bool {
        isLoading = true
        defer { isLoading = false }
        
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updateSubscriptionStatus()
            await transaction.finish()
            return true
            
        case .userCancelled:
            return false
            
        case .pending:
            errorMessage = "Purchase is pending approval"
            return false
            
        @unknown default:
            return false
        }
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
        } catch {
            errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Update Subscription Status
    
    func updateSubscriptionStatus() async {
        var hasActiveSubscription = false
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                if transaction.productID == SubscriptionProduct.monthlyPro.rawValue {
                    if transaction.revocationDate == nil {
                        hasActiveSubscription = true
                        purchasedProductIDs.insert(transaction.productID)
                    } else {
                        purchasedProductIDs.remove(transaction.productID)
                    }
                }
            } catch {
                print("Transaction verification failed: \(error)")
            }
        }
        
        subscriptionStatus = hasActiveSubscription ? .subscribed : .notSubscribed
    }
    
    // MARK: - Transaction Listener
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached { [weak self] in
            for await result in Transaction.updates {
                do {
                    guard let self = self else { return }
                    let transaction = try await self.checkVerified(result)
                    await self.updateSubscriptionStatus()
                    await transaction.finish()
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - Verification
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Subscription Info
    
    func getSubscriptionInfo() async -> (expirationDate: Date?, isAutoRenewing: Bool)? {
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if transaction.productID == SubscriptionProduct.monthlyPro.rawValue {
                    return (transaction.expirationDate, transaction.revocationDate == nil)
                }
            } catch {
                continue
            }
        }
        return nil
    }
}
