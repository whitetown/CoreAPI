//
//  DateFormatter.swift
//  CoreAPI
//
//  Created by Sergey Chehuta on 13/03/2021.
//

import Foundation

extension DateFormatter {
    
    static let iso8601Full: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    static var coreAPI: DateFormatter = {
        let result = DateFormatter()
        result.dateFormat = "HH:mm:ss.SSS"
        return result
    }()

    static func logPrefix(_ date: Date = Date()) -> String {
        return "----- \(DateFormatter.coreAPI.string(from: date)) -- CoreAPI "
    }
}
