import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import Foundation

@main
struct PublicCodingKeysPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        PublicCodingKeysMacro.self,
        CodingKeyNameMacro.self,
        CodingIgnoredMacro.self
    ]
}

public struct PublicCodingKeysMacro: MemberMacro {
 
    public enum Error: Swift.Error, CustomStringConvertible {
        case notAStruct
        case notPublicType
        case notConformingToCodable
        
        public var description: String {
            switch self {
            case .notAStruct:
                return "@PublicCodingKeys can only be applied to Struct"
            case .notPublicType:
                return "@PublicCodingKeys type should be marked public"
            case .notConformingToCodable:
                return "@PublicCodingKeys type must conform to Codable"
            }
        }
    }
    
    public static func expansion<D: DeclGroupSyntax, C: MacroExpansionContext>(of node: AttributeSyntax, providingMembersOf declaration: D, in context: C) throws -> [DeclSyntax] {
        guard declaration.is(StructDeclSyntax.self) else {
            context.addDiagnostics(from: Error.notAStruct, node: declaration)
            return []
        }
        guard declaration.as(StructDeclSyntax.self)?.modifiers.contains(where: {$0.name.text == "\(SwiftSyntax.Keyword.public)"}) == true else {
            context.addDiagnostics(from: Error.notPublicType, node: declaration)
            return []
        }
        guard declaration.as(StructDeclSyntax.self)?.inheritanceClause?.inheritedTypes.contains(where: { $0.type.as(IdentifierTypeSyntax.self)?.name.text == "Codable" }) == true else {
            context.addDiagnostics(from: Error.notConformingToCodable, node: declaration.modifiers)
            return []
        }

        let propertyIdentifier = declaration.propertyWithKeyNames
        
        guard let identifier = propertyIdentifier, !identifier.isEmpty else { return [] }
        let idenfitierToken = identifier.compactMap({$0.syntax}).joined(separator: "\n")
        let codingKeys =
        """
        public enum CodingKeys: String, CodingKey {
            \(idenfitierToken)
        }
        """
        return ["\(raw: codingKeys)"]
    }
}

public struct CodingKeyNameMacro: PeerMacro {
    static let attributeName = "CodingKeyName"
    public static func expansion(of node: AttributeSyntax, providingPeersOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        []
    }
}


public struct CodingIgnoredMacro: PeerMacro {
    static let attributeName = "CodingIgnored"
    
    enum Error: String, Swift.Error, CustomStringConvertible {
        case notAVariable
        case noDefaultValue
        
        var message: String {
            switch self {
            case .notAVariable:
                return "@CodingIgnored can only be applied to variables."
            case .noDefaultValue:
                return "@CodingIgnored properties must provide a default value or can be an optional type"
            }
        }
        
        var description: String { self.message }
    }
    
    public static func expansion<D: DeclSyntaxProtocol, C: MacroExpansionContext>(of node: AttributeSyntax, providingPeersOf declaration: D, in context: C) throws -> [DeclSyntax] {
        guard let variableDecl = declaration.as(VariableDeclSyntax.self) else {
            throw Error.notAVariable
        }
        if let isOptional = variableDecl.bindings.first?.isOptionalType {
            if isOptional == false, let hasDefaultValue = variableDecl.bindings.first?.hasInitializer {
                if hasDefaultValue == false {
                    context.addDiagnostics(from: Error.noDefaultValue, node: variableDecl.bindings)
                    return []
                }
            }
            return []
        }
        return []
    }
}

extension DeclGroupSyntax {
    var variableDecls: [VariableDeclSyntax]? {
        self.as(StructDeclSyntax.self)?.memberBlock.members.compactMap({$0.decl.as(VariableDeclSyntax.self)})
    }
    
    var propertyWithKeyNames: [PropertyWithKeyName]? {
        self.variableDecls?.compactMap({$0.propertyWithKeyName()})
    }
}

struct PropertyWithKeyName {
    var name: String
    var key: String?
    
    var syntax: String {
        ["case \(name)", key.map {"\"\($0)\""} ].compactMap({ $0 }).joined(separator: " = ")
    }
}

extension VariableDeclSyntax {
    func propertyWithKeyName() -> PropertyWithKeyName? {
        if let shouldIgnoreCodingKey = self.attributes.first?.as(AttributeSyntax.self)?.shouldIgnoreCodingKey {
            if shouldIgnoreCodingKey { return nil }
        }
        let hasAccessorBlock = self.bindings.first?.as(PatternBindingSyntax.self)?.hasAccessorBlock
        guard hasAccessorBlock == false else { return nil }
        guard let propertyName = self.bindings.first?.as(PatternBindingSyntax.self)?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else { return nil }
        let codingKeyName = self.attributes.first?.as(AttributeSyntax.self)?.codingKeyName()
        return PropertyWithKeyName(name: propertyName, key: codingKeyName)
    }
}

extension AttributeSyntax {
    var shouldIgnoreCodingKey: Bool {
        self.attributeName.as(IdentifierTypeSyntax.self)?.name.text == CodingIgnoredMacro.attributeName
    }
    
    func codingKeyName() -> String? {
        var keyName: String?
        if self.attributeName.as(IdentifierTypeSyntax.self)?.name.text == CodingKeyNameMacro.attributeName {
           keyName = self.arguments?.as(LabeledExprListSyntax.self)?.first?.expression.as(StringLiteralExprSyntax.self)?.segments.first?.as(StringSegmentSyntax.self)?.content.text
        }
        return keyName
    }
}


extension PatternBindingSyntax {
    var hasAccessorBlock: Bool {
        self.accessorBlock != nil
    }
}

extension PatternBindingSyntax {
    var hasInitializer: Bool {
        self.initializer != nil
    }
    
    var isOptionalType: Bool? {
        guard let typeAnnotation else { return nil }
        return typeAnnotation.type.is(OptionalTypeSyntax.self)
    }
}
