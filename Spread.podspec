Pod::Spec.new do |s|

  s.name         = "Spread"
  s.version      = "1.2.0"
  s.summary      = "Spread is a data flow control, inspire from: When the shit hit the fan, it will be spread all over."
  s.homepage     = "http://facebook.com/huyphams"
  s.license      = "MIT"
  s.author             = { "Huy Pham" => "duchuykun@gmail.com" }
  s.social_media_url   = "https://www.instagram.com/huyphams"
  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/huyphams/Spread.git", :tag => "#{s.version}" }
  s.source_files  = "Classes/*.{h,m}"
  s.requires_arc = true

end
