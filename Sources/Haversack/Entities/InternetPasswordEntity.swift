// SPDX-License-Identifier: MIT
// Copyright 2023, Jamf

import Foundation

/// Represents a password to an account on another computer or website in the keychain.
///
/// The combination of `server` and `account` values is unique per internet password in the keychain.
public class InternetPasswordEntity: PasswordBaseEntity {
    /// The Internet security domain.
    /// - Note: Uses `kSecAttrSecurityDomain`
    public var securityDomain: String?

    /// Contains the server's domain name or IP address.
    /// - Note: Uses `kSecAttrServer`
    public var server: String?

    /// A communications protocol for internet passwords.
    /// - Note: Mirrors the `kSecAttrProtocol...` constants.
    public enum NetworkProtocol {
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

        private static let translation: [CFString: NetworkProtocol] = [
            kSecAttrProtocolFTP: FTP,
            kSecAttrProtocolFTPAccount: FTPAccount,
            kSecAttrProtocolHTTP: HTTP,
            kSecAttrProtocolIRC: IRC,
            kSecAttrProtocolNNTP: NNTP,
            kSecAttrProtocolPOP3: POP3,
            kSecAttrProtocolSMTP: SMTP,
            kSecAttrProtocolSOCKS: SOCKS,
            kSecAttrProtocolIMAP: IMAP,
            kSecAttrProtocolLDAP: LDAP,
            kSecAttrProtocolAppleTalk: appleTalk,
            kSecAttrProtocolAFP: AFP,
            kSecAttrProtocolTelnet: telnet,
            kSecAttrProtocolSSH: SSH,
            kSecAttrProtocolFTPS: FTPS,
            kSecAttrProtocolHTTPS: HTTPS,
            kSecAttrProtocolHTTPProxy: HTTPProxy,
            kSecAttrProtocolHTTPSProxy: HTTPSProxy,
            kSecAttrProtocolFTPProxy: FTPProxy,
            kSecAttrProtocolSMB: SMB,
            kSecAttrProtocolRTSP: RTSP,
            kSecAttrProtocolRTSPProxy: RTSPProxy,
            kSecAttrProtocolDAAP: DAAP,
            kSecAttrProtocolEPPC: EPPC,
            kSecAttrProtocolIPP: IPP,
            kSecAttrProtocolNNTPS: NNTPS,
            kSecAttrProtocolLDAPS: LDAPS,
            kSecAttrProtocolTelnetS: telnetS,
            kSecAttrProtocolIMAPS: IMAPS,
            kSecAttrProtocolIRCS: IRCS,
            kSecAttrProtocolPOP3S: POP3S
        ]

        static func make(from securityFrameworkValue: CFString) -> NetworkProtocol? {
            return translation[securityFrameworkValue]
        }

        func securityFrameworkValue() -> CFString {
            return Self.translation.first(where: { $1 == self })!.key
        }
    }

    /// Denotes the protocol to access the account on the server.
    /// - Note: Uses `kSecAttrProtocol`
    public var `protocol`: NetworkProtocol?

    /// An authentication scheme for internet passwords.
    /// - Note: Mirrors the `kSecAttrAuthenticationType...` constants.
    public enum AuthenticationType {
        case NTLM
        case MSN
        case DPA
        case RPA
        case HTTPBasic
        case HTTPDigest
        case HTMLForm
        case `default`

        private static let translation: [CFString: AuthenticationType] = [
            kSecAttrAuthenticationTypeNTLM: NTLM,
            kSecAttrAuthenticationTypeMSN: MSN,
            kSecAttrAuthenticationTypeDPA: DPA,
            kSecAttrAuthenticationTypeRPA: RPA,
            kSecAttrAuthenticationTypeHTTPBasic: HTTPBasic,
            kSecAttrAuthenticationTypeHTTPDigest: HTTPDigest,
            kSecAttrAuthenticationTypeHTMLForm: HTMLForm,
            kSecAttrAuthenticationTypeDefault: `default`
        ]

        static func make(from securityFrameworkValue: CFString) -> AuthenticationType? {
            return translation[securityFrameworkValue]
        }

        func securityFrameworkValue() -> CFString {
            return Self.translation.first(where: { $1 == self })!.key
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
    override public init() {
        super.init()
    }

    public required init(from keychainItemRef: SecurityFrameworkType?, data: Data?,
                         attributes: [String: Any]?, persistentRef: Data?) {
        super.init(from: keychainItemRef, data: data, attributes: attributes, persistentRef: persistentRef)

        if let attrs = attributes {
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

    override public func entityQuery(includeSecureData: Bool) -> SecurityFrameworkQuery {
        var query = super.entityQuery(includeSecureData: includeSecureData)

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
