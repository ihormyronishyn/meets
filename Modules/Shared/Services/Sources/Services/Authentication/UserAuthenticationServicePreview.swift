//
//  UserAuthenticationServicePreview.swift
//  Services
//

#if DEBUG

    import Entities
    import Foundation

    @MainActor
    public final class UserAuthenticationServicePreview: UserAuthenticationServiceProtocol {

        // MARK: - Properties

        public private(set) var username: String?
        public private(set) var roomId: Int?

        public var isAuthenticated: Bool {
            username != nil && roomId != nil
        }

        // MARK: - Init

        public init(username: String? = Peer.Preview.local.username, roomId: Int? = Peer.Preview.local.roomId) {
            self.username = username
            self.roomId = roomId
        }

        // MARK: - Login

        public func login(username: String, roomId: Int) {
            self.username = username
            self.roomId = roomId
        }

        // MARK: - Logout

        public func logout() {
            username = nil
            roomId = nil
        }
    }

    // MARK: - Preview

    public extension UserAuthenticationServiceProtocol where Self == UserAuthenticationServicePreview {
        /// Somebody already signed into a room, so a canvas draws the screen that
        /// follows the entrance rather than the entrance itself.
        static var preview: UserAuthenticationServicePreview {
            UserAuthenticationServicePreview()
        }
    }

#endif
