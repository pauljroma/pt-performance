//
//  ClinicalTemplateService.swift
//  PTPerformance
//
//  Service for managing clinical documentation templates
//  Handles system templates, user templates, and usage tracking
//

import Foundation
import Supabase

// MARK: - Input Models for Supabase

/// Input for creating a new clinical template
private struct CreateClinicalTemplateInput: Codable {
    let therapistId: String
    let name: String
    let description: String?
    let templateType: String
    let bodyRegion: String?
    let templateContent: TemplateContent
    let defaultValues: [String: String]?
    let isSystemTemplate: Bool
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case therapistId = "therapist_id"
        case name
        case description
        case templateType = "template_type"
        case bodyRegion = "body_region"
        case templateContent = "template_content"
        case defaultValues = "default_values"
        case isSystemTemplate = "is_system_template"
        case isActive = "is_active"
    }
}

/// Input for updating an existing clinical template
private struct UpdateClinicalTemplateInput: Codable {
    var name: String?
    var description: String?
    var templateType: String?
    var bodyRegion: String?
    var templateContent: TemplateContent?
    var defaultValues: [String: String]?
    var isActive: Bool?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case name
        case description
        case templateType = "template_type"
        case bodyRegion = "body_region"
        case templateContent = "template_content"
        case defaultValues = "default_values"
        case isActive = "is_active"
        case updatedAt = "updated_at"
    }
}

/// Input for tracking template usage
private struct TrackTemplateUsageParams: Codable {
    let pTemplateId: String

    enum CodingKeys: String, CodingKey {
        case pTemplateId = "p_template_id"
    }
}

/// Input for incrementing use count
private struct IncrementUseCountInput: Codable {
    let useCount: Int
    let lastUsedAt: Date

    enum CodingKeys: String, CodingKey {
        case useCount = "use_count"
        case lastUsedAt = "last_used_at"
    }
}

// MARK: - Clinical Template Service

/// Service for managing clinical documentation templates
/// Uses PTSupabaseClient.flexibleDecoder for all date handling
@MainActor
class ClinicalTemplateService: ObservableObject {
    static let shared = ClinicalTemplateService()
    private let supabase = PTSupabaseClient.shared
    private let logger = DebugLogger.shared

    // MARK: - Published Properties

    @Published private(set) var systemTemplates: [ClinicalTemplate] = []
    @Published private(set) var userTemplates: [ClinicalTemplate] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: ClinicalTemplateError?

    private init() {}

    // MARK: - Combined Templates

    /// All templates (system + user) sorted by usage
    var allTemplates: [ClinicalTemplate] {
        (systemTemplates + userTemplates).sorted { ($0.useCount ?? 0) > ($1.useCount ?? 0) }
    }

    /// Templates filtered by type
    func templates(for type: TemplateType) -> [ClinicalTemplate] {
        allTemplates.filter { $0.templateType == type }
    }

    /// Templates filtered by body region
    func templates(for bodyRegion: String) -> [ClinicalTemplate] {
        allTemplates.filter { $0.bodyRegion == bodyRegion }
    }

    // MARK: - Fetch Templates

    /// Fetch all system templates
    func fetchSystemTemplates() async throws -> [ClinicalTemplate] {
        logger.info("CLINICAL TEMPLATE", "Fetching system templates...")

        do {
            let templates: [ClinicalTemplate] = try await supabase.client
                .from("clinical_templates")
                .select()
                .eq("is_system_template", value: true)
                .eq("is_active", value: true)
                .order("use_count", ascending: false)
                .order("name", ascending: true)
                .execute()
                .value

            self.systemTemplates = templates
            logger.success("CLINICAL TEMPLATE", "Fetched \(templates.count) system templates")
            return templates
        } catch {
            logger.error("CLINICAL TEMPLATE", "Failed to fetch system templates: \(error)")
            self.error = .fetchFailed
            throw ClinicalTemplateError.fetchFailed
        }
    }

