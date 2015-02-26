Pod::Spec.new do |s|

  s.name = "FDModel"
  s.version = "1.2.1"
  s.summary = "Pain free model layer by 1414 Degrees."
  s.license = { :type => "MIT", :file => "LICENSE.md" }

  s.homepage = "https://github.com/reidmain/FDModel"
  s.author = "Reid Main"
  s.social_media_url = "http://twitter.com/reidmain"

  s.ios.deployment_target = "7.0"
  s.osx.deployment_target = "10.9"
  s.source = { :git => "https://github.com/reidmain/FDModel.git", :tag => s.version }
  s.source_files = "FDModel/**/*.{h,m}"
  s.framework  = "Foundation"
  s.requires_arc = true
  s.dependency "FDFoundationKit", "~> 1.2"
end
