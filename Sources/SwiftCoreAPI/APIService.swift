//
//  APIService.swift
//
//  Created by Sergey Chehuta on 15/02/2020.
//  Copyright © 2020 WhiteTown. All rights reserved.
//

import Foundation

open class APIService: NSObject {

    public typealias ProgressHandler = (Double) -> Void

    public var onLog: ((String) -> Void)?
    public var maxLogHeaderLength = -1

    public var signature:  ((URL?) -> [String : String])?
    public var on401Error: ((URL?) -> Void)?
    public var on401ErrorWithCallback: ((URL?, @escaping (_ reload: Bool)->Void) -> Void)?

    public var defaultDecoder = JSONDecoder()

    public let queue = OperationQueue()
    public lazy var session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)

    internal var baseURL:  URL?
    internal var headers = [String:String]()

    private var progressHandlersByTaskID = [Int : ProgressHandler]()

    public override init() {
        super.init()

        self.session.configuration.waitsForConnectivity = true
        self.session.configuration.timeoutIntervalForRequest = 60

        //self.defaultDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Full)
        self.defaultDecoder.dateDecodingStrategyFormatters = [
            DateFormatter.iso8601Full,
            DateFormatter.iso8601ShortZ,
            DateFormatter.iso8601Short,
            DateFormatter.yyyyMMdd_HHmmss,
        ]
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

    @discardableResult
    open func load<T>(_ resource: APIResource,
                      parse: @escaping ((AnyObject, Data) -> T?),
                      completion: @escaping (Result<T, Error>) -> ()) -> Operation {

        weak var welf = self
        let operation = BlockOperation {
            self.loadInternal(resource, parse: parse) { (result) in
                welf?.resultHandler(result, onReload: {
                    welf?.reloadResource(resource, parse: parse, completion: completion)
                }, completion: completion)
            }
        }
        self.queue.addOperation(operation)
        return operation
    }

    @discardableResult
    open func load<T: Decodable>(_ resource: APIResource,
                                 _ type: T.Type,
                                 completion: @escaping (Result<T, Error>) -> ()) -> Operation {

        return self.load(resource, parse: { (_, data) -> T? in
            return try? self.defaultDecoder.decode(T.self, from: data)
        }, completion: completion)
    }

    @discardableResult
    open func upload<T>(_ resource: APIResource,
                        parse: @escaping ((AnyObject, Data) -> T?),
                        onProgress: @escaping ProgressHandler,
                        completion: @escaping (Result<T, Error>) -> ()) -> Operation {

        weak var welf = self
        let operation = BlockOperation {
            self.uploadInternal(resource, parse: parse, onProgress: onProgress) { (result) in
                welf?.resultHandler(result, onReload: {
                    welf?.reuploadResource(resource, parse: parse, onProgress: onProgress, completion: completion)
                }, completion: completion)
            }
        }
        self.queue.addOperation(operation)
        return operation
    }

    @discardableResult
    open func upload<T: Decodable>(_ resource: APIResource,
                                   _ type: T.Type,
                                   onProgress: @escaping ProgressHandler,
                                   completion: @escaping (Result<T, Error>) -> ()) -> Operation {

        return self.upload(resource, parse: { (_, data) -> T? in
            return try? self.defaultDecoder.decode(T.self, from: data)
        }, onProgress: onProgress, completion: completion)
    }

}

private extension APIService {

    func resultHandler<T>(_ result: Result<T, Error>,
                          onReload: @escaping ()->Void,
                          completion: @escaping (Result<T, Error>) -> ()) {

        switch result {
        case .success(_):
            completion(result)
        case .failure(let error):
            if (error as? APIError)?.apiCode == .unauthorised {

                if let on401ErrorWithCallback = self.on401ErrorWithCallback {
                    self.suspend()
                    on401ErrorWithCallback(self.baseURL) { reload in
                        if reload {
                            onReload()
                        }
                    }

                } else if let on401Error = self.on401Error {
                    self.suspend()
                    on401Error(self.baseURL)

                } else {
                    completion(result)
                }

            } else {
                completion(result)
            }
        }
    }

    func responseHandler<T>(_ data: Data?,
                            _ response: URLResponse?,
                            _ error: Error?,
                            parse: @escaping ((AnyObject, Data) -> T?),
                            completion: @escaping (Result<T, Error>) -> ()) {

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
    }

