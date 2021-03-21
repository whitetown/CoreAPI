//
//  NSMutableData.swift
//  CoreAPI
//
//  Created by Sergey Chehuta on 13/03/2021.
//

import Foundation

extension NSMutableData {

    func append(value: Any) {
        if      let value = value as? Bool { self.append(boolValue: value) }
        else if let value = value as? Int { self.append(intValue: value) }
        else if let value = value as? String { self.append(stringValue: value) }
        else {
            if let data = "\(value)".data(using: .utf8, allowLossyConversion: false) {
                self.append(data)
            }
        }
    }

    func append(stringValue: String) {
        if let data = stringValue.data(using: .utf8, allowLossyConversion: false) {
            self.append(data)
        }
    }

    func append(boolValue: Bool) {
        if let data = "\(boolValue)".data(using: .utf8) {
            self.append(data)
        }
    }

    func append(intValue: Int) {
        if let data = "\(intValue)".data(using: .utf8) {
            self.append(data)
        }
    }

}
