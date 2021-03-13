Pod::Spec.new do |spec|

    spec.name         = "CoreAPI"
    spec.version      = "0.0.1"
    spec.summary      = "CoreAPI framework"

    spec.description  = <<-DESC
    CoreAPI
                    DESC

    spec.homepage     = "https://github.com/whitetown/CoreAPI"
    spec.license      = { :type => "MIT", :file => "LICENSE" }
    spec.author       = { "WhiteTown" => "sensoneo@whitetown.com" }

    spec.ios.deployment_target = "12.1"
    spec.swift_version = "5.1"

    spec.source        = { :git => "https://github.com/whitetown/CoreAPI.git", :tag => "#{spec.version}" }
    spec.source_files  = "Sources/**/*.{h,m,swift}"

end
