import SwiftUI
import AVFoundation

struct BarcodeScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ServiceContainer.shared.makeBookRegistrationViewModel()
    @State private var scannedISBN: String?
    @State private var isSearching = false
    @State private var showManualEntry = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showBookRegistration = false
    @State private var foundBook: Book?
    private let authService = AuthService.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Camera view
                CameraView(scannedISBN: $scannedISBN)
                    .ignoresSafeArea()
                
                // Dark overlay
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                // Scanner UI
                VStack {
                    // Top bar with close button
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                                .memoryShadow(.medium)
                        }
                        .padding(.leading, MemorySpacing.md)
                        
                        Spacer()
                    }
                    .padding(.top, MemorySpacing.md)
                    
                    Spacer()
                    
                    // Scanner frame
                    VStack(spacing: MemorySpacing.lg) {
                        // Instructions
                        VStack(spacing: MemorySpacing.sm) {
                            Text("バーコードをスキャン")
                                .font(MemoryTheme.Fonts.title3())
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.5), radius: 4)
                            
                            Text("本の裏表紙にあるバーコードを\n枠内に合わせてください")
                                .font(MemoryTheme.Fonts.subheadline())
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .shadow(color: .black.opacity(0.5), radius: 4)
                        }
                        
                        // Scanner frame
                        ZStack {
                            // Base frame
                            RoundedRectangle(cornerRadius: MemoryRadius.large)
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            MemoryTheme.Colors.primaryBlue.opacity(0.8),
                                            MemoryTheme.Colors.primaryBlueLight.opacity(0.8)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 3
                                )
                                .frame(width: 280, height: 120)
                            
                            // Animated scanning line
                            if scannedISBN == nil {
                                ScanningLineView()
                            }
                            
                            // Success overlay
                            if scannedISBN != nil {
                                RoundedRectangle(cornerRadius: MemoryRadius.large)
                                    .stroke(MemoryTheme.Colors.success, lineWidth: 4)
                                    .frame(width: 280, height: 120)
                                    .overlay(
                                        HStack(spacing: MemorySpacing.sm) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 24))
                                            Text("スキャン成功！")
                                                .font(MemoryTheme.Fonts.headline())
                                        }
                                        .foregroundColor(MemoryTheme.Colors.success)
                                        .padding(MemorySpacing.md)
                                        .background(Color.black.opacity(0.7))
                                        .cornerRadius(MemoryRadius.medium)
                                    )
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .animation(MemoryTheme.Animation.spring, value: scannedISBN != nil)
                    }
                    .padding(.bottom, 100)
                    
                    Spacer()
                    
                    // Manual entry button
                    Button {
                        showManualEntry = true
                    } label: {
                        HStack(spacing: MemorySpacing.xs) {
                            Image(systemName: "keyboard")
                                .font(.system(size: 16))
                            Text("ISBNを手動で入力")
                                .font(MemoryTheme.Fonts.subheadline())
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, MemorySpacing.lg)
                        .padding(.vertical, MemorySpacing.sm)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    MemoryTheme.Colors.inkBlack.opacity(0.6),
                                    MemoryTheme.Colors.inkBlack.opacity(0.4)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(MemoryRadius.full)
                        .memoryShadow(.medium)
                    }
                    .padding(.bottom, MemorySpacing.xl)
                }
            }
        }
        .onChange(of: scannedISBN) { oldValue, newValue in
            if let isbn = newValue {
                searchBook(isbn: isbn)
            }
        }
        .sheet(isPresented: $showManualEntry) {
            ManualISBNEntryView(onSubmit: { isbn in
                searchBook(isbn: isbn)
            })
                    }
        .alert("エラー", isPresented: $showError) {
            Button("OK") {
                scannedISBN = nil
            }
        } message: {
            Text(errorMessage)
        }
        .fullScreenCover(isPresented: $showBookRegistration) {
            if let book = foundBook {
                BookRegistrationView(prefilledBook: book)
                                }
        }
        .overlay {
            if isSearching {
                ZStack {
                    Color.black.opacity(0.8)
                        .ignoresSafeArea()
                    
                    VStack(spacing: MemorySpacing.lg) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                        
                        Text("書籍情報を検索中...")
                            .font(MemoryTheme.Fonts.body())
                            .foregroundColor(.white)
                    }
                    .padding(MemorySpacing.xl)
                    .background(
                        RoundedRectangle(cornerRadius: MemoryRadius.large)
                            .fill(MemoryTheme.Colors.inkBlack.opacity(0.9))
                    )
                    .memoryShadow(.medium)
                }
                .transition(.opacity)
                .animation(MemoryTheme.Animation.fast, value: isSearching)
            }
        }
    }
    
    private func searchBook(isbn: String) {
        isSearching = true
        
        // Check if user is authenticated
        guard AuthService.shared.currentUser != nil else {
            isSearching = false
            showError(message: "ログインが必要です")
            return
        }
        
        Task {
            // 統合検索サービスを使用
            let searchService = UnifiedBookSearchService.shared
            let books = await searchService.searchByISBN(isbn)
            
            await MainActor.run {
                isSearching = false
                
                if let book = books.first {
                    // API から取得した本は public として扱う
                    foundBook = book
                    showBookRegistration = true
                } else {
                    // 見つからない場合は手動入力を促す
                    guard let userId = authService.currentUser?.uid else { return }
                    let manualBook = Book(
                        id: UUID().uuidString,
                        isbn: isbn,
                        title: "",
                        author: "",
                        dataSource: .manual,
                        status: .wantToRead,
                        addedDate: Date(),
                        createdAt: Date(),
                        updatedAt: Date()
                    )
                    foundBook = manualBook
                    showBookRegistration = true
                }
            }
        }
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
        scannedISBN = nil
    }
}

// MARK: - Scanning Line Animation

struct ScanningLineView: View {
    @State private var animating = false
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        MemoryTheme.Colors.primaryBlue.opacity(0.8),
                        MemoryTheme.Colors.primaryBlue,
                        MemoryTheme.Colors.primaryBlue.opacity(0.8),
                        Color.clear
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: 260, height: 2)
            .offset(y: animating ? 50 : -50)
            .animation(
                Animation.easeInOut(duration: 2)
                    .repeatForever(autoreverses: true),
                value: animating
            )
            .onAppear { animating = true }
    }
}

// MARK: - Camera View (UIKit Integration)

struct CameraView: UIViewControllerRepresentable {
    @Binding var scannedISBN: String?
    
    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, CameraViewControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func didScanBarcode(_ isbn: String) {
            parent.scannedISBN = isbn
        }
    }
}

// MARK: - Camera View Controller

protocol CameraViewControllerDelegate: AnyObject {
    func didScanBarcode(_ isbn: String)
}

class CameraViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    weak var delegate: CameraViewControllerDelegate?
    
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var hasScanned = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if captureSession?.isRunning == false {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession?.startRunning()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if captureSession?.isRunning == true {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession?.stopRunning()
            }
        }
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        if (captureSession?.canAddInput(videoInput) ?? false) {
            captureSession?.addInput(videoInput)
        } else {
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if (captureSession?.canAddOutput(metadataOutput) ?? false) {
            captureSession?.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean13, .ean8]
        } else {
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        previewLayer?.frame = view.layer.bounds
        previewLayer?.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer!)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if hasScanned { return }
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            
            // ISBN-13の場合は978または979で始まる
            if stringValue.hasPrefix("978") || stringValue.hasPrefix("979") {
                hasScanned = true
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                delegate?.didScanBarcode(stringValue)
            }
        }
    }
}

// MARK: - Manual ISBN Entry View

struct ManualISBNEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isbn = ""
    let onSubmit: (String) -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        MemoryTheme.Colors.background,
                        MemoryTheme.Colors.secondaryBackground
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: MemorySpacing.lg) {
                    // Header
                    VStack(spacing: MemorySpacing.sm) {
                        Image(systemName: "barcode")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        MemoryTheme.Colors.primaryBlue,
                                        MemoryTheme.Colors.primaryBlueDark
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .padding(.bottom, MemorySpacing.sm)
                        
                        Text("ISBNコードを入力")
                            .font(MemoryTheme.Fonts.title3())
                            .foregroundColor(MemoryTheme.Colors.inkBlack)
                        
                        Text("本の裏表紙に記載されている\n10桁または13桁の数字")
                            .font(MemoryTheme.Fonts.subheadline())
                            .foregroundColor(MemoryTheme.Colors.inkGray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, MemorySpacing.xl)
                    
                    // Input field
                    VStack(alignment: .leading, spacing: MemorySpacing.xs) {
                        Text("ISBN")
                            .font(MemoryTheme.Fonts.caption())
                            .foregroundColor(MemoryTheme.Colors.inkGray)
                        
                        TextField("978-4-123456-78-9", text: $isbn)
                            .font(MemoryTheme.Fonts.title3())
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .padding(MemorySpacing.md)
                            .background(MemoryTheme.Colors.cardBackground)
                            .cornerRadius(MemoryRadius.medium)
                            .memoryShadow(.soft)
                    }
                    .padding(.horizontal, MemorySpacing.xl)
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("キャンセル")
                            .font(MemoryTheme.Fonts.subheadline())
                            .foregroundColor(MemoryTheme.Colors.inkGray)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        onSubmit(isbn)
                        dismiss()
                    } label: {
                        Text("検索")
                            .font(MemoryTheme.Fonts.headline())
                            .foregroundColor(isbn.isEmpty ? MemoryTheme.Colors.inkLightGray : MemoryTheme.Colors.primaryBlue)
                    }
                    .disabled(isbn.isEmpty)
                }
            }
        }
    }
}

#Preview {
    BarcodeScannerView()
        }