import SwiftUI

struct WantToReadDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let book: Book
    let onSave: (Book?) -> Void
    
    @State private var priority: Int
    @State private var plannedReadingDate: Date?
    @State private var reminderEnabled: Bool
    @State private var purchaseLinks: [PurchaseLink]
    @State private var showingAddLink = false
    @State private var editingLink: PurchaseLink?
    
    init(book: Book, onSave: @escaping (Book?) -> Void) {
        self.book = book
        self.onSave = onSave
        _priority = State(initialValue: book.priority ?? 5)
        _plannedReadingDate = State(initialValue: book.plannedReadingDate)
        _reminderEnabled = State(initialValue: book.reminderEnabled)
        _purchaseLinks = State(initialValue: book.purchaseLinks ?? [])
    }
    
    var body: some View {
        NavigationView {
            Form {
                // 本の情報セクション
                Section {
                    HStack(spacing: 12) {
                        BookCoverView(imageId: book.coverImageId, size: .custom(width: 60, height: 84))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(book.title)
                                .font(.headline)
                            Text(book.author)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                
                // 優先度設定
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("優先度")
                            Spacer()
                            Text("\(priority + 1)")
                                .fontWeight(.medium)
                                .foregroundColor(priorityColor)
                        }
                        
                        Slider(value: Binding(
                            get: { Double(priority) },
                            set: { priority = Int($0) }
                        ), in: 0...9, step: 1)
                        .accentColor(priorityColor)
                    }
                } header: {
                    Text("優先度設定")
                } footer: {
                    Text("1が最高優先度、10が最低優先度です")
                }
                
                // 読書予定
                Section {
                    Toggle("読書予定日を設定", isOn: Binding(
                        get: { plannedReadingDate != nil },
                        set: { enabled in
                            if enabled {
                                plannedReadingDate = Date().addingTimeInterval(7 * 24 * 60 * 60) // 1週間後
                            } else {
                                plannedReadingDate = nil
                                reminderEnabled = false
                            }
                        }
                    ))
                    
                    if plannedReadingDate != nil {
                        DatePicker("予定日", selection: Binding(
                            get: { plannedReadingDate ?? Date() },
                            set: { plannedReadingDate = $0 }
                        ), displayedComponents: .date)
                        
                        Toggle("リマインダー", isOn: $reminderEnabled)
                    }
                } header: {
                    Text("読書スケジュール")
                } footer: {
                    if reminderEnabled && plannedReadingDate != nil {
                        Text("予定日にプッシュ通知でお知らせします")
                    }
                }
                
                // 購入リンク
                Section {
                    ForEach(purchaseLinks) { link in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(link.title)
                                    .font(.headline)
                                if let price = link.price {
                                    Text("¥\(Int(price))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Button {
                                if let url = URL(string: link.url) {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                Image(systemName: "arrow.up.right.square")
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            editingLink = link
                        }
                    }
                    .onDelete { indices in
                        purchaseLinks.remove(atOffsets: indices)
                    }
                    
                    Button {
                        showingAddLink = true
                    } label: {
                        Label("購入リンクを追加", systemImage: "plus.circle.fill")
                    }
                } header: {
                    Text("購入リンク")
                }
            }
            .navigationTitle("読みたいリスト設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        let updatedBook = book.updated(
                            priority: priority,
                            plannedReadingDate: plannedReadingDate,
                            reminderEnabled: reminderEnabled,
                            purchaseLinks: purchaseLinks.isEmpty ? nil : purchaseLinks
                        )
                        onSave(updatedBook)
                        dismiss()
                    }
                }
            }
        }
                .sheet(isPresented: $showingAddLink) {
            AddPurchaseLinkView { link in
                purchaseLinks.append(link)
            }
        }
        .sheet(item: $editingLink) { link in
            EditPurchaseLinkView(link: link) { updatedLink in
                if let index = purchaseLinks.firstIndex(where: { $0.id == link.id }) {
                    purchaseLinks[index] = updatedLink
                }
            }
        }
    }
    
    private var priorityColor: Color {
        switch priority {
        case 0...2:
            return MemoryTheme.Colors.primaryBlue
        case 3...5:
            return MemoryTheme.Colors.goldenMemory
        case 6...8:
            return MemoryTheme.Colors.info
        default:
            return .gray
        }
    }
}

// 購入リンク追加ビュー
struct AddPurchaseLinkView: View {
    @Environment(\.dismiss) private var dismiss
    let onAdd: (PurchaseLink) -> Void
    
    @State private var selectedPreset = "カスタム"
    @State private var title = ""
    @State private var url = ""
    @State private var price = ""
    
    let presets = ["カスタム", "Amazon", "楽天ブックス", "紀伊國屋書店"]
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Picker("ストア", selection: $selectedPreset) {
                        ForEach(presets, id: \.self) { preset in
                            Text(preset)
                        }
                    }
                    .onChange(of: selectedPreset) { _, newValue in
                        if newValue != "カスタム" {
                            title = newValue
                        }
                    }
                    
                    if selectedPreset == "カスタム" {
                        TextField("ストア名", text: $title)
                            .memoryTextFieldStyle()
                    }
                    
                    TextField("URL", text: $url)
                        .memoryTextFieldStyle()
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                    
                    TextField("価格（オプション）", text: $price)
                        .memoryTextFieldStyle()
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("購入リンクを追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("追加") {
                        let link = PurchaseLink(
                            title: title.isEmpty ? selectedPreset : title,
                            url: url,
                            price: Double(price)
                        )
                        onAdd(link)
                        dismiss()
                    }
                    .disabled(url.isEmpty || (selectedPreset == "カスタム" && title.isEmpty))
                }
            }
        }
            }
}

// 購入リンク編集ビュー
struct EditPurchaseLinkView: View {
    @Environment(\.dismiss) private var dismiss
    let link: PurchaseLink
    let onUpdate: (PurchaseLink) -> Void
    
    @State private var title: String
    @State private var url: String
    @State private var price: String
    
    init(link: PurchaseLink, onUpdate: @escaping (PurchaseLink) -> Void) {
        self.link = link
        self.onUpdate = onUpdate
        _title = State(initialValue: link.title)
        _url = State(initialValue: link.url)
        _price = State(initialValue: link.price != nil ? String(Int(link.price!)) : "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("ストア名", text: $title)
                        .memoryTextFieldStyle()
                    TextField("URL", text: $url)
                        .memoryTextFieldStyle()
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                    TextField("価格（オプション）", text: $price)
                        .memoryTextFieldStyle()
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("購入リンクを編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        let updatedLink = PurchaseLink(
                            id: link.id,
                            title: title,
                            url: url,
                            price: Double(price),
                            createdAt: link.createdAt
                        )
                        onUpdate(updatedLink)
                        dismiss()
                    }
                    .disabled(title.isEmpty || url.isEmpty)
                }
            }
        }
            }
}