import Foundation

// OpenBD API レスポンスモデル
struct OpenBDResponse: Codable {
    let onix: OpenBDOnix?
    let hanmoto: OpenBDHanmoto?
    let summary: OpenBDSummary?
}

struct OpenBDOnix: Codable {
    let recordReference: String?  // ISBN
    let notificationType: String?
    let productIdentifier: OpenBDProductIdentifier?
    let descriptiveDetail: OpenBDDescriptiveDetail?
    let collateralDetail: OpenBDCollateralDetail?
    let publishingDetail: OpenBDPublishingDetail?
    
    enum CodingKeys: String, CodingKey {
        case recordReference = "RecordReference"
        case notificationType = "NotificationType"
        case productIdentifier = "ProductIdentifier"
        case descriptiveDetail = "DescriptiveDetail"
        case collateralDetail = "CollateralDetail"
        case publishingDetail = "PublishingDetail"
    }
}

struct OpenBDProductIdentifier: Codable {
    let productIDType: String?
    let idValue: String?
    
    enum CodingKeys: String, CodingKey {
        case productIDType = "ProductIDType"
        case idValue = "IDValue"
    }
}

struct OpenBDDescriptiveDetail: Codable {
    let productComposition: String?
    let productForm: String?
    let titleDetail: OpenBDTitleDetail?
    let contributor: [OpenBDContributor]?
    let extent: [OpenBDExtent]?
    
    enum CodingKeys: String, CodingKey {
        case productComposition = "ProductComposition"
        case productForm = "ProductForm"
        case titleDetail = "TitleDetail"
        case contributor = "Contributor"
        case extent = "Extent"
    }
}

struct OpenBDTitleDetail: Codable {
    let titleType: String?
    let titleElement: OpenBDTitleElement?
    
    enum CodingKeys: String, CodingKey {
        case titleType = "TitleType"
        case titleElement = "TitleElement"
    }
}

struct OpenBDTitleElement: Codable {
    let titleElementLevel: String?
    let titleText: OpenBDTitleText?
    
    enum CodingKeys: String, CodingKey {
        case titleElementLevel = "TitleElementLevel"
        case titleText = "TitleText"
    }
}

struct OpenBDTitleText: Codable {
    let content: String?
    let collationkey: String?
}

struct OpenBDContributor: Codable {
    let sequenceNumber: String?
    let contributorRole: [String]?
    let personName: OpenBDPersonName?
    let biographicalNote: String?
    
    enum CodingKeys: String, CodingKey {
        case sequenceNumber = "SequenceNumber"
        case contributorRole = "ContributorRole"
        case personName = "PersonName"
        case biographicalNote = "BiographicalNote"
    }
}

struct OpenBDPersonName: Codable {
    let content: String?
    let collationkey: String?
}

struct OpenBDExtent: Codable {
    let extentType: String?
    let extentValue: String?
    let extentUnit: String?
    
    enum CodingKeys: String, CodingKey {
        case extentType = "ExtentType"
        case extentValue = "ExtentValue"
        case extentUnit = "ExtentUnit"
    }
}

struct OpenBDPublishingDetail: Codable {
    let imprint: OpenBDImprint?
    let publishingDate: [OpenBDPublishingDate]?
    
    enum CodingKeys: String, CodingKey {
        case imprint = "Imprint"
        case publishingDate = "PublishingDate"
    }
}

struct OpenBDImprint: Codable {
    let imprintIdentifier: [OpenBDImprintIdentifier]?
    let imprintName: String?
    
    enum CodingKeys: String, CodingKey {
        case imprintIdentifier = "ImprintIdentifier"
        case imprintName = "ImprintName"
    }
}

struct OpenBDImprintIdentifier: Codable {
    let imprintIDType: String?
    let idValue: String?
    
    enum CodingKeys: String, CodingKey {
        case imprintIDType = "ImprintIDType"
        case idValue = "IDValue"
    }
}

struct OpenBDPublishingDate: Codable {
    let publishingDateRole: String?
    let date: String?
    
    enum CodingKeys: String, CodingKey {
        case publishingDateRole = "PublishingDateRole"
        case date = "Date"
    }
}

struct OpenBDCollateralDetail: Codable {
    let supportingResource: [OpenBDSupportingResource]?
    let textContent: [OpenBDTextContent]?
    
    enum CodingKeys: String, CodingKey {
        case supportingResource = "SupportingResource"
        case textContent = "TextContent"
    }
}

struct OpenBDSupportingResource: Codable {
    let resourceContentType: String?
    let contentAudience: String?
    let resourceVersion: [OpenBDResourceVersion]?
    
