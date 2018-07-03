Pod::Spec.new do |s|

  s.name         = "Photobook"
  s.version      = "1.0.0"
  s.summary      = "Summary here"
  s.description  = <<-DESC
Description here
                   DESC

  s.license      = "MIT"
  s.platform     = :ios, "9.0"
  s.authors      = { 'Konstantinos Karagiannis' => 'kkarayannis@gmail.com', 'Jaime Landazuri' => '', 'Julian Gruber' => '' }
  s.homepage     = 'https://www.kite.ly'
  s.source       = { :git => "https://github.com/OceanLabs/Photobook-iOS.git", :tag => "v" + s.version.to_s }
  s.source_files  = ["Photobook/**/*.swift", "PhotobookSDK/**/*.swift"]
  s.swift_version = "4.1"
  s.resource_bundles  = { 'PhotobookResources' => ['Photobook/Base.lproj/Main.storyboard', 'Photobook/Resources/Assets.xcassets', 'Photobook/Resources/Lora-Regular.ttf', 'Photobook/Resources/Montserrat-Bold.ttf', 'Photobook/Resources/OpenSans-Regular.ttf'] }
  s.module_name         = 'Photobook'
  s.dependency "KeychainSwift", "~> 11.0.0"
  s.dependency "SDWebImage", "~> 4.4.0"
  s.dependency "FBSDKCoreKit", "~> 4.33.0"
  s.dependency "FBSDKLoginKit", "~> 4.33.0"
  s.dependency "Stripe"
  s.dependency "Analytics", "~> 3.0"
  s.dependency "PayPal-iOS-Dynamic-Loader"

end