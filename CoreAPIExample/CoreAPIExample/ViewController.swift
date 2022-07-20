//
//  ViewController.swift
//  CoreAPIExample
//
//  Created by Sergey Chehuta on 13/03/2021.
//

import UIKit
import SwiftCoreAPI

class ViewController: UIViewController {

    let titles = ["Simple GET", "Get user", "Get Users", "Simple POST", "Subclass1", "Subclass2"]
    let customAPI = MyAPIService()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        makeButtons()
    }

}

private extension ViewController {

    func makeButton(_ title: String) -> UIButton {
        let result = UIButton()
        result.setTitle(title, for: .normal)
        result.backgroundColor = .blue
        result.setTitleColor(.white, for: .normal)
        result.addTarget(self, action: #selector(btnTap), for: .touchUpInside)
        return result
    }

    func makeButtons() {

        var frame = self.view.bounds.insetBy(dx: 40, dy: 120)
        frame.size.height = 5*44+4*10
        let stack = UIStackView(frame: frame)
        stack.autoresizingMask = [.flexibleWidth]
        stack.axis = .vertical
        stack.spacing = 10
        stack.distribution = .fillEqually
        self.view.addSubview(stack)

        titles.forEach { stack.addArrangedSubview(makeButton($0)) }
    }

    @objc func btnTap(_ sender: UIButton) {
        guard let index = self.titles.firstIndex(of: sender.title(for: .normal) ?? "") else { return }

        switch index {
        case 0:
            simpleGet()
        case 1:
            getUser()
        case 2:
            getUsers()
        case 3:
            post()
        case 4:
            customPost()
        case 5:
            anotherExample()
        default:
            break
        }
    }

    func simpleGet() {
        let resource = APIResource(path: "simple-get")

        let api = APIService().base("https://coreapi.free.beeceptor.com/")
        api.load(resource) { (json, data) -> NSDictionary? in
            return json as? NSDictionary
        } completion: { (result) in
            print(result)
        }
    }

    func getUser() {
        let resource = APIResource(path: "user")
        let api = APIService().base("https://coreapi.free.beeceptor.com/")
        api.load(resource, User.self) { (result) in
            print(result)
        }
    }

    func getUsers() {
        let resource = APIResource(path: "users").query(["key":"value"])
        let api = APIService().base("https://coreapi.free.beeceptor.com/")
        api.load(resource, [User].self) { (result) in
            print(result)
        }
    }

    func post() {

        let value = Array(1...100000).map({ "line \($0)" }).joined(separator: "\n")

        let resource = APIResource(path: "users").post().body(["key": value])
        let api = APIService().base("https://coreapi.free.beeceptor.com/")
        api.load(resource) { (json, data) -> Bool in
            return true
        } progress: { value in
            print(value)
        } completion: { (result) in
            print(result)
        }
    }

    func customPost() {
        self.customAPI.makePost { (result) in
            print(result)
        }
    }

    func anotherExample() {
        self.customAPI.anotherExample { (result) in
            print(result)
        }
    }
}

struct User: Codable {
    let id: Int
    let name: String
}

class MyAPIService: APIService {

    override init() {
        super.init()
        initialize()
    }

    func initialize() {
        self
            .base("https://coreapi.free.beeceptor.com/")
            .headers(values: ["api-key": "some-value"])
            .onLog { (value) in
                print(value)
            }
    }

    func makePost(completion: @escaping (Result<NSDictionary,Error>)->Void) {

        let resource = POST(path: "custom").body(["key":"value"])

        self.load(resource) { (json, data) -> NSDictionary? in
            return json as? NSDictionary
        } progress: { value in
            print(value)
        } completion: { (result) in
            completion(result)
        }
    }

    func anotherExample(completion: @escaping (Result<Status,Error>)->Void) {

        let payload = User(id: 5, name: "Test")
        let resource = POST(path: "custom").payload(payload)

        self.load(resource, Status.self) { (result) in
            completion(result)
        }
    }

}

struct Status: Codable {
    let status: String
}


