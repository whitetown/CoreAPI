//
//  APIErrorCode.swift
//  CoreAPI
//
//  Created by Sergey Chehuta on 13/03/2021.
//

import Foundation

public enum APIErrorCode {
    case wrongURL
    case wrongRefreshToken
    case wrongResponse
    case noData
    case badRequest
    case unauthorised
    case forbidden
    case resourceNotFound
    case internalServerError
    case otherHTTP
}
