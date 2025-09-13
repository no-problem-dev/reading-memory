import SwiftUI

struct BookNoteContentView: View {
    let book: Book
    @Bindable var viewModel: BookNoteViewModel
    @FocusState private var isTextEditorFocused: Bool
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
                .onTapGesture {
                    isTextEditorFocused = false
                }
            
            VStack(spacing: 0) {
                // Header Section for consistency with chat tab
                HStack {
                    Text("読書メモ")
                        .font(.subheadline)
                        .foregroundColor(Color(.secondaryLabel))
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "note.text")
                            .font(.system(size: 14))
                        Text("通常メモ")
                            .font(.caption)
                    }
                    .foregroundColor(Color(.secondaryLabel))
                }
                .padding(.horizontal)
                .padding(.vertical, MemorySpacing.sm)
                .background(Color(.tertiarySystemBackground))
                .overlay(
                    Rectangle()
                        .fill(Color(.separator))
                        .frame(height: 0.5),
                    alignment: .bottom
                )
                
                ScrollView {
                    VStack(spacing: MemorySpacing.lg) {
                        // Book Info Header
                        bookInfoHeader(book: book)
                        
                        // Note Editor
                        noteEditor()
                        
                        // Save Button
                        saveButton()
                        
                        // Save Confirmation
                        if viewModel.showingSaveConfirmation {
                            saveConfirmationView()
                        }
                    }
                    .padding()
                }
                .onTapGesture {
                    isTextEditorFocused = false
                }
            }
        }
        .alert("エラー", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完了") {
                    isTextEditorFocused = false
                }
            }
        }
    }
    
    @ViewBuilder
    private func bookInfoHeader(book: Book) -> some View {
        HStack(spacing: MemorySpacing.md) {
            // Cover Image
            BookCoverView(imageId: book.coverImageId, size: .custom(width: 60, height: 90))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(book.displayTitle)
                    .font(.headline)
                    .lineLimit(2)
                    .foregroundColor(Color(.label))
                
                if !book.displayAuthor.isEmpty {
                    Text(book.displayAuthor)
                        .font(.subheadline)
                        .foregroundColor(Color(.secondaryLabel))
                        .lineLimit(1)
                }
                
                HStack {
                    Image(systemName: statusIcon(for: book.status))
                        .font(.caption)
                    Text(book.status.displayName)
                        .font(.caption)
                }
                .foregroundColor(statusColor(for: book.status))
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(MemoryRadius.medium)
    }
    
    @ViewBuilder
    private func noteEditor() -> some View {
        VStack(alignment: .leading, spacing: MemorySpacing.sm) {
            HStack {
                Label("メモ", systemImage: "note.text")
                    .font(.headline)
                    .foregroundColor(Color(.label))
                
                Spacer()
                
                if !viewModel.noteText.isEmpty {
                    Text("\(viewModel.noteText.count)文字")
                        .font(.caption)
                        .foregroundColor(Color(.tertiaryLabel))
                }
            }
            
            ZStack(alignment: .topLeading) {
                // Placeholder
                if viewModel.noteText.isEmpty {
                    Text("ここに読書メモを入力...")
                        .foregroundColor(Color(.placeholderText))
                        .padding(.horizontal, 13)
                        .padding(.vertical, 12)
                        .allowsHitTesting(false)
                }
                
                TextEditor(text: $viewModel.noteText)
                    .focused($isTextEditorFocused)
                    .padding(8)
                    .scrollContentBackground(.hidden)
                    .background(Color(.secondarySystemBackground))
                    .foregroundColor(Color(.label))
                    .tint(MemoryTheme.Colors.primaryBlue)
            }
            .background(Color(.secondarySystemBackground))
            .cornerRadius(MemoryRadius.small)
            .frame(minHeight: 300)
            .overlay(
                RoundedRectangle(cornerRadius: MemoryRadius.small)
                    .stroke(
                        isTextEditorFocused ? MemoryTheme.Colors.primaryBlue : Color(.separator),
                        lineWidth: isTextEditorFocused ? 2 : 0.5
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: isTextEditorFocused)
            
            Text("読書中に感じたことや考えたこと、重要なポイントなどを自由に記録できます")
                .font(.caption)
                .foregroundColor(Color(.secondaryLabel))
        }
    }
    
    @ViewBuilder
    private func saveButton() -> some View {
        Button {
            Task {
                await viewModel.saveNote()
            }
        } label: {
            HStack {
                Image(systemName: "square.and.arrow.down")
                Text("メモを保存")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                viewModel.isLoading ? Color(.systemGray) : MemoryTheme.Colors.primaryBlue
            )
            .cornerRadius(MemoryRadius.medium)
        }
        .disabled(viewModel.isLoading)
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private func saveConfirmationView() -> some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(MemoryTheme.Colors.success)
            Text("メモを保存しました")
                .font(.subheadline)
                .foregroundColor(Color(.label))
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(MemoryRadius.medium)
        .memoryShadow(.soft)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    private func statusIcon(for status: ReadingStatus) -> String {
        switch status {
        case .wantToRead:
            return "bookmark"
        case .reading:
            return "book.pages"
        case .completed:
            return "checkmark.circle"
        case .dnf:
            return "xmark.circle"
        }
    }
    
    private func statusColor(for status: ReadingStatus) -> Color {
        switch status {
        case .wantToRead:
            return MemoryTheme.Colors.primaryBlue
        case .reading:
            return MemoryTheme.Colors.goldenMemory
        case .completed:
            return MemoryTheme.Colors.success
        case .dnf:
            return Color(.systemGray)
        }
    }
}