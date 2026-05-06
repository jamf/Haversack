// SPDX-License-Identifier: MIT
// Copyright 2026, Jamf

import Foundation
@preconcurrency import Security

/// Represents a password to an account on another computer or website in the keychain.
///
/// The combination of `server` and `account` values is unique per internet password in the keychain.
public struct InternetPasswordEntity: PasswordBaseEntity {
#if os(macOS)
    /// The native Security framework type associated with `PasswordBaseEntity`
    ///
    /// On macOS uses the `SecKeychainItem` type to interface with the Security framework.
    /// On iOS uses the [Data](https://developer.apple.com/documentation/Foundation/Data)
    /// type to interface with the Security framework.
    public typealias SecurityFrameworkType = SecKeychainItem
#else
    /// The native Security framework type associated with `PasswordBaseEntity`
    ///
    /// On macOS uses the `SecKeychainItem` type to interface with the Security framework.
    /// On iOS uses the [Data](https://developer.apple.com/documentation/Foundation/Data)
    /// type to interface with the Security framework.
    public typealias SecurityFrameworkType = Data
#endif

    /// The keychain item reference, if it has been returned.
    public var reference: SecurityFrameworkType?

    /// The persistent keychain item reference, if it has been returned.
    public var persistentRef: Data?

    /// When the item was created; read only.
    /// - Note: Uses `kSecAttrCreationDate`
    public private(set) var creationDate: Date?

    /// When the item was last modified; read only.
    /// - Note: Uses `kSecAttrModificationDate`
    public private(set) var modificationDate: Date?

    /// The item's creator.
    /// - Note: Uses `kSecAttrCreator`
    public var creator: Int?    // FourCharCode

    /// A description to store alongside the item.
    ///
    /// In Keychain Access this is the `Kind` field.
    /// - Note: Uses `kSecAttrDescription`
    public var description: String?

    /// A comment to store alongside the item.
    ///
    /// In Keychain Access this is the `Comment` field.
    /// - Note: Uses `kSecAttrComment`.
    public var comment: String?

    /// User-defined group number for passwords
    /// - Note: Uses `kSecAttrType`
    public var group: Int?     // FourCharCode

    /// A user-visible label for the item.
    ///
    /// In Keychain Access this is the `Name` field.
    /// - Note: Uses `kSecAttrLabel`
    public var label: String?

    /// Whether you want this to show up in Keychain Access.
    /// - Note: Uses `kSecAttrIsInvisible`
    public var isInvisible: Bool?

    /// The name of an account within a service associated with the password.
    ///
    /// In Keychain Access this is the `Account` field.
    /// - Note: Uses `kSecAttrAccount`
    public var account: String?

    /// The actual password.
    ///
    /// If this is nil, when saving to the keychain the `kSecAttrIsNegative` is set to `true` instead.
    /// - Note: Uses `kSecValueData`.
    public var passwordData: Data?

    /// The Internet security domain.
    /// - Note: Uses `kSecAttrSecurityDomain`
    public var securityDomain: String?

    /// Contains the server's domain name or IP address.
    /// - Note: Uses `kSecAttrServer`
    public var server: String?

    /// A communications protocol for internet passwords.
    /// - Note: Mirrors the `kSecAttrProtocol...` constants.
    public enum NetworkProtocol: Sendable {
        case FTP
        case FTPAccount
        case HTTP
        case IRC
        case NNTP
        case POP3
        case SMTP
        case SOCKS
        case IMAP
        case LDAP
        case appleTalk
        case AFP
        case telnet
        case SSH
        case FTPS
        case HTTPS
        case HTTPProxy
        case HTTPSProxy
        case FTPProxy
        case SMB
        case RTSP
        case RTSPProxy
        case DAAP
        case EPPC
        case IPP
        case NNTPS
        case LDAPS
        case telnetS
        case IMAPS
        case IRCS
        case POP3S

        private static let translation: [String: NetworkProtocol] = [
            kSecAttrProtocolFTP as String: FTP,
            kSecAttrProtocolFTPAccount as String: FTPAccount,
            kSecAttrProtocolHTTP as String: HTTP,
            kSecAttrProtocolIRC as String: IRC,
            kSecAttrProtocolNNTP as String: NNTP,
            kSecAttrProtocolPOP3 as String: POP3,
            kSecAttrProtocolSMTP as String: SMTP,
            kSecAttrProtocolSOCKS as String: SOCKS,
            kSecAttrProtocolIMAP as String: IMAP,
            kSecAttrProtocolLDAP as String: LDAP,
            kSecAttrProtocolAppleTalk as String: appleTalk,
            kSecAttrProtocolAFP as String: AFP,
            kSecAttrProtocolTelnet as String: telnet,
            kSecAttrProtocolSSH as String: SSH,
            kSecAttrProtocolFTPS as String: FTPS,
            kSecAttrProtocolHTTPS as String: HTTPS,
            kSecAttrProtocolHTTPProxy as String: HTTPProxy,
            kSecAttrProtocolHTTPSProxy as String: HTTPSProxy,
            kSecAttrProtocolFTPProxy as String: FTPProxy,
            kSecAttrProtocolSMB as String: SMB,
            kSecAttrProtocolRTSP as String: RTSP,
            kSecAttrProtocolRTSPProxy as String: RTSPProxy,
            kSecAttrProtocolDAAP as String: DAAP,
            kSecAttrProtocolEPPC as String: EPPC,
            kSecAttrProtocolIPP as String: IPP,
            kSecAttrProtocolNNTPS as String: NNTPS,
            kSecAttrProtocolLDAPS as String: LDAPS,
            kSecAttrProtocolTelnetS as String: telnetS,
            kSecAttrProtocolIMAPS as String: IMAPS,
            kSecAttrProtocolIRCS as String: IRCS,
            kSecAttrProtocolPOP3S as String: POP3S
        ]

        static func make(from securityFrameworkValue: CFString) -> NetworkProtocol? {
            return translation[securityFrameworkValue as String]
        }

        func securityFrameworkValue() -> CFString {
            return Self.translation.first(where: { $1 == self })!.key as CFString
        }
    }

    /// Denotes the protocol to access the account on the server.
    /// - Note: Uses `kSecAttrProtocol`
    public var `protocol`: NetworkProtocol?

    /// An authentication scheme for internet passwords.
    /// - Note: Mirrors the `kSecAttrAuthenticationType...` constants.
    public enum AuthenticationType: Sendable {
        case NTLM
        case MSN
        case DPA
        case RPA
        case HTTPBasic
        case HTTPDigest
        case HTMLForm
        case `default`

        private static let translation: [String: AuthenticationType] = [
            kSecAttrAuthenticationTypeNTLM as String: NTLM,
            kSecAttrAuthenticationTypeMSN as String: MSN,
            kSecAttrAuthenticationTypeDPA as String: DPA,
            kSecAttrAuthenticationTypeRPA as String: RPA,
            kSecAttrAuthenticationTypeHTTPBasic as String: HTTPBasic,
            kSecAttrAuthenticationTypeHTTPDigest as String: HTTPDigest,
            kSecAttrAuthenticationTypeHTMLForm as String: HTMLForm,
            kSecAttrAuthenticationTypeDefault as String: `default`
        ]

        static func make(from securityFrameworkValue: CFString) -> AuthenticationType? {
            return translation[securityFrameworkValue as String]
        }

        func securityFrameworkValue() -> CFString {
            return Self.translation.first(where: { $1 == self })!.key as CFString
        }
    }

    /// Denotes the authentication scheme for this item.
    /// - Note: Uses `kSecAttrAuthenticationType`
    public var authenticationType: AuthenticationType?

    /// Indicates the server's port number.
    /// - Note: Uses `kSecAttrPort`
    public var port: Int?

    /// Represents a path, typically the path component of the URL on the server.
    /// - Note: Uses `kSecAttrPath`
    public var path: String?

    /// Create an empty internet password entity
    public init() {
        // Everything is nil with this constructor.
    }

    public init(from keychainItemRef: SecurityFrameworkType?, data: Data?,
                attributes: [String: Any]?, persistentRef: Data?) {
        reference = keychainItemRef
        passwordData = data
        self.persistentRef = persistentRef

        if let attrs = attributes {
            creationDate = attrs[kSecAttrCreationDate as String] as? Date
            modificationDate = attrs[kSecAttrModificationDate as String] as? Date
            label = attrs[kSecAttrLabel as String] as? String
            account = attrs[kSecAttrAccount as String] as? String
            group = attrs[kSecAttrType as String] as? Int
            comment = attrs[kSecAttrComment as String] as? String
            description = attrs[kSecAttrDescription as String] as? String
            creator = attrs[kSecAttrCreator as String] as? Int

            securityDomain = attrs[kSecAttrSecurityDomain as String] as? String
            server = attrs[kSecAttrServer as String] as? String

            if let possibleProtocol = attrs[kSecAttrProtocol as String] as? String {
                `protocol` = .make(from: possibleProtocol as CFString)
            }

            if let possibleAuthType = attrs[kSecAttrAuthenticationType as String] as? String {
                authenticationType = .make(from: possibleAuthType as CFString)
            }

            port = attrs[kSecAttrPort as String] as? Int
            path = attrs[kSecAttrPath as String] as? String
        }
    }

    // MARK: - KeychainStorable

    public func entityQuery(includeSecureData: Bool) -> SecurityFrameworkQuery {
        var query = _entityQuery(includeSecureData: includeSecureData)

        query[kSecClass as String] = kSecClassInternetPassword

        if let theDomain = securityDomain {
            query[kSecAttrSecurityDomain as String] = theDomain
        }

        if let theServer = server {
            query[kSecAttrServer as String] = theServer
        }

        if let theProtocol = `protocol` {
            query[kSecAttrProtocol as String] = theProtocol.securityFrameworkValue()
        }

        if let theAuthenticationType = authenticationType {
            query[kSecAttrAuthenticationType as String] = theAuthenticationType.securityFrameworkValue()
        }

        if let thePort = port {
            query[kSecAttrPort as String] = thePort
        }

        if let thePath = path {
            query[kSecAttrPath as String] = thePath
        }

        return query
    }
}
