import Foundation

public extension JSON {

    /// Return the string value if this is a `.string`, otherwise `nil`
    var stringValue: String? {
        if case .string(let value) = self {
            return value
        }
        return nil
    }

    /// Return the double value if this is a `.number`, otherwise `nil`
    var doubleValue: Double? {
        if case .number(let value) = self {
            return value
        }
        return nil
    }

    /// Return the bool value if this is a `.bool`, otherwise `nil`
    var boolValue: Bool? {
        if case .bool(let value) = self {
            return value
        }
        return nil
    }

    /// Return the object value if this is an `.object`, otherwise `nil`
    var objectValue: [String: JSON]? {
        if case .object(let value) = self {
            return value
        }
        return nil
    }

    /// Return the array value if this is an `.array`, otherwise `nil`
    var arrayValue: [JSON]? {
        if case .array(let value) = self {
            return value
        }
        return nil
    }

    /// Return `true` iff this is `.null`
    var isNull: Bool {
        if case .null = self {
            return true
        }
        return false
    }

    /// If this is an `.array`, return item at index
    ///
    /// If this is not an `.array` or the index is out of bounds, returns `nil`.
    subscript(index: Int) -> JSON? {
        if case .array(let arr) = self, arr.indices.contains(index) {
            return arr[index]
        }
        return nil
    }

    /// If this is an `.object`, return item at key
    subscript(key: String) -> JSON? {
        if case .object(let dict) = self {
            return dict[key]
        }
        return nil
    }

    /// Dynamic member lookup sugar for string subscripts
    ///
    /// This lets you write `json.foo` instead of `json["foo"]`.
    subscript(dynamicMember member: String) -> JSON? {
        return self[member]
    }
    
    /// Return the JSON type at the keypath if this is an `.object`, otherwise `nil`
    ///
    /// This lets you write `json[keyPath: "foo.bar.jar"]`.
    subscript(keyPath keyPath: String) -> JSON? {
        return queryKeyPath(keyPath.components(separatedBy: "."))
    }
    
    func queryKeyPath<T>(_ path: T) -> JSON? where T: Collection, T.Element == String {
        
        // Only object values may be subscripted
        guard case .object(let object) = self else {
            return nil
        }
        
        // Is the path non-empty?
        guard let head = path.first else {
            return nil
        }
        
        // Do we have a value at the required key?
        guard let value = object[head] else {
            return nil
        }
        
        let tail = path.dropFirst()
        
        return tail.isEmpty ? value : value.queryKeyPath(tail)
    }
    
}
