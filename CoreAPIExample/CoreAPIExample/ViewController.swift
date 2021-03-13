//
//  ViewController.swift
//  CoreAPIExample
//
//  Created by Sergey Chehuta on 13/03/2021.
//

import UIKit
import CoreAPI

class ViewController: UIViewController {

    let titles = ["GET", "POST", "PATCH", "PUT", "DELETE"]

    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            self.view.backgroundColor = UIColor.systemBackground
        } else {
            self.view.backgroundColor = UIColor.white
        }
        makeButtons()
    }

}

private extension ViewController {

    func makeButton(_ title: String) -> UIButton {
        let result = UIButton()
        result.setTitle(title, for: .normal)
        result.backgroundColor = .systemGray
        result.setTitleColor(.white, for: .normal)
        result.addTarget(self, action: #selector(btnTap), for: .touchUpInside)
        return result
    }

    func makeButtons() {

        var frame = self.view.bounds.insetBy(dx: 20, dy: 120)
        frame.size.height = 44
        let stack = UIStackView(frame: frame)
        stack.autoresizingMask = [.flexibleWidth]
        stack.axis = .horizontal
        stack.spacing = 10
        stack.distribution = .fillEqually
        self.view.addSubview(stack)


        let buttons = titles.map { makeButton($0) }
        buttons.forEach { stack.addArrangedSubview($0) }
    }

    @objc func btnTap(_ sender: UIButton) {
        guard let index = self.titles.firstIndex(of: sender.title(for: .normal) ?? "") else { return }

        switch index {
        case 0:
            get1()
            get2()
            get3()
        case 1:
            post()
        default:
            break
        }
    }

    func get1() {
        let resource = APIResource(path: "https://api.mocki.io/v1/ce5f60e2")

        let api = OpenAPIService()
        api.load(resource) { (json, data) -> NSDictionary? in

            //print(json)
            return json as? NSDictionary

        } completion: { (result) in

            print(result)
        }
    }

    func get2() {
        let resource = APIResource(path: "ce5f60e2")

        let api = OpenAPIService().base("https://api.mocki.io/v1/")
        api.load(resource) { (json, data) -> User? in

            //print(json)
            return try? JSONDecoder().decode(User.self, from: data)

        } completion: { (result) in

            print(result)
        }
    }

    func get3() {
        let resource = APIResource(path: "b043df5a")
            //.header(value: "Test", for: "X-Test")
            //.query(["key": "value"])

        let api = OpenAPIService()
            .base("https://api.mocki.io/v1/")
            .on(log: { (value) in
                print(value)
            })

        api.load(resource) { (json, data) -> [User] in

            //print(json)
            return (try? JSONDecoder().decode([User].self, from: data)) ?? []

        } completion: { (result) in

            print(result)
        }
    }

    func post() {

        let resource = APIResource(path: "ce5f60e2").post()

        let api = SignedAPIService()
            .base("https://api.mocki.io/v1/")
            .on(log: { (value) in
                print(value)
            })
            .on(error401: { (url) in
                print(url)
            })
            .on(signature: { (url) -> [String : String] in
                return ["Authorization": "Bearer 1234567890"]
            })

        api.load(resource) { (json, data) -> Bool in

            return true

        } completion: { (result) in

            print(result)
        }
    }

}

struct User: Codable {
    let name: String
    let city: String
}
