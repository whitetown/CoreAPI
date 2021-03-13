//
//  SignedAPIService.swift
//  CoreAPI
//
//  Created by Sergey Chehuta on 13/03/2021.
//

import Foundation

open class SignedAPIService: APIService {

    private let queue = OperationQueue()

    public var signature:  ((URL?) -> [String : String])?
    public var on401Error: ((URL?) -> Void)?

    open override func prepareRequest(_ url: URL, _ resource: APIResource) -> URLRequest {
        return URLRequest(url: url,
                          resource: resource,
                          headers: self.headers,
                          signature: self.signature?(self.baseURL) ?? [:])
    }

    open override func load<T>(_ resource: APIResource,
                               parse: @escaping ((AnyObject, Data) -> T?),
                               completion: @escaping (Result<T, Error>) -> ()) {

        weak var welf = self
        let operation = BlockOperation {
            super.load(resource, parse: parse) { (result) in
                switch result {
                case .success(_):
                    DispatchQueue.main.async { completion(result) }
                case .failure(let error):
                    if (error as? APIError)?.apiCode == .unauthorised {
                        welf?.suspend()
                        welf?.reloadResource(resource, parse: parse, completion: completion)
                        welf?.on401Error?(welf?.baseURL)
                    } else {
                        DispatchQueue.main.async { completion(result) }
                    }
                }
            }
        }
        self.queue.addOperation(operation)
    }

    private func reloadResource<T>(_ resource: APIResource,
                                   parse: @escaping ((AnyObject, Data) -> T?),
                                   completion: @escaping (Result<T, Error>) -> ()) {
        load(resource, parse: parse, completion: completion)
    }

}

public extension SignedAPIService {

    @discardableResult
    func on(error401: @escaping ((URL?) -> Void)) -> Self {
        self.on401Error = error401
        return self
    }

    @discardableResult
    func on(signature: @escaping ((URL?) -> [String : String])) -> Self {
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
