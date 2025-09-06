import SwiftUI
import RevenueCat

struct PaywallView: View {
    @Environment(SubscriptionStateStore.self) private var subscriptionState
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPackage: Package?
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var offerings: Offerings?
    
    private let subscriptionService = SubscriptionService.shared
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // ヘッダー
                    headerSection
                    
                    // 特典リスト
                    featuresSection
                    
                    // 価格オプション
                    if let offerings = offerings {
                        pricingSection(offerings)
                    } else {
                        ProgressView()
                            .frame(height: 150)
                    }
                    
                    // 購入ボタン
                    purchaseButton
                    
                    // 法的情報
                    legalSection
                }
                .padding()
            }
            .navigationTitle("メモリープラス")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
            .task {
                do {
                    offerings = try await subscriptionService.loadOfferings()
                    // デフォルトで年額プランを選択
                    if let yearlyPackage = offerings?.current?.availablePackages.first(where: { 
                        $0.storeProduct.productIdentifier.contains("yearly") 
                    }) {
                        selectedPackage = yearlyPackage
                    }
                } catch {
                    print("Error loading offerings: \(error)")
                }
            }
            .onChange(of: subscriptionState.isSubscribed) { _, isSubscribed in
                if isSubscribed {
                    dismiss()
                }
            }
            .alert("エラー", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundStyle(.linearGradient(
                    colors: [.purple, .blue],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            
            Text("メモリープラスで\nもっと豊かな読書体験を")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("すべての機能を制限なく使えます")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical)
    }
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(SubscriptionStateStore.PremiumFeature.allCases, id: \.self) { feature in
                FeatureRow(feature: feature)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
    
    private func pricingSection(_ offerings: Offerings) -> some View {
        VStack(spacing: 12) {
            if let packages = offerings.current?.availablePackages {
                ForEach(packages) { package in
                    PriceOptionView(
                        package: package,
                        isSelected: selectedPackage?.id == package.id,
                        onTap: {
                            selectedPackage = package
                        }
                    )
                }
            }
        }
    }
    
    private var purchaseButton: some View {
        VStack(spacing: 12) {
            Button {
                Task {
                    await purchaseSelectedPackage()
                }
            } label: {
                HStack {
                    if isPurchasing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text("購入する")
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(selectedPackage == nil ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
                .fontWeight(.semibold)
            }
            .disabled(selectedPackage == nil || isPurchasing)
            
            Button("購入を復元") {
                Task {
                    await restorePurchases()
                }
            }
            .font(.footnote)
            .foregroundColor(.blue)
        }
    }
    
    private var legalSection: some View {
        VStack(spacing: 8) {
            Text("・サブスクリプションは自動的に更新されます")
            Text("・いつでもApp Storeから解約できます")
            
            HStack(spacing: 16) {
                Link("利用規約", destination: URL(string: "https://taniguchi-kyoichi.com/products/dokusho-memory/terms")!)
                Link("プライバシーポリシー", destination: URL(string: "https://taniguchi-kyoichi.com/products/dokusho-memory/privacy")!)
            }
            .font(.footnote)
            .foregroundColor(.blue)
            .padding(.top, 8)
        }
        .font(.caption)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
        .padding(.vertical)
    }
    
    private func purchaseSelectedPackage() async {
        guard let package = selectedPackage else { return }
        
        isPurchasing = true
        defer { isPurchasing = false }
        
        do {
            let success = try await subscriptionService.purchase(package)
            if success {
                // 状態更新を待つ
                await subscriptionState.refreshStatus()
                dismiss()
            }
        } catch {
            if let error = error as? RevenueCat.ErrorCode {
                switch error {
                case .purchaseCancelledError:
                    // ユーザーがキャンセルした場合は何もしない
                    break
                default:
                    errorMessage = "購入に失敗しました: \(error.localizedDescription)"
                    showError = true
                }
            } else {
                errorMessage = "購入に失敗しました"
                showError = true
            }
        }
    }
    
    private func restorePurchases() async {
        isPurchasing = true
        defer { isPurchasing = false }
        
        do {
            let success = try await subscriptionService.restore()
            if success {
                // 状態更新を待つ
                await subscriptionState.refreshStatus()
                dismiss()
            } else {
                errorMessage = "復元できるサブスクリプションが見つかりませんでした"
                showError = true
            }
        } catch {
            errorMessage = "復元に失敗しました"
            showError = true
        }
    }
}

struct FeatureRow: View {
    let feature: SubscriptionStateStore.PremiumFeature
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: feature.icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(feature.rawValue)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Text(feature.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct PriceOptionView: View {
    let package: Package
    let isSelected: Bool
    let onTap: () -> Void
    
    var isYearly: Bool {
        package.storeProduct.productIdentifier.contains("yearly")
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(package.storeProduct.localizedTitle)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(package.storeProduct.localizedPriceString)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    if isYearly {
                        Text("2ヶ月分お得")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(isSelected ? .blue : .gray)
                }
                
                // RevenueCat's StoreProduct has a different subscriptionPeriod type
                // Show package type instead
                Text(PaywallView.packageDescription(package.packageType))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color(.systemGray4), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// PackageType拡張を削除（RevenueCatの将来の更新と競合する可能性があるため）
extension PaywallView {
    static func packageDescription(_ type: PackageType) -> String {
        switch type {
        case .monthly:
            return "月額プラン"
        case .annual:
            return "年額プラン"
        case .weekly:
            return "週額プラン"
        case .twoMonth:
            return "2ヶ月プラン"
        case .threeMonth:
            return "3ヶ月プラン"
        case .sixMonth:
            return "6ヶ月プラン"
        case .lifetime:
            return "買い切りプラン"
        case .custom:
            return "カスタムプラン"
        @unknown default:
            return "プラン"
        }
    }
}

#Preview {
    PaywallView()
}
