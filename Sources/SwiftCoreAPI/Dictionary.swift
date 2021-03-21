//
//  Dictionary.swift
//  CoreAPI
//
//  Created by Sergey Chehuta on 13/03/2021.
//

import Foundation

extension Dictionary where Key == String, Value == Any {

    func urlEncodedString() -> String? {
        if self.count == 0 { return nil }

        let array: [String] = self.map { (key, value) in
            if let values = value as? [Any] {
                let joinedValues = values.map { "\($0)" }.joined(separator: ",")
                return "\(key)=\(joinedValues)"
            }
            else {
                return "\(key)=\(value)"
            }
        }

        let allowedCharacterSet = CharacterSet(charactersIn: "!';:@+$/?%#[] ").inverted
        return array
                .joined(separator: "&")
                .addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)
    }
}
