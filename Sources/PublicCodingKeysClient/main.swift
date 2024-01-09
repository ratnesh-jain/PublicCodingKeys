import PublicCodingKeys

@PublicCodingKeys
public struct Person: Codable {
    public var id: Int
    public var name: String
    public var email: String
}

@PublicCodingKeys
public struct Item: Codable {
    
    @CodingKeyName("_id")
    public var id: Int
    public var text: String
}

@PublicCodingKeys
public struct Row: Codable {
    @CodingKeyName("_id")
    public var id: Int
    
    @CodingKeyName("_val")
    public var value: Double
    
    @CodingIgnored
    public var item: String?
}
