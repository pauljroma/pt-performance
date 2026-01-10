import Foundation

/// Content structure for help articles
struct ArticleContent: Codable {
    let sections: [ContentSection]
    
    struct ContentSection: Codable {
        let heading: String?
        let body: String
    }
}
