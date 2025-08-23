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
                CameraView(scannedISBN: $scannedISBN)
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    VStack(spacing: 16) {
                        Text("バーコードをスキャン")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("本の裏表紙にあるバーコードを\n枠内に合わせてください")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                        
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: 250, height: 100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.yellow, lineWidth: 3)
                                    .opacity(scannedISBN != nil ? 1 : 0)
                                    .animation(.easeInOut(duration: 0.3), value: scannedISBN != nil)
                            )
                    }
                    .padding(.bottom, 100)
                    
                    Spacer()
                    
                    Button(action: {
                        showManualEntry = true
                    }) {
                        Label("手動で入力", systemImage: "keyboard")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(20)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .background(Color.black)
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
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                    .overlay(
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)
                            Text("書籍情報を検索中...")
                                .foregroundColor(.white)
                        }
                    )
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
    
    private func parseBookInfo(from data: [String: Any], dataSource: BookDataSource = .manual) -> Book? {
        guard let isbn = data["isbn"] as? String,
              let title = data["title"] as? String,
              let author = data["author"] as? String else {
            return nil
        }
        
        let publisher = data["publisher"] as? String
        let pageCount = data["pageCount"] as? Int
        let description = data["description"] as? String
        let coverUrl = data["coverUrl"] as? String
        
        var publishedDate: Date?
        if let dateString = data["publishedDate"] as? String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            publishedDate = formatter.date(from: dateString)
        }
        
        guard let userId = AuthService.shared.currentUser?.uid else { return nil }
        return Book(
            id: UUID().uuidString,
            isbn: isbn,
            title: title,
            author: author,
            publisher: publisher,
            publishedDate: publishedDate,
            pageCount: pageCount,
            description: description,
            coverImageUrl: coverUrl,
            dataSource: dataSource,
            status: .wantToRead,
            addedDate: Date(),
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
        scannedISBN = nil
    }
}

// カメラビュー
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

// カメラビューコントローラー
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

// 手動ISBN入力ビュー
struct ManualISBNEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isbn = ""
    let onSubmit: (String) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("ISBN (10桁または13桁)", text: $isbn)
                        .keyboardType(.numberPad)
                } footer: {
                    Text("本の裏表紙に記載されているISBNコードを入力してください")
                        .font(.caption)
                }
            }
            .navigationTitle("ISBNを入力")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("検索") {
                        onSubmit(isbn)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(isbn.isEmpty)
                }
            }
        }
    }
}
