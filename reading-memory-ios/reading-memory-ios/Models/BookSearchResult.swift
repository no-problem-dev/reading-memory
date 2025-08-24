import Foundation

/// 書籍検索結果を表すモデル
/// APIから取得した検索結果を保持し、実際の保存時にBookモデルに変換される
struct BookSearchResult: Identifiable, Equatable {
    let id: String
    
    // 書籍基本情報
    let isbn: String?
    let title: String
    let author: String
    let publisher: String?
    let publishedDate: Date?
    let pageCount: Int?
    let description: String?
    let coverImageUrl: String?  // 外部APIからの画像URL
    let dataSource: BookDataSource
    
    init(
        isbn: String? = nil,
        title: String,
        author: String,
        publisher: String? = nil,
        publishedDate: Date? = nil,
        pageCount: Int? = nil,
        description: String? = nil,
        coverImageUrl: String? = nil,
        dataSource: BookDataSource
    ) {
        self.id = UUID().uuidString
        self.isbn = isbn
        self.title = title
        self.author = author
        self.publisher = publisher
        self.publishedDate = publishedDate
        self.pageCount = pageCount
        self.description = description
        self.coverImageUrl = coverImageUrl
        self.dataSource = dataSource
    }
    
    /// BookSearchResultをBookに変換（保存用）
    /// 注意: この時点ではcoverImageIdはnilで、実際の保存時に画像をアップロードして設定される
    func toBook() -> Book {
        return Book.new(
            isbn: isbn,
            title: title,
            author: author,
            publisher: publisher,
            publishedDate: publishedDate,
            pageCount: pageCount,
            description: description,
            coverImageId: nil,  // 保存時に画像をアップロードして設定
            dataSource: dataSource
        )
    }
}

// MARK: - Computed Properties
extension BookSearchResult {
    var displayTitle: String {
        title.isEmpty ? "無題の本" : title
    }
    
    var displayAuthor: String {
        author.isEmpty ? "著者不明" : author
    }
}