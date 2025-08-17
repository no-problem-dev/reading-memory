import Foundation

protocol NetworkServiceProtocol {
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T
    func requestData(_ endpoint: Endpoint) async throws -> Data
}

struct Endpoint {
    let baseURL: String
    let path: String
    let method: HTTPMethod
    let headers: [String: String]?
    let queryItems: [URLQueryItem]?
    let body: Data?
    
    enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case patch = "PATCH"
        case delete = "DELETE"
    }
    
    var url: URL? {
        var components = URLComponents(string: baseURL)
        components?.path = path
        components?.queryItems = queryItems
        return components?.url
    }
}

final class NetworkService: NetworkServiceProtocol {
    static let shared = NetworkService()
    
    private let session: URLSession
    private let decoder: JSONDecoder
    
    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }
    
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let data = try await requestData(endpoint)
        
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw AppError.custom("データの解析に失敗しました: \(error.localizedDescription)")
        }
    }
    
    func requestData(_ endpoint: Endpoint) async throws -> Data {
        guard let url = endpoint.url else {
            throw AppError.custom("無効なURLです")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = endpoint.body
        
        // Set default headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Add custom headers
        endpoint.headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AppError.networkError("無効なレスポンスです")
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                return data
            case 401:
                throw AppError.unauthorized
            case 403:
                throw AppError.permissionDenied
            case 404:
                throw AppError.dataNotFound
            case 500...599:
                throw AppError.serverError(httpResponse.statusCode)
            default:
                throw AppError.networkError("エラーコード: \(httpResponse.statusCode)")
            }
        } catch let error as AppError {
            throw error
        } catch {
            if (error as NSError).code == NSURLErrorNotConnectedToInternet {
                throw AppError.noInternetConnection
            } else if (error as NSError).code == NSURLErrorTimedOut {
                throw AppError.requestTimeout
            }
            throw AppError.networkError(error.localizedDescription)
        }
    }
}

// MARK: - Google Books API Example
extension NetworkService {
    struct GoogleBooksEndpoints {
        static let baseURL = "https://www.googleapis.com/books/v1"
        
        static func searchByISBN(_ isbn: String, apiKey: String) -> Endpoint {
            return Endpoint(
                baseURL: baseURL,
                path: "/volumes",
                method: .get,
                headers: nil,
                queryItems: [
                    URLQueryItem(name: "q", value: "isbn:\(isbn)"),
                    URLQueryItem(name: "key", value: apiKey)
                ],
                body: nil
            )
        }
        
        static func searchByTitle(_ title: String, author: String? = nil, apiKey: String) -> Endpoint {
            var query = "intitle:\(title)"
            if let author = author {
                query += "+inauthor:\(author)"
            }
            
            return Endpoint(
                baseURL: baseURL,
                path: "/volumes",
                method: .get,
                headers: nil,
                queryItems: [
                    URLQueryItem(name: "q", value: query),
                    URLQueryItem(name: "key", value: apiKey),
                    URLQueryItem(name: "maxResults", value: "20")
                ],
                body: nil
            )
        }
    }
}