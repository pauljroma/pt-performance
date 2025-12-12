import Foundation

// Patient model from iOS app
struct Patient: Codable {
    let id: String
    let therapistId: String
    let firstName: String
    let lastName: String
    let email: String
    let sport: String?
    let position: String?
    let injuryType: String?
    let targetLevel: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case therapistId = "therapist_id"
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case sport
        case position
        case injuryType = "injury_type"
        case targetLevel = "target_level"
        case createdAt = "created_at"
    }
}

// Sample JSON from Supabase API
let jsonString = """
[{
  "id": "00000000-0000-0000-0000-000000000001",
  "therapist_id": "00000000-0000-0000-0000-000000000100",
  "first_name": "John",
  "last_name": "Brebbia",
  "email": "demo-athlete@ptperformance.app",
  "sport": "Baseball",
  "position": "Pitcher",
  "created_at": "2025-12-09T13:28:08.61431+00:00"
}]
"""

let jsonData = jsonString.data(using: .utf8)!

// Test 1: Default decoder (what Supabase client might use)
print("Test 1: Default JSONDecoder")
let decoder1 = JSONDecoder()
do {
    let patients = try decoder1.decode([Patient].self, from: jsonData)
    print("✅ Success: \(patients.count) patients")
} catch {
    print("❌ Failed: \(error)")
}

// Test 2: With ISO8601 date strategy
print("\nTest 2: ISO8601 date strategy")
let decoder2 = JSONDecoder()
decoder2.dateDecodingStrategy = .iso8601
do {
    let patients = try decoder2.decode([Patient].self, from: jsonData)
    print("✅ Success: \(patients.count) patients")
} catch {
    print("❌ Failed: \(error)")
}

// Test 3: With custom ISO8601 formatter (handles fractional seconds)
print("\nTest 3: Custom ISO8601 with fractional seconds")
let decoder3 = JSONDecoder()
let formatter = ISO8601DateFormatter()
formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
decoder3.dateDecodingStrategy = .custom { decoder in
    let container = try decoder.singleValueContainer()
    let dateString = try container.decode(String.self)
    if let date = formatter.date(from: dateString) {
        return date
    }
    throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date")
}
do {
    let patients = try decoder3.decode([Patient].self, from: jsonData)
    print("✅ Success: \(patients.count) patients")
    print("Created at: \(patients[0].createdAt)")
} catch {
    print("❌ Failed: \(error)")
}