    /// Fetch all templates for a therapist (user-created)
    func fetchUserTemplates(therapistId: String) async throws -> [ClinicalTemplate] {
        logger.info("CLINICAL TEMPLATE", "Fetching user templates for therapist: \(therapistId)")

        do {
            let templates: [ClinicalTemplate] = try await supabase.client
                .from("clinical_templates")
                .select()
                .eq("therapist_id", value: therapistId)
                .eq("is_system_template", value: false)
                .order("use_count", ascending: false)
                .order("updated_at", ascending: false)
                .execute()
                .value

            self.userTemplates = templates
            logger.success("CLINICAL TEMPLATE", "Fetched \(templates.count) user templates")
            return templates
        } catch {
            logger.error("CLINICAL TEMPLATE", "Failed to fetch user templates: \(error)")
            self.error = .fetchFailed
            throw ClinicalTemplateError.fetchFailed
        }
    }

    /// Fetch all templates (system + user) for a therapist
    func fetchAllTemplates(therapistId: String) async throws -> [ClinicalTemplate] {
        logger.info("CLINICAL TEMPLATE", "Fetching all templates for therapist: \(therapistId)")
        isLoading = true
        error = nil

        defer { isLoading = false }

        do {
            // Fetch both in parallel
            async let systemTask = fetchSystemTemplates()
            async let userTask = fetchUserTemplates(therapistId: therapistId)

            let (system, user) = try await (systemTask, userTask)
            return system + user
        } catch {
            logger.error("CLINICAL TEMPLATE", "Failed to fetch all templates: \(error)")
            throw error
        }
    }

    /// Fetch a single template by ID
    func fetchTemplate(id: UUID) async throws -> ClinicalTemplate? {
        logger.info("CLINICAL TEMPLATE", "Fetching template: \(id)")

        do {
            let templates: [ClinicalTemplate] = try await supabase.client
                .from("clinical_templates")
                .select()
                .eq("id", value: id.uuidString)
                .limit(1)
                .execute()
                .value

            logger.success("CLINICAL TEMPLATE", "Template found: \(templates.first?.name ?? "nil")")
            return templates.first
        } catch {
            logger.error("CLINICAL TEMPLATE", "Failed to fetch template: \(error)")
            throw ClinicalTemplateError.templateNotFound
        }
    }

    // MARK: - Create Template

    /// Create a new user template
    func createTemplate(_ input: ClinicalTemplateInput) async throws -> ClinicalTemplate {
        logger.info("CLINICAL TEMPLATE", "Creating template: \(input.name)")

        // Validate input
        try input.validate()

        guard let therapistId = input.therapistId else {
            throw ClinicalTemplateError.invalidName("Therapist ID is required")
        }

        let createInput = CreateClinicalTemplateInput(
            therapistId: therapistId,
            name: input.name,
            description: input.description,
            templateType: input.templateType,
            bodyRegion: input.bodyRegion,
            templateContent: input.templateContent,
            defaultValues: input.defaultValues,
            isSystemTemplate: false,
            isActive: input.isActive ?? true
        )

        do {
            let template: ClinicalTemplate = try await supabase.client
                .from("clinical_templates")
                .insert(createInput)
                .select()
                .single()
                .execute()
                .value

            // Update local cache
            userTemplates.append(template)

            logger.success("CLINICAL TEMPLATE", "Created template: \(template.id)")
            return template
        } catch {
            logger.error("CLINICAL TEMPLATE", "Failed to create template: \(error)")
            throw ClinicalTemplateError.saveFailed
        }
    }

    // MARK: - Update Template

    /// Update an existing user template
    func updateTemplate(
        id: UUID,
        name: String? = nil,
        description: String? = nil,
        templateType: TemplateType? = nil,
        bodyRegion: String? = nil,
        templateContent: TemplateContent? = nil,
        defaultValues: [String: String]? = nil,
        isActive: Bool? = nil
    ) async throws -> ClinicalTemplate {
        logger.info("CLINICAL TEMPLATE", "Updating template: \(id)")

        // Check if it's a system template
        if let existingTemplate = allTemplates.first(where: { $0.id == id }),
           existingTemplate.isSystemTemplate {
            throw ClinicalTemplateError.cannotDeleteSystemTemplate
        }

        let updateInput = UpdateClinicalTemplateInput(
            name: name,
            description: description,
            templateType: templateType?.rawValue,
            bodyRegion: bodyRegion,
            templateContent: templateContent,
            defaultValues: defaultValues,
            isActive: isActive,
            updatedAt: Date()
        )

        do {
            let template: ClinicalTemplate = try await supabase.client
                .from("clinical_templates")
                .update(updateInput)
                .eq("id", value: id.uuidString)
                .select()
                .single()
                .execute()
                .value

            // Update local cache
            if let index = userTemplates.firstIndex(where: { $0.id == id }) {
                userTemplates[index] = template
            }

            logger.success("CLINICAL TEMPLATE", "Updated template: \(template.name)")
            return template
        } catch {
            logger.error("CLINICAL TEMPLATE", "Failed to update template: \(error)")
            throw ClinicalTemplateError.saveFailed
        }
    }