    enum CodingKeys: String, CodingKey {
        case resourceContentType = "ResourceContentType"
        case contentAudience = "ContentAudience"
        case resourceVersion = "ResourceVersion"
    }
}

struct OpenBDResourceVersion: Codable {
    let resourceForm: String?
    let resourceVersionFeature: [OpenBDResourceVersionFeature]?
    let resourceLink: String?
    
    enum CodingKeys: String, CodingKey {
        case resourceForm = "ResourceForm"
        case resourceVersionFeature = "ResourceVersionFeature"
        case resourceLink = "ResourceLink"
    }
}

struct OpenBDResourceVersionFeature: Codable {
    let resourceVersionFeatureType: String?
    let featureValue: String?
    
    enum CodingKeys: String, CodingKey {
        case resourceVersionFeatureType = "ResourceVersionFeatureType"
        case featureValue = "FeatureValue"
    }
}

struct OpenBDTextContent: Codable {
    let textType: String?
    let contentAudience: String?
    let text: String?
    
    enum CodingKeys: String, CodingKey {
        case textType = "TextType"
        case contentAudience = "ContentAudience"
        case text = "Text"
    }
}

struct OpenBDHanmoto: Codable {
    let datecreated: String?
    let datemodified: String?
}

struct OpenBDSummary: Codable {
    let isbn: String?
    let title: String?
    let volume: String?
    let series: String?
    let publisher: String?
    let pubdate: String?
    let cover: String?
    let author: String?
}

// OpenBD API レスポンスから Book モデルへの変換
extension OpenBDResponse {
    func toBook() -> Book? {
        // サマリーから優先的にデータを取得
        if let summary = summary {
            return Book.new(
                isbn: summary.isbn,
                title: summary.title ?? "タイトル不明",
                author: summary.author ?? "著者不明",
                publisher: summary.publisher,
                publishedDate: parseDate(summary.pubdate),
                pageCount: extractPageCount(),
                description: extractDescription(),
                coverImageUrl: summary.cover,
                dataSource: .openBD
            )
        }
        
        // ONIXデータから取得
        guard let onix = onix else { return nil }
        
        let isbn = onix.recordReference ?? onix.productIdentifier?.idValue
        let title = onix.descriptiveDetail?.titleDetail?.titleElement?.titleText?.content ?? "タイトル不明"
        let authors = onix.descriptiveDetail?.contributor?.compactMap { $0.personName?.content }
        let author = authors?.joined(separator: ", ") ?? "著者不明"
        let publisher = onix.publishingDetail?.imprint?.imprintName
        let publishedDate = onix.publishingDetail?.publishingDate?.first(where: { $0.publishingDateRole == "01" })?.date
        let coverImageUrl = extractCoverImageUrl()
        
        return Book.new(
            isbn: isbn,
            title: title,
            author: author,
            publisher: publisher,
            publishedDate: parseDate(publishedDate),
            pageCount: extractPageCount(),
            description: extractDescription(),
            coverImageUrl: coverImageUrl,
            dataSource: .openBD
        )
    }
    
    private func extractPageCount() -> Int? {
        guard let extents = onix?.descriptiveDetail?.extent else { return nil }
        
        for extent in extents {
            if extent.extentType == "11" { // ページ数
                return Int(extent.extentValue ?? "")
            }
        }
        return nil
    }
    
    private func extractDescription() -> String? {
        guard let textContents = onix?.collateralDetail?.textContent else { return nil }
        
        // 内容紹介を優先
        for content in textContents {
            if content.textType == "03" { // Description
                return content.text
            }
        }
        
        // 次に目次情報
        for content in textContents {
            if content.textType == "04" { // Table of contents
                return content.text
            }
        }
        
        return nil
    }
    
    private func extractCoverImageUrl() -> String? {
        // サマリーの表紙画像を優先
        if let cover = summary?.cover, !cover.isEmpty {
            return cover
        }
        
        // ONIXデータから表紙画像を取得
        guard let resources = onix?.collateralDetail?.supportingResource else { return nil }
        
        for resource in resources {
            if resource.resourceContentType == "01" { // Front cover
                if let version = resource.resourceVersion?.first {
                    return version.resourceLink
                }
            }
        }
        
        return nil
    }
    
    private func parseDate(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        
        // OpenBDの日付形式: YYYYMMDD または YYYY-MM-DD
        let formatters = [
            DateFormatter.yyyyMMdd_noSeparator,
            DateFormatter.yyyyMMdd,
            DateFormatter.yyyyMM,
            DateFormatter.yyyy
        ]
        
        for formatter in formatters {
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        
        return nil
    }
}

// DateFormatter 拡張
extension DateFormatter {
    static let yyyyMMdd_noSeparator: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()
}