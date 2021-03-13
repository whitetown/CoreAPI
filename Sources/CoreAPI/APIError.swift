//
//  APIError.swift
//
//  Created by Sergey Chehuta on 15/02/2020.
//  Copyright © 2020 WhiteTown. All rights reserved.
//

import Foundation

public struct APIError: Error {

    public let apiCode:    APIErrorCode
    public let statusCode: Int
    public let error:      Error?
    public let response:   URLResponse? = nil
    public let responseCode: NSDictionary?
    public let data:       Data?

    public init(_ apiCode: APIErrorCode, statusCode: Int = 0, error: Error? = nil, response: URLResponse? = nil, data: Data? = nil) {
        self.apiCode = apiCode
        self.statusCode = statusCode
        self.error = error
        //self.response = response
        self.responseCode = APIError.parseResponseCode(data)
        self.data = data
    }
    
    static func checkResponse(_ response: URLResponse?, data: Data?) -> APIError? {
        
        guard let response = response as? HTTPURLResponse else {
            return APIError(.wrongResponse, data: data)
        }

        switch response.statusCode {
        case 200..<205:
            return nil
        case 400:
            return APIError(.badRequest, statusCode: response.statusCode, response: response, data: data)
        case 401:
            return APIError(.unauthorised, statusCode: response.statusCode, response: response, data: data)
        case 403:
            return APIError(.forbidden, statusCode: response.statusCode, response: response, data: data)
        case 404:
            return APIError(.resourceNotFound, statusCode: response.statusCode, response: response, data: data)
        case 500:
            return APIError(.internalServerError, statusCode: response.statusCode, response: response, data: data)
        default:
            return APIError(.otherHTTP, statusCode: response.statusCode, response: response, data: data)
        }

    }
    
    static func parseResponseCode(_ data: Data?) -> NSDictionary? {
        if  let data = data {
            return try? JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary
        }
        return nil
    }

    public var errorMessage: String? {
        return (self.responseCode?["message"] as? String)
            ?? (self.responseCode?["error_description"] as? String)
    }

}
