//
//  String.swift
//  CoreAPI
//
//  Created by Sergey Chehuta on 10/03/2021.
//

import Foundation

extension String {

    public var trimmed: String {
        return self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }

}

extension String {

    func fixURL() -> String {
        if self.trimmed.count > 0 {
            if !self.hasSuffix("/") {
                return self.trimmed + "/"
            }
        }
        return self
    }

    func fixPath() -> String {
        if self.hasPrefix("/") {
            return String(self.dropFirst())
        } else {
            return self
        }
    }
}
