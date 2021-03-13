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