    // MARK: - Delete Template

    /// Delete a user template (cannot delete system templates)
    func deleteTemplate(id: UUID) async throws {
        logger.info("CLINICAL TEMPLATE", "Deleting template: \(id)")

        // Check if it's a system template
        if let existingTemplate = allTemplates.first(where: { $0.id == id }),
           existingTemplate.isSystemTemplate {
            logger.error("CLINICAL TEMPLATE", "Cannot delete system template")
            throw ClinicalTemplateError.cannotDeleteSystemTemplate
        }

        do {
            _ = try await supabase.client
                .from("clinical_templates")
                .delete()
                .eq("id", value: id.uuidString)
                .eq("is_system_template", value: false)
                .execute()

            // Update local cache
            userTemplates.removeAll { $0.id == id }

            logger.success("CLINICAL TEMPLATE", "Deleted template: \(id)")
        } catch {
            logger.error("CLINICAL TEMPLATE", "Failed to delete template: \(error)")
            throw ClinicalTemplateError.saveFailed
        }
    }

    // MARK: - Duplicate Template

    /// Duplicate an existing template (system or user) as a new user template
    func duplicateTemplate(id: UUID, therapistId: String, newName: String? = nil) async throws -> ClinicalTemplate {
        logger.info("CLINICAL TEMPLATE", "Duplicating template: \(id)")

        guard let original = try await fetchTemplate(id: id) else {
            throw ClinicalTemplateError.templateNotFound
        }

        let duplicateName = newName ?? "\(original.name) (Copy)"

        // Check for duplicate name
        if allTemplates.contains(where: { $0.name == duplicateName && $0.therapistId?.uuidString == therapistId }) {
            throw ClinicalTemplateError.duplicateName
        }

        let input = ClinicalTemplateInput(
            therapistId: therapistId,
            name: duplicateName,
            description: original.description,
            templateType: original.templateType.rawValue,
            bodyRegion: original.bodyRegion,
            templateContent: original.templateContent,
            defaultValues: original.defaultValues,
            isActive: true
        )

        let newTemplate = try await createTemplate(input)
        logger.success("CLINICAL TEMPLATE", "Duplicated template as: \(newTemplate.name)")
        return newTemplate
    }

    // MARK: - Usage Tracking

    /// Track when a template is used (increments use count and updates last used date)
    func trackTemplateUsage(templateId: UUID) async throws {
        logger.info("CLINICAL TEMPLATE", "Tracking usage for template: \(templateId)")

        // First, fetch current use count
        guard let template = try await fetchTemplate(id: templateId) else {
            throw ClinicalTemplateError.templateNotFound
        }

        let newUseCount = (template.useCount ?? 0) + 1

        do {
            // Try RPC function first (if available)
            let params = TrackTemplateUsageParams(pTemplateId: templateId.uuidString)
            _ = try await supabase.client
                .rpc("track_template_usage", params: params)
                .execute()

            logger.success("CLINICAL TEMPLATE", "Usage tracked via RPC for template: \(templateId)")

            // Update local cache
            await updateLocalCacheUsage(templateId: templateId, useCount: newUseCount)
        } catch {
            // Fallback to direct update if RPC not available
            logger.warning("CLINICAL TEMPLATE", "RPC not available, using direct update")

            let updateInput = IncrementUseCountInput(
                useCount: newUseCount,
                lastUsedAt: Date()
            )

            do {
                _ = try await supabase.client
                    .from("clinical_templates")
                    .update(updateInput)
                    .eq("id", value: templateId.uuidString)
                    .execute()

                logger.success("CLINICAL TEMPLATE", "Usage tracked directly for template: \(templateId)")

                // Update local cache
                await updateLocalCacheUsage(templateId: templateId, useCount: newUseCount)
            } catch {
                logger.error("CLINICAL TEMPLATE", "Failed to track usage: \(error)")
                // Don't throw - usage tracking failure shouldn't block the user
            }
        }
    }

