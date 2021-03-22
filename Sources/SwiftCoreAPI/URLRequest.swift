//
//  URLRequest.swift
//  CoreAPI
//
//  Created by Sergey Chehuta on 13/03/2021.
//

import Foundation

public let jsonHeader: [String: String] = [
    "Content-Type": "application/json",
    "Accept-Type":  "application/json",
    ]

extension URLRequest {

    init(url: URL, resource: APIResource, headers: [String:String], signature: [String:String] = [:]) {

        self.init(url: url)
        self.httpMethod = resource.method.rawValue
        for (field, value) in headers {
            self.setValue(value, forHTTPHeaderField: field)
        }
        for (field, value) in signature {
            self.setValue(value, forHTTPHeaderField: field)
        }
        if resource.isJSON {
            for (field, value) in jsonHeader {
                self.setValue(value, forHTTPHeaderField: field)
            }
        }
        for (field, value) in resource.headers {
            self.setValue(value, forHTTPHeaderField: field)
        }
        if resource.method != .get {
            self.httpBody = resource.data
        }
    }
}
