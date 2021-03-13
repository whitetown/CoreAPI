//
//  APIMethod.swift
//  CoreAPI
//
//  Created by Sergey Chehuta on 13/03/2021.
//

import Foundation

public enum APIMethod: String {
    case get
    case post
    case put
    case patch
    case delete

    var stringValue: String {
        switch self {
        case .get:    return "GET"
        case .post:   return "POST"
        case .put:    return "PUT"
        case .patch:  return "PATCH"
        case .delete: return "DELETE"
        }
    }
}
