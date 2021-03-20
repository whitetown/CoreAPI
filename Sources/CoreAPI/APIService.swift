//
//  APIService.swift
//
//  Created by Sergey Chehuta on 15/02/2020.
//  Copyright © 2020 WhiteTown. All rights reserved.
//

import Foundation

open class APIService {

    public var onLog: ((String) -> Void)?
    public var maxLogHeaderLength = -1

    public var signature:  ((URL?) -> [String : String])?
    public var on401Error: ((URL?) -> Void)?

    public let queue = OperationQueue()
    public let session = URLSession(configuration: .default)

    internal var baseURL:  URL?
    internal var headers = [String:String]()

    public init() {
        self.session.configuration.waitsForConnectivity = true
        self.session.configuration.timeoutIntervalForRequest = 60
    }

    open func prepareRequest(_ url: URL, _ resource: APIResource) -> URLRequest {
        return URLRequest(url: url,
                          resource: resource,
                          headers: self.headers,
                          signature: self.signature?(self.baseURL) ?? [:])
    }

    open func url(_ resource: APIResource) -> URL? {

        var urlString = resource.path ?? ""
        if let query  = resource.query.urlEncodedString(), query.count > 0  {
            urlString += "?" + query
        }

        if let baseURL = self.baseURL {
            return URL(string: urlString, relativeTo: baseURL)
        } else {
            return URL(string: urlString)
        }
    }

    open func load<T>(_ resource: APIResource,
                      parse: @escaping ((AnyObject, Data) -> T?),
                      completion: @escaping (Result<T, Error>) -> ()) {

        weak var welf = self
        let operation = BlockOperation {
            self.loadInternal(resource, parse: parse) { (result) in
                switch result {
                case .success(_):
                    completion(result)
                case .failure(let error):
                    if (error as? APIError)?.apiCode == .unauthorised, let on401Error = welf?.on401Error {
                        welf?.suspend()
                        welf?.reloadResource(resource, parse: parse, completion: completion)
                        on401Error(welf?.baseURL)
                    } else {
                        completion(result)
                    }
                }
            }
        }
        self.queue.addOperation(operation)
    }

    private func loadInternal<T>(_ resource: APIResource,
                      parse: @escaping ((AnyObject, Data) -> T?),
                      completion: @escaping (Result<T, Error>) -> ()) {

        guard let url = self.url(resource) else {
            completion(.failure(APIError(.wrongURL)))
            return
        }

        let request = prepareRequest(url, resource)
        self.session.dataTask(with: request) { data, response, error in
            
            DispatchQueue.global().async {
                self.log(request, data, response, error)
            }

            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

            if let error = error {
                completion(.failure(APIError(.otherHTTP, statusCode: statusCode, error: error, response: response)))
                return
            }

            if let error = APIError.checkResponse(response, data: data) {
                completion(.failure(error))
                return
            }

            if  let data = data,
                let json = try? JSONSerialization.jsonObject(with: data, options: []) as AnyObject,
                let result = parse(json, data) {
                    completion(.success(result))
                return
            }

            if [200, 201, 202, 204].contains(statusCode) {
                if let result = true as? T {
                    completion(.success(result))
                    return
                }
            }

            completion(.failure(APIError(.noData, statusCode: statusCode)))

        }.resume()
    }

    private func reloadResource<T>(_ resource: APIResource,
                                   parse: @escaping ((AnyObject, Data) -> T?),
                                   completion: @escaping (Result<T, Error>) -> ()) {
        self.loadInternal(resource, parse: parse, completion: completion)
    }

    private func log(_ request: URLRequest, _ data: Data?, _ response: URLResponse?, _ error: Error?) {
        
        guard let onLog = self.onLog else { return }

        var messages = [String]()
        
        messages.append(DateFormatter.logPrefix() + "\(request.httpMethod ?? "") REQUEST " + String(repeating: "-", count: 30))

        messages.append(request.url?.absoluteString ?? "")
        if let headers = request.allHTTPHeaderFields {
            messages.append("HEADERS: \(self.maxLogHeaderLength >= 0 ? String(headers.description.prefix(self.maxLogHeaderLength)) : headers.description)")
        }
        if  let httpBody = request.httpBody {
            let value = String(data: httpBody, encoding: .utf8)
            let json = try? JSONSerialization.jsonObject(with: httpBody, options: []) as AnyObject
            messages.append("BODY: \(value ?? json?.description ?? "")")
        }

        messages.append(DateFormatter.logPrefix() + "\((response as? HTTPURLResponse)?.statusCode ?? 0) RESPONSE " + String(repeating: "-", count: 30))

        if let headers = (response as? HTTPURLResponse)?.allHeaderFields as? [String:Any] {
            messages.append("HEADERS: \(headers.description)")
        }

        if  let data = data,
            let value = String(data: data, encoding: .utf8) {
            //let json = try? JSONSerialization.jsonObject(with: data, options: []) as AnyObject {
            messages.append("DATA: \(value)")
        }

        if let error = error {
            messages.append("ERROR: \(error)")
        }

        messages.append(String(repeating: "-", count: 20) + " ¯\\_(ツ)_/¯ " + String(repeating: "-", count: 20))
        
        let result = messages.joined(separator: "\n") + "\n"
        //print(result)
        onLog(result)
    }

}

public extension APIService {

    @discardableResult
    func base(_ baseURL: URL) -> Self {
        self.baseURL = baseURL
        return self
    }

    @discardableResult
    func base(_ urLString: String) -> Self {
        self.baseURL = URL(string: urLString)
        return self
    }

    @discardableResult
    func header(value: String, for key: String) -> Self {
        self.headers[key] = value
        return self
    }

    @discardableResult
    func headers(values: [String:String]) -> Self {
        values.forEach { (key, value) in
            self.headers[key] = value
        }
        return self
    }

    @discardableResult
    func onLog(_ log: @escaping ((String) -> Void)) -> Self {
        self.onLog = log
        return self
    }

    @discardableResult
    func onError401(_ error401: @escaping ((URL?) -> Void)) -> Self {
        self.on401Error = error401
        return self
    }

    @discardableResult
    func onSignature(_ signature: @escaping ((URL?) -> [String : String])) -> Self {
        self.signature = signature
        return self
    }

    func suspend() {
        self.queue.isSuspended = true
    }

    func resume() {
        self.queue.isSuspended = false
    }

    func cancelAllRequests() {
        self.queue.cancelAllOperations()
    }

}

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
