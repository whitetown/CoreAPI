Pod::Spec.new do |spec|

    spec.name         = "SwiftCoreAPI"
    spec.version      = "0.0.9"
    spec.summary      = "SwiftCoreAPI framework"

    spec.description  = <<-DESC
    Tiny network library for REST API.
    Pure Swift.
    No dependencies.
    DESC

    spec.homepage     = "https://github.com/whitetown/SwiftCoreAPI"
    spec.license      = { :type => "MIT", :file => "LICENSE" }
    spec.author       = { "WhiteTown" => "sensoneo@whitetown.com" }

    spec.ios.deployment_target = "12.1"
    spec.swift_version = "5.1"

    spec.source        = { :git => "https://github.com/whitetown/SwiftCoreAPI.git", :tag => "v0.0.9" }
    spec.source_files  = "Sources/**/*.swift"

end
