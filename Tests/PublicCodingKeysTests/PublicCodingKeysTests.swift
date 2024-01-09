import MacroTesting
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import PublicCodingKeysMacros

final class PublicCodingKeysTests: XCTestCase {
    
    override func invokeTest() {
        withMacroTesting(
            macros: [
            "PublicCodingKeys": PublicCodingKeysMacro.self,
            "CodingKeyName": CodingKeyNameMacro.self,
            "CodingIgnored": CodingIgnoredMacro.self
        ]) {
            super.invokeTest()
        }
    }
    
    func testPublicCodingKeyMacro() throws {
        assertMacro {
            """
            @PublicCodingKeys
            public struct Person: Codable {
                var id: Int
                var name: String
                var email: String
                var dob: Date
            }
            """
        } expansion: {
            """
            public struct Person: Codable {
                var id: Int
                var name: String
                var email: String
                var dob: Date

                public enum CodingKeys: String, CodingKey {
                    case id
                    case name
                    case email
                    case dob
                }
            }
            """
        }
    }
    
    func testPublicCodingKeyNameMacro() throws {
        assertMacro {
            """
            public struct Person: Codable {
                @CodingKeyName("_id")
                var id: Int
            
                var name: String
                var email: String
            }
            """
        } expansion: {
            """
            public struct Person: Codable {
                var id: Int

                var name: String
                var email: String
            }
            """
        }
    }
    
    func testPublicCodingKeyNameWithPublicCodingKeyMacro() throws {
        assertMacro {
            """
            @PublicCodingKeys
            public struct Person: Codable {
                @CodingKeyName("_id")
                var id: Int
                var name: String
                var email: String
            }
            """
        } expansion: {
            """
            public struct Person: Codable {
                var id: Int
                var name: String
                var email: String

                public enum CodingKeys: String, CodingKey {
                    case id = "_id"
                    case name
                    case email
                }
            }
            """
        }
    }
    
    func testPublicCodingKeysWithComputedProperties() throws {
        assertMacro {
            #"""
            @PublicCodingKeys
            public struct Person: Codable {
                public var id: Int
                public var name: String
                public var email: String
            
                public var isEmailValid: Bool {
                    email.isEmpty == false
                }
                
                public var displayName: String {
                    get { self.name }
                    set { self.name = newValue }
                }
            }
            """#
        } expansion: {
            """
            public struct Person: Codable {
                public var id: Int
                public var name: String
                public var email: String

                public var isEmailValid: Bool {
                    email.isEmpty == false
                }
                
                public var displayName: String {
                    get { self.name }
                    set { self.name = newValue }
                }

                public enum CodingKeys: String, CodingKey {
                    case id
                    case name
                    case email
                }
            }
            """
        }
    }
    
    func testPublicCodingKeyWithCodingIgnored() throws {
        assertMacro {
            """
            @PublicCodingKeys
            public struct Row: Codable {
                @CodingKeyName("_id")
                public var id: Int
                
                @CodingKeyName("_val")
                public var value: Double
                
                @CodingIgnored
                public var item: String = "a"
            
                @CodingIgnored
                public var block: Int?
            }
            """
        } expansion: {
            """
            public struct Row: Codable {
                public var id: Int
                
                public var value: Double
                
                public var item: String = "a"
                public var block: Int?

                public enum CodingKeys: String, CodingKey {
                    case id = "_id"
                    case value = "_val"
                }
            }
            """
        }
    }
}
