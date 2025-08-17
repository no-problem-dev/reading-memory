import SwiftUI

struct BookRegistrationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ServiceContainer.shared.makeBookRegistrationViewModel()
    
    @State private var title = ""
    @State private var author = ""
    @State private var isbn = ""
    @State private var publisher = ""
    @State private var publishedDate = Date()
    @State private var pageCount = ""
    @State private var description = ""
    @State private var showDatePicker = false
    @State private var hasPublishedDate = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("基本情報") {
                    TextField("タイトル *", text: $title)
                    TextField("著者 *", text: $author)
                    TextField("ISBN", text: $isbn)
                        .keyboardType(.numberPad)
                    TextField("出版社", text: $publisher)
                }
                
                Section("詳細情報") {
                    HStack {
                        Text("出版日")
                        Spacer()
                        if hasPublishedDate {
                            Text(publishedDate.formatted(date: .abbreviated, time: .omitted))
                                .foregroundColor(.secondary)
                                .onTapGesture {
                                    showDatePicker.toggle()
                                }
                        } else {
                            Button("設定する") {
                                hasPublishedDate = true
                                showDatePicker = true
                            }
                        }
                    }
                    
                    if showDatePicker {
                        DatePicker("出版日",
                                   selection: $publishedDate,
                                   displayedComponents: .date)
                            .datePickerStyle(.graphical)
                    }
                    
                    TextField("ページ数", text: $pageCount)
                        .keyboardType(.numberPad)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("説明")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextEditor(text: $description)
                            .frame(minHeight: 100)
                    }
                }
            }
            .navigationTitle("本を登録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveBook()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.isEmpty || author.isEmpty)
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.3))
                }
            }
            .alert("エラー", isPresented: $viewModel.showError) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                Text(viewModel.errorMessage ?? "不明なエラーが発生しました")
            }
        }
    }
    
    private func saveBook() {
        Task {
            let book = Book(
                isbn: isbn.isEmpty ? nil : isbn.trimmingCharacters(in: .whitespacesAndNewlines),
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                author: author.trimmingCharacters(in: .whitespacesAndNewlines),
                publisher: publisher.isEmpty ? nil : publisher.trimmingCharacters(in: .whitespacesAndNewlines),
                publishedDate: hasPublishedDate ? publishedDate : nil,
                pageCount: Int(pageCount),
                description: description.isEmpty ? nil : description.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            
            let success = await viewModel.registerBook(book)
            if success {
                dismiss()
            }
        }
    }
}

#Preview {
    BookRegistrationView()
}