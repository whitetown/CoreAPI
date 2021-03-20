//
//  APIResource.swift
//
//  Created by Sergey Chehuta on 15/02/2020.
//  Copyright © 2020 WhiteTown. All rights reserved.
//

import Foundation

public class APIResource {

    var path:     String?
    var method:   APIMethod = .get
    var headers = [String: String]()
    var data:     Data?
    var query   = [String: Any]()
    var isJSON  = true

    public init(path:      String? = nil,
                method:    APIMethod = .get,
                headers:   [String: String] = [:],
                data:      Data?,
                query:     [String: Any] = [:]) {

        self.path    = path?.fixPath()
        self.method  = method
        self.headers = headers
        self.data    = data
        self.query   = query
    }

    public convenience init(path:      String? = nil,
                            method:    APIMethod = .get,
                            headers:   [String: String] = [:],
                            body:      [String: Any] = [:],
                            query:     [String: Any] = [:]) {

        self.init(path:     path?.fixPath(),
                  method:   method,
                  headers:  headers,
                  data:     try? JSONSerialization.data(withJSONObject: body),
                  query:    query)
    }

    public convenience init<E: Encodable>(path:      String? = nil,
                                          method:    APIMethod = .get,
                                          headers:   [String: String] = [:],
                                          payload:   E,
                                          query:     [String: Any] = [:]) {

        self.init(path:     path?.fixPath(),
                  method:   method,
                  headers:  headers,
                  data:     try? JSONEncoder().encode(payload),
                  query:    query)
    }

}

public extension APIResource {

    func path(_ path: String) -> Self {
        self.path = path.fixPath()
        return self
    }

    func header(value: String, for key: String) -> Self {
        self.headers[key] = value
        return self
    }

    func headers(values: [String:String]) -> Self {
        values.forEach { (key, value) in
            self.headers[key] = value
        }
        return self
    }

    func data(_ value: Data) -> Self {
        self.data = value
        return self
    }

    func body(_ value: [String:Any]) -> Self {
        self.data = try? JSONSerialization.data(withJSONObject: value)
        return self
    }

    func payload<E:Encodable>(_ value: E) -> Self {
        self.data = try? JSONEncoder().encode(value)
        return self
    }

    func query(_ value: [String:Any]) -> Self {
        self.query = value
        return self
    }

    func multipart(_ payload: [Multipart]) -> Self {
        let (data, boundary) = create(multipart: payload)
        self.isJSON = false
        return self
                .header(value: "multipart/form-data; boundary=\(boundary)", for: "Content-Type")
                .header(value: "\(data.count)", for: "Content-Length")
                .data(data)
    }

    func create(multipart payload: [Multipart]) -> (Data, String) {

        // generate boundary string using a unique per-app string
        let boundary = UUID().uuidString

        let result = NSMutableData()

        payload.forEach { (part) in
            switch part {
            case .form(let key, let value):

                result.append(stringValue: "\r\n--\(boundary)\r\n")
                result.append(stringValue: "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                result.append(value: value)

            case .file(let name, let url, let filename, let type):

                if let data = try? Data(contentsOf: url) {

                    result.append(stringValue: "\r\n--\(boundary)\r\n")
                    result.append(stringValue: "Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n")
                    result.append(stringValue: "Content-Type: \(type)\r\n\r\n")
                    result.append(data)
                }

            case .data(let name, let data, let filename, let type):

                result.append(stringValue: "\r\n--\(boundary)\r\n")
                result.append(stringValue: "Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n")
                result.append(stringValue: "Content-Type: \(type)\r\n\r\n")
                result.append(data)

            case .image(let name, let image, let filename):

                if let data = image.jpegData(compressionQuality: 1) {
                    let type = "image/jpeg"

                    result.append(stringValue: "\r\n--\(boundary)\r\n")
                    result.append(stringValue: "Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n")
                    result.append(stringValue: "Content-Type: \(type)\r\n\r\n")
                    result.append(data)
                }

            }
        }

        // End the raw http request data, note that there is 2 extra dash ("-") at the end, this is to indicate the end of the data
        // According to the HTTP 1.1 specification https://tools.ietf.org/html/rfc7230
        result.append(stringValue: "\r\n--\(boundary)--\r\n")

        return (result as Data, boundary)
    }

    func get() -> Self {
        self.method = .get
        return self
    }

    func post() -> Self {
        self.method = .post
        return self
    }

    func put() -> Self {
        self.method = .put
        return self
    }

    func patch() -> Self {
        self.method = .patch
        return self
    }

    func delete() -> Self {
        self.method = .delete
        return self
    }
}

extension String {

    func fixPath() -> String {
        if self.hasPrefix("/") {
            return String(self.dropFirst())
        } else {
            return self
        }
    }
}
