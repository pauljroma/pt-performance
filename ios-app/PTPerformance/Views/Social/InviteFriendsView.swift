//
//  InviteFriendsView.swift
//  PTPerformance
//
//  ACP-996: Invite Friends Flow
//  Contact-based invite experience with Messages, Email, and share link support
//

import SwiftUI
import ContactsUI

// MARK: - Invite Contact

/// A contact selected for invitation
struct InviteContact: Identifiable, Hashable {
    let id: String
    let givenName: String
    let familyName: String
    let phoneNumber: String?
    let emailAddress: String?
    var isInvited: Bool = false

    var fullName: String {
        [givenName, familyName].filter { !$0.isEmpty }.joined(separator: " ")
    }

    var initials: String {
        let first = givenName.prefix(1).uppercased()
        let last = familyName.prefix(1).uppercased()
        return "\(first)\(last)"
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Invite Method

/// Available methods for sending invitations
enum InviteMethod: String, CaseIterable, Identifiable {
    case message = "Messages"
    case email = "Email"
    case shareLink = "Share Link"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .message: return "message.fill"
        case .email: return "envelope.fill"
        case .shareLink: return "link"
        }
    }

    var color: Color {
        switch self {
        case .message: return DesignTokens.statusSuccess
        case .email: return DesignTokens.statusInfo
        case .shareLink: return .modusCyanStatic
        }
    }
}

// MARK: - Invite Friends View

/// Invite friends flow with contact picker and multiple sharing options
struct InviteFriendsView: View {

    // MARK: - Properties

    @StateObject private var referralService = ReferralService.shared
    @Environment(\.dismiss) private var dismiss

    @State private var contacts: [InviteContact] = []
    @State private var searchText = ""
    @State private var isLoadingContacts = false
    @State private var contactsPermissionDenied = false
    @State private var showContactPicker = false
    @State private var selectedContact: InviteContact?
    @State private var showInviteMethodSheet = false
    @State private var inviteSentCount = 0

    private let logger = DebugLogger.shared

    // MARK: - Computed

