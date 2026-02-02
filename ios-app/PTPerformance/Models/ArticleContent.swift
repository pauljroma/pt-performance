import Foundation

/// Content structure for help articles
struct ArticleContent: Codable, Hashable, Equatable {
    let sections: [ContentSection]

    struct ContentSection: Codable, Hashable, Equatable {
        let heading: String?
        let body: String
    }
}