    func loadInternal<T>(_ resource: APIResource,
                         parse: @escaping ((AnyObject, Data) -> T?),
                         completion: @escaping (Result<T, Error>) -> ()) {

        guard let url = self.url(resource) else {
            completion(.failure(APIError(.wrongURL)))
            return
        }

        weak var welf = self
        let startTime = Date()
        let request = prepareRequest(url, resource)
        let task = self.session.dataTask(with: request) { data, response, error in
            let endTime = Date()
            DispatchQueue.global().async {
                self.log(request, data, response, error, startTime, endTime)
            }
            welf?.responseHandler(data, response, error, parse: parse, completion: completion)
        }

        task.resume()
    }

    func reloadResource<T>(_ resource: APIResource,
                                   parse: @escaping ((AnyObject, Data) -> T?),
                                   completion: @escaping (Result<T, Error>) -> ()) {
        self.loadInternal(resource, parse: parse, completion: completion)
    }

    func uploadInternal<T>(_ resource: APIResource,
                                   parse: @escaping ((AnyObject, Data) -> T?),
                                   onProgress: @escaping ProgressHandler,
                                   completion: @escaping (Result<T, Error>) -> ()) {

        guard let url = self.url(resource) else {
            completion(.failure(APIError(.wrongURL)))
            return
        }

        weak var welf = self
        let startTime = Date()
        let data = resource.data ?? Data()
        resource.data = nil
        let request = prepareRequest(url, resource)

        let task = self.session.uploadTask(with: request, from: data) { data, response, error in
            let endTime = Date()
            DispatchQueue.global().async {
                self.log(request, data, response, error, startTime, endTime)
            }
            welf?.responseHandler(data, response, error, parse: parse, completion: completion)
        }
        self.progressHandlersByTaskID[task.taskIdentifier] = onProgress
        task.resume()
    }

    func reuploadResource<T>(_ resource: APIResource,
                                   parse: @escaping ((AnyObject, Data) -> T?),
                                   onProgress: @escaping ProgressHandler,
                                   completion: @escaping (Result<T, Error>) -> ()) {
        self.uploadInternal(resource, parse: parse, onProgress: onProgress, completion: completion)
    }

    func log(_ request: URLRequest,
             _ data: Data?,
             _ response: URLResponse?,
             _ error: Error?,
             _ startTime: Date,
             _ endTime: Date) {
        
        guard let onLog = self.onLog else { return }

        var messages = [String]()
        
        messages.append(DateFormatter.logPrefix(startTime) + "\(request.httpMethod ?? "") REQUEST " + String(repeating: "-", count: 30))

        messages.append(request.url?.absoluteString ?? "")
        if let headers = request.allHTTPHeaderFields {
            messages.append("HEADERS: \(self.maxLogHeaderLength >= 0 ? String(headers.description.prefix(self.maxLogHeaderLength)) : headers.description)")
        }
        if  let httpBody = request.httpBody {
            let value = String(data: httpBody, encoding: .utf8)
            let json = try? JSONSerialization.jsonObject(with: httpBody, options: []) as AnyObject
            messages.append("BODY: \(value ?? json?.description ?? "")")
        }

        messages.append(DateFormatter.logPrefix(endTime)
                            + "\((response as? HTTPURLResponse)?.statusCode ?? 0) RESPONSE -- "
                            + "\(endTime.timeIntervalSince1970-startTime.timeIntervalSince1970) "
                            + String(repeating: "-", count: 20))

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
        self.baseURL = URL(string: urLString.fixURL())
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
    func onError401WithCallback(_ on401ErrorWithCallback: @escaping ((URL?, @escaping (_ reload: Bool)->Void) -> Void)) -> Self {
        self.on401ErrorWithCallback = on401ErrorWithCallback
        return self
    }

    @discardableResult
    func onSignature(_ signature: @escaping ((URL?) -> [String : String])) -> Self {
        self.signature = signature
        return self
    }

    @discardableResult
    func setDefaultDecoder(_ decoder: JSONDecoder) -> Self {
        self.defaultDecoder = decoder
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

extension APIService: URLSessionTaskDelegate {

    public func urlSession(_ session: URLSession,
                           task: URLSessionTask,
                           didSendBodyData bytesSent: Int64,
                           totalBytesSent: Int64,
                           totalBytesExpectedToSend: Int64) {
        let progress = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
        let handler = self.progressHandlersByTaskID[task.taskIdentifier]
        handler?(progress)
    }

    public func urlSession(_ session: URLSession,
                           task: URLSessionTask,
                           didCompleteWithError error: Error?) {
        self.progressHandlersByTaskID[task.taskIdentifier] = nil
    }
}