    /// Update local cache with usage data
    private func updateLocalCacheUsage(templateId: UUID, useCount: Int) async {
        if let index = systemTemplates.firstIndex(where: { $0.id == templateId }) {
            var template = systemTemplates[index]
            template = ClinicalTemplate(
                id: template.id,
                therapistId: template.therapistId,
                name: template.name,
                description: template.description,
                templateType: template.templateType,
                bodyRegion: template.bodyRegion,
                templateContent: template.templateContent,
                defaultValues: template.defaultValues,
                isSystemTemplate: template.isSystemTemplate,
                isActive: template.isActive,
                useCount: useCount,
                lastUsedAt: Date(),
                createdAt: template.createdAt,
                updatedAt: Date()
            )
            systemTemplates[index] = template
        }

        if let index = userTemplates.firstIndex(where: { $0.id == templateId }) {
            var template = userTemplates[index]
            template = ClinicalTemplate(
                id: template.id,
                therapistId: template.therapistId,
                name: template.name,
                description: template.description,
                templateType: template.templateType,
                bodyRegion: template.bodyRegion,
                templateContent: template.templateContent,
                defaultValues: template.defaultValues,
                isSystemTemplate: template.isSystemTemplate,
                isActive: template.isActive,
                useCount: useCount,
                lastUsedAt: Date(),
                createdAt: template.createdAt,
                updatedAt: Date()
            )
            userTemplates[index] = template
        }
    }

    // MARK: - Search

    /// Search templates by name or description
    func searchTemplates(query: String, therapistId: String) async throws -> [ClinicalTemplate] {
        logger.info("CLINICAL TEMPLATE", "Searching templates: \(query)")

        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return allTemplates
        }

        do {
            let templates: [ClinicalTemplate] = try await supabase.client
                .from("clinical_templates")
                .select()
                .or("is_system_template.eq.true,therapist_id.eq.\(therapistId)")
                .eq("is_active", value: true)
                .or("name.ilike.%\(query)%,description.ilike.%\(query)%,body_region.ilike.%\(query)%")
                .order("use_count", ascending: false)
                .execute()
                .value

            logger.success("CLINICAL TEMPLATE", "Found \(templates.count) templates matching: \(query)")
            return templates
        } catch {
            logger.error("CLINICAL TEMPLATE", "Search failed: \(error)")
            throw ClinicalTemplateError.fetchFailed
        }
    }

    // MARK: - Most Used Templates

    /// Get most frequently used templates
    func fetchMostUsedTemplates(therapistId: String, limit: Int = 5) async throws -> [ClinicalTemplate] {
        logger.info("CLINICAL TEMPLATE", "Fetching most used templates (limit: \(limit))")

        do {
            let templates: [ClinicalTemplate] = try await supabase.client
                .from("clinical_templates")
                .select()
                .or("is_system_template.eq.true,therapist_id.eq.\(therapistId)")
                .eq("is_active", value: true)
                .order("use_count", ascending: false)
                .limit(limit)
                .execute()
                .value

            logger.success("CLINICAL TEMPLATE", "Fetched \(templates.count) most used templates")
            return templates
        } catch {
            logger.error("CLINICAL TEMPLATE", "Failed to fetch most used templates: \(error)")
            throw ClinicalTemplateError.fetchFailed
        }
    }

    /// Get recently used templates
    func fetchRecentlyUsedTemplates(therapistId: String, limit: Int = 5) async throws -> [ClinicalTemplate] {
        logger.info("CLINICAL TEMPLATE", "Fetching recently used templates (limit: \(limit))")

        do {
            let templates: [ClinicalTemplate] = try await supabase.client
                .from("clinical_templates")
                .select()
                .or("is_system_template.eq.true,therapist_id.eq.\(therapistId)")
                .eq("is_active", value: true)
                .not("last_used_at", operator: .is, value: "null")
                .order("last_used_at", ascending: false)
                .limit(limit)
                .execute()
                .value

            logger.success("CLINICAL TEMPLATE", "Fetched \(templates.count) recently used templates")
            return templates
        } catch {
            logger.error("CLINICAL TEMPLATE", "Failed to fetch recently used templates: \(error)")
            throw ClinicalTemplateError.fetchFailed
        }
    }

    // MARK: - Clear State

    /// Clear all cached templates and reset state
    func clearState() {
        systemTemplates = []
        userTemplates = []
        isLoading = false
        error = nil
        logger.info("CLINICAL TEMPLATE", "State cleared")
    }
}
