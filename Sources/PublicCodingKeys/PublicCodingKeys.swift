// The Swift Programming Language
// https://docs.swift.org/swift-book

/// A macro that produces a public declaration of the CodingKeys enum
/// used for the Codable conformance. For example,
///
///     @PublicCodingKeys
///     public struct Item: Codable {
///         public var id: Int
///         public var text: String
///     }
///
/// expands to
///
///     @PublicCodingKeys
///     public struct Item: Codable {
///         public var id: Int
///         public var text: String
///
///         public enum CodingKeys: CodingKey {
///             case id
///             case text
///         }
///     }
/// For this target type must be declared `public` and conform to `Codable`.
@attached(member, names: named(CodingKeys))
public macro PublicCodingKeys() = #externalMacro(module: "PublicCodingKeysMacros", type: "PublicCodingKeysMacro")

/// A peer macro that should be attached to a property of the target type.
///
/// For some cases, the networking API returning json with some different name of the key,
/// and in the Swift data types are using naming convensions.
/// In these cases CodingKeyName is useful to provide the different name.
///
///     @PublicCodingKeys
///     public struct Item: Codable {
///         @CodingKeyName("_id")
///         public var id: Int
///         public var text: String
///     }
///
/// expands to
///
///     @PublicCodingKeys
///     public struct Item: Codable {
///         @CodingKeyName("_id")
///         public var id: Int
///         public var text: String
///
///         public enum CodingKeys: CodingKey {
///             case id = "_id"
///             case text
///         }
///     }
///
@attached(peer)
public macro CodingKeyName(_ name: String) = #externalMacro(module: "PublicCodingKeysMacros", type: "CodingKeyNameMacro")

/// For some cases, the properties are not needed to participate in the Encoding/Decoding operations.
/// In such cases CodingIgnored Macro is used to prevent the CodingKey generation for such properties.
///
/// NOTE: These properies **MUST** have a *default value* or *optional type* in order to qualify for `Codable` type.
///
///     @PublicCodingKeys
///     public struct Item: Codable {
///         @CodingKeyName("_id")
///         public var id: Int
///         public var text: String
///         @CodingIgnored
///         public var date: Date?
///     }
///
/// expands to
///
///     @PublicCodingKeys
///     public struct Item: Codable {
///         @CodingKeyName("_id")
///         public var id: Int
///         public var text: String
///         @CodingIgnored
///         public var date: Date?
///
///         public enum CodingKeys: String, CodingKey {
///             case id = "_id"
///             case text
///         }
///     }
///
@attached(peer)
public macro CodingIgnored() = #externalMacro(module: "PublicCodingKeysMacros", type: "CodingIgnoredMacro")