    private var filteredContacts: [InviteContact] {
        if searchText.isEmpty {
            return contacts
        }
        return contacts.filter {
            $0.fullName.localizedCaseInsensitiveContains(searchText) ||
            ($0.phoneNumber?.contains(searchText) ?? false) ||
            ($0.emailAddress?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    private var inviteMessage: String {
        let code = referralService.referralCode.isEmpty ? "" : " Use my referral code \(referralService.referralCode) to get started."
        return "Hey! I've been using Modus PT for my training and it's been awesome.\(code) Check it out: https://app.moduspt.com/invite/\(referralService.referralCode)"
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header stats
                inviteHeader

                // Search bar
                searchBar

                // Contact list or states
                contactListContent
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Invite Friends")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        HapticFeedback.light()
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showContactPicker) {
                ContactPickerView(onContactSelected: { contact in
                    addContactFromPicker(contact)
                })
            }
            .sheet(isPresented: $showInviteMethodSheet) {
                inviteMethodSheet
            }
            .task {
                await loadContacts()
            }
        }
    }

    // MARK: - Header

    private var inviteHeader: some View {
        VStack(spacing: Spacing.sm) {
            HStack(spacing: Spacing.lg) {
                // Invites sent stat
                VStack(spacing: Spacing.xxs) {
                    Text("\(inviteSentCount)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.modusCyan)
                    Text("Invites Sent")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()
                    .frame(height: 40)

                // Referral count
                VStack(spacing: Spacing.xxs) {
                    Text("\(referralService.referralCount)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.modusTealAccent)
                    Text("Friends Joined")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()
                    .frame(height: 40)

                // Quick share
                Button {
                    HapticFeedback.medium()
                    referralService.shareReferralLink()
                } label: {
                    VStack(spacing: Spacing.xxs) {
                        Image(systemName: "square.and.arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundColor(.modusCyan)
                        Text("Quick Share")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .accessibilityLabel("Quick share referral link")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)

            // Referral code display
            if !referralService.referralCode.isEmpty {
                HStack(spacing: Spacing.xs) {
                    Text("Your code:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(referralService.referralCode)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.modusCyan)
                        .fontDesign(.monospaced)

                    Button {
                        referralService.copyReferralCode()
                    } label: {
                        Image(systemName: referralService.codeCopied ? "checkmark" : "doc.on.doc")
                            .font(.caption2)
                            .foregroundColor(referralService.codeCopied ? DesignTokens.statusSuccess : .modusCyan)
                    }
                    .accessibilityLabel("Copy referral code")
                }
                .padding(.bottom, Spacing.xs)
            }
        }
        .padding(.horizontal, Spacing.md)
        .background(Color(.systemBackground))
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search contacts...", text: $searchText)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }

            Button {
                HapticFeedback.light()
                showContactPicker = true
            } label: {
                Image(systemName: "person.crop.circle.badge.plus")
                    .foregroundColor(.modusCyan)
            }
            .accessibilityLabel("Import contacts")
        }
        .padding(Spacing.sm)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(CornerRadius.sm)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
    }

    // MARK: - Contact List Content

    @ViewBuilder
    private var contactListContent: some View {
        if isLoadingContacts {
            VStack(spacing: Spacing.md) {
                ProgressView()
                Text("Loading contacts...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if contactsPermissionDenied {
            contactsPermissionView
        } else if filteredContacts.isEmpty {
            emptyContactsView
        } else {
            contactsList
        }
    }

    // MARK: - Contacts Permission View

    private var contactsPermissionView: some View {
        EmptyStateView(
            title: "Contacts Access Required",
            message: "Allow Modus to access your contacts to invite friends. You can also share your referral link directly.",
            icon: "person.crop.circle.badge.exclamationmark",
            iconColor: .modusCyan,
            action: EmptyStateView.EmptyStateAction(
                title: "Open Settings",
                icon: "gear",
                action: {
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL)
                    }
                }
            )
        )
    }

    // MARK: - Empty Contacts View

    private var emptyContactsView: some View {
        VStack(spacing: Spacing.lg) {
            if searchText.isEmpty {
                EmptyStateView(
                    title: "No Contacts Found",
                    message: "Import contacts or share your referral link directly with friends.",
                    icon: "person.2.slash",
                    iconColor: .secondary,
                    action: EmptyStateView.EmptyStateAction(
                        title: "Import Contacts",
                        icon: "person.crop.circle.badge.plus",
                        action: {
                            showContactPicker = true
                        }
                    )
                )
            } else {
                EmptyStateView(
                    title: "No Results",
                    message: "No contacts match \"\(searchText)\"",
                    icon: "magnifyingglass",
                    iconColor: .secondary
                )
            }
        }
    }

    // MARK: - Contacts List

    private var contactsList: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.xs) {
                ForEach(filteredContacts) { contact in
                    contactRow(contact)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
        }
    }

    private func contactRow(_ contact: InviteContact) -> some View {
        HStack(spacing: Spacing.md) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.modusCyan.opacity(0.12))
                    .frame(width: 44, height: 44)

                Text(contact.initials)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.modusCyan)
            }

            // Name and contact info
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(contact.fullName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let phone = contact.phoneNumber {
                    Text(phone)
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if let email = contact.emailAddress {
                    Text(email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Invite button
            if contact.isInvited {
                HStack(spacing: Spacing.xxs) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(DesignTokens.statusSuccess)
                    Text("Invited")
                        .font(.caption)
                        .foregroundColor(DesignTokens.statusSuccess)
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(DesignTokens.statusSuccess.opacity(0.1))
                .cornerRadius(CornerRadius.sm)
            } else {
                Button {
                    HapticFeedback.medium()
                    selectedContact = contact
                    showInviteMethodSheet = true
                } label: {
                    Text("Invite")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                        .background(Color.modusCyan)
                        .cornerRadius(CornerRadius.sm)
                }
                .accessibilityLabel("Invite \(contact.fullName)")
            }
        }
        .padding(Spacing.sm)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.md)
    }

    // MARK: - Invite Method Sheet

    private var inviteMethodSheet: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                if let contact = selectedContact {
                    Text("Invite \(contact.fullName)")
                        .font(.headline)
                        .padding(.top, Spacing.md)

                    Text("Choose how to send the invitation")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                VStack(spacing: Spacing.sm) {
                    ForEach(InviteMethod.allCases) { method in
                        Button {
                            HapticFeedback.medium()
                            sendInvite(via: method)
                        } label: {
                            HStack(spacing: Spacing.md) {
                                Image(systemName: method.iconName)
                                    .font(.title3)
                                    .foregroundColor(method.color)
                                    .frame(width: 32)

                                Text(method.rawValue)
                                    .font(.body)
                                    .foregroundColor(.primary)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(Spacing.md)
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(CornerRadius.md)
                        }
                    }
                }
                .padding(.horizontal, Spacing.lg)

                Spacer()
            }
            .navigationTitle("Send Invite")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showInviteMethodSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Actions

    /// Load contacts from the device
    private func loadContacts() async {
        logger.info("InviteFriends", "Loading contacts")
        isLoadingContacts = true

        let store = CNContactStore()

        do {
            let status = CNContactStore.authorizationStatus(for: .contacts)

            switch status {
            case .authorized, .limited:
                break
            case .notDetermined:
                let granted = try await store.requestAccess(for: .contacts)
                if !granted {
                    contactsPermissionDenied = true
                    isLoadingContacts = false
                    return
                }
            case .denied, .restricted:
                contactsPermissionDenied = true
                isLoadingContacts = false
                logger.warning("InviteFriends", "Contacts permission denied")
                return
            @unknown default:
                contactsPermissionDenied = true
                isLoadingContacts = false
                return
            }

            let keysToFetch: [CNKeyDescriptor] = [
                CNContactGivenNameKey as CNKeyDescriptor,
                CNContactFamilyNameKey as CNKeyDescriptor,
                CNContactPhoneNumbersKey as CNKeyDescriptor,
                CNContactEmailAddressesKey as CNKeyDescriptor,
                CNContactIdentifierKey as CNKeyDescriptor
            ]

            let request = CNContactFetchRequest(keysToFetch: keysToFetch)
            request.sortOrder = .givenName

            var fetchedContacts: [InviteContact] = []

            try store.enumerateContacts(with: request) { cnContact, _ in
                let phone = cnContact.phoneNumbers.first?.value.stringValue
                let email = cnContact.emailAddresses.first?.value as? String

                // Only include contacts with a phone number or email
                guard phone != nil || email != nil else { return }

                let contact = InviteContact(
                    id: cnContact.identifier,
                    givenName: cnContact.givenName,
                    familyName: cnContact.familyName,
                    phoneNumber: phone,
                    emailAddress: email
                )
                fetchedContacts.append(contact)
            }

            contacts = fetchedContacts
            logger.success("InviteFriends", "Loaded \(contacts.count) contacts")
        } catch {
            if error.isCancellation { return }
            logger.error("InviteFriends", "Failed to load contacts: \(error.localizedDescription)")
            contactsPermissionDenied = true
        }

        isLoadingContacts = false
    }

    /// Add a contact from the contact picker
    private func addContactFromPicker(_ cnContact: CNContact) {
        let phone = cnContact.phoneNumbers.first?.value.stringValue
        let email = cnContact.emailAddresses.first?.value as? String

        let contact = InviteContact(
            id: cnContact.identifier,
            givenName: cnContact.givenName,
            familyName: cnContact.familyName,
            phoneNumber: phone,
            emailAddress: email
        )

        // Add if not already in list
        if !contacts.contains(where: { $0.id == contact.id }) {
            contacts.insert(contact, at: 0)
        }

        selectedContact = contact
        showInviteMethodSheet = true
        logger.info("InviteFriends", "Added contact from picker: \(contact.fullName)")
    }

    /// Send invite via the selected method
    private func sendInvite(via method: InviteMethod) {
        guard let contact = selectedContact else { return }

        logger.info("InviteFriends", "Sending invite to \(contact.fullName) via \(method.rawValue)")

        switch method {
        case .message:
            if let phone = contact.phoneNumber,
               let url = URL(string: "sms:\(phone)&body=\(inviteMessage.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
                UIApplication.shared.open(url)
            }
        case .email:
            if let email = contact.emailAddress,
               let url = URL(string: "mailto:\(email)?subject=Join%20Modus%20PT&body=\(inviteMessage.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
                UIApplication.shared.open(url)
            }
        case .shareLink:
            let content = ShareContent(
                title: "Join Modus PT",
                text: inviteMessage,
                image: nil,
                url: referralService.generateReferralLink()
            )
            SocialSharingService.shared.presentShareSheet(content: content)
        }

        // Mark contact as invited
        if let index = contacts.firstIndex(where: { $0.id == contact.id }) {
            contacts[index].isInvited = true
        }
        inviteSentCount += 1
        showInviteMethodSheet = false
        HapticFeedback.success()
        logger.success("InviteFriends", "Invite sent to \(contact.fullName) via \(method.rawValue)")
    }
}

// MARK: - Contact Picker View

/// UIViewControllerRepresentable wrapper for CNContactPickerViewController
struct ContactPickerView: UIViewControllerRepresentable {
    let onContactSelected: (CNContact) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onContactSelected: onContactSelected)
    }

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        picker.displayedPropertyKeys = [
            CNContactGivenNameKey,
            CNContactFamilyNameKey,
            CNContactPhoneNumbersKey,
            CNContactEmailAddressesKey
        ]
        return picker
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}

    class Coordinator: NSObject, CNContactPickerDelegate {
        let onContactSelected: (CNContact) -> Void

        init(onContactSelected: @escaping (CNContact) -> Void) {
            self.onContactSelected = onContactSelected
        }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            DebugLogger.shared.info("ContactPicker", "Selected contact: \(contact.givenName) \(contact.familyName)")
            onContactSelected(contact)
        }

        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            DebugLogger.shared.diagnostic("[ContactPicker] Contact picker cancelled")
        }
    }
}

// MARK: - Preview

#if DEBUG
struct InviteFriendsView_Previews: PreviewProvider {
    static var previews: some View {
        InviteFriendsView()
    }
}
#endif
