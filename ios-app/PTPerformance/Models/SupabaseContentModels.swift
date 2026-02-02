//
//  SupabaseContentModels.swift
//  PTPerformance
//
//  Shared models for Supabase content_items table
//  Used by both HelpContentLoader and LearningContentLoader
//

import Foundation

// MARK: - Supabase Models

/// Supabase content_items table structure (flexible content system)
struct SupabaseContentItem: Codable, Identifiable, Hashable {
    let id: String
    let slug: String
    let title: String
    let category: String
    let subcategory: String?
    let content: ContentData // JSONB field with markdown
    let excerpt: String?
    let tags: [String]?
    let difficulty: String?
    let estimated_duration_minutes: Int?
    let is_published: Bool
}

/// Content data from JSONB field
struct ContentData: Codable, Hashable {
    let markdown: String?
    let reading_time: String?
    let references: [Reference]?

    struct Reference: Codable, Hashable {
        let citation: String
        let order: Int
    }

    // Custom decoding to handle both dict and string formats
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        // Try to decode as dictionary first
        if let dict = try? container.decode([String: AnyCodableValue].self) {
            self.markdown = dict["markdown"]?.stringValue
            self.reading_time = dict["reading_time"]?.stringValue
            self.references = dict["references"]?.arrayValue?.compactMap { value in
                guard let dict = value.dictionaryValue,
                      let citation = dict["citation"]?.stringValue,
                      let order = dict["order"]?.intValue else {
                    return nil
                }
                return Reference(citation: citation, order: order)
            }
        } else if let string = try? container.decode(String.self) {
            // If it's just a string, use it as markdown
            self.markdown = string
            self.reading_time = nil
            self.references = nil
        } else {
            throw DecodingError.typeMismatch(ContentData.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Content must be dict or string"))
        }
    }
}

/// Helper for decoding heterogeneous JSONB values
enum AnyCodableValue: Codable, Hashable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case array([AnyCodableValue])
    case dictionary([String: AnyCodableValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let int = try? container.decode(Int.self) {
            self = .int(int)
        } else if let double = try? container.decode(Double.self) {
            self = .double(double)
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let array = try? container.decode([AnyCodableValue].self) {
            self = .array(array)
        } else if let dict = try? container.decode([String: AnyCodableValue].self) {
            self = .dictionary(dict)
        } else {
            throw DecodingError.typeMismatch(AnyCodableValue.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported type"))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .int(let value): try container.encode(value)
        case .double(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .array(let value): try container.encode(value)
        case .dictionary(let value): try container.encode(value)
        case .null: try container.encodeNil()
        }
    }

    var stringValue: String? {
        if case .string(let value) = self { return value }
        return nil
    }

    var intValue: Int? {
        if case .int(let value) = self { return value }
        return nil
    }

    var arrayValue: [AnyCodableValue]? {
        if case .array(let value) = self { return value }
        return nil
    }

    var dictionaryValue: [String: AnyCodableValue]? {
        if case .dictionary(let value) = self { return value }
        return nil
    }
}
