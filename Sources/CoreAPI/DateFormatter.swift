//
//  DateFormatter.swift
//  CoreAPI
//
//  Created by Sergey Chehuta on 13/03/2021.
//

import Foundation

extension DateFormatter {

    static var coreAPI: DateFormatter = {
        let result = DateFormatter()
        result.dateFormat = "HH:mm:ss.SSS"
        return result
    }()

    static func logPrefix() -> String {
        return "----- \(DateFormatter.coreAPI.string(from: Date())) -- CoreAPI "
    }
}
