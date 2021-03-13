//
//  AppDelegate.swift
//  CoreAPIExample
//
//  Created by Sergey Chehuta on 13/03/2021.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var rootNC: UINavigationController?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.rootNC = UINavigationController(rootViewController: ViewController())
        self.window?.rootViewController = self.rootNC
        self.window?.makeKeyAndVisible()

        return true
    }

}

