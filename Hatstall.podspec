#
# Be sure to run `pod lib lint Hatstall.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Hatstall'
  s.version          = '0.0.1'
  s.summary          = 'Simple network layer'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = "Simple network layer" 

  s.homepage         = 'https://github.com/ambas/Hatstall'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'ambas' => 'ambaschobsanti@gmail.com' }
  s.source           = { :git => 'https://github.com/ambas/Hatstall.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'Hatstall/Classes/**/*'
  
  # s.resource_bundles = {
  #   'Hatstall' => ['Hatstall/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'ObjectMapper', '~> 2.2.8'
end
