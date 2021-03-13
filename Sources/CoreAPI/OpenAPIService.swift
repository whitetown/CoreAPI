//
//  OpenAPIService.swift
//  CoreAPI
//
//  Created by Sergey Chehuta on 13/03/2021.
//

import Foundation

public typealias OpenAPIService = APIService

public extension APIService {

    func GET(path: String) -> APIResource {
        return APIResource(path: path).get()
    }

    func POST(path: String) -> APIResource {
        return APIResource(path: path).post()
    }

    func PUT(path: String) -> APIResource {
        return APIResource(path: path).put()
    }

    func PATCH(path: String) -> APIResource {
        return APIResource(path: path).patch()
    }

    func DELETE(path: String) -> APIResource {
        return APIResource(path: path).delete()
    }
}
