//
//  APIMultipart.swift
//  CoreAPI
//
//  Created by Sergey Chehuta on 12/03/2021.
//

import UIKit

public enum Multipart {
    case form(String, Any)
    case file(String, URL, String, String)   //name, URL, filename, Content-Type
    case data(String, Data, String, String)
    case image(String, UIImage, String)
}
