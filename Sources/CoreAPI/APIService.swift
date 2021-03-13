//
//  APIService.swift
//
//  Created by Sergey Chehuta on 15/02/2020.
//  Copyright © 2020 WhiteTown. All rights reserved.
//

import Foundation

open class APIService {

    public var onLogging: ((String) -> Void)?

    internal var baseURL:  URL?
    internal var headers = [String:String]()

    public let session = URLSession(configuration: .default)

    public init() {
        self.session.configuration.waitsForConnectivity = true
        self.session.configuration.timeoutIntervalForRequest = 60
    }

    open func prepareRequest(_ url: URL, _ resource: APIResource) -> URLRequest {
        return URLRequest(url: url,
                          resource: resource,
                          headers: self.headers)
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

        guard let url = self.url(resource) else {
            DispatchQueue.main.async { completion(.failure(APIError(.wrongURL))) }
            return
        }

        let request = prepareRequest(url, resource)
        self.session.dataTask(with: request) { data, response, error in
            DispatchQueue.global().async {
            self.log(request, data, response, error)
            }

            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(APIError(.otherHTTP, statusCode: statusCode, error: error, response: response)))
                }
                return
            }

            if let error = APIError.checkResponse(response, data: data) {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }

            if  let data = data,
                let json = try? JSONSerialization.jsonObject(with: data, options: []) as AnyObject,
                let result = parse(json, data) {
                DispatchQueue.main.async { completion(.success(result)) }
                return
            }

            if [200, 201, 202, 204].contains(statusCode) {
                if let result = true as? T {
                    DispatchQueue.main.async { completion(.success(result)) }
                    return
                }
            }

            DispatchQueue.main.async { completion(.failure(APIError(.noData, statusCode: statusCode))) }

        }.resume()
    }

    private func log(_ request: URLRequest, _ data: Data?, _ response: URLResponse?, _ error: Error?) {
        
        guard let onLogging = self.onLogging else { return }

        var messages = [String]()
        
        messages.append(DateFormatter.logPrefix() + "\(request.httpMethod ?? "") REQUEST " + String(repeating: "-", count: 30))

        messages.append(request.url?.absoluteString ?? "")
        if let headers = request.allHTTPHeaderFields {
            messages.append("HEADERS: \(headers.description)")
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
        onLogging(result)
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
    func on(log: @escaping ((String) -> Void)) -> Self {
        self.onLogging = log
        return self
    }

}
