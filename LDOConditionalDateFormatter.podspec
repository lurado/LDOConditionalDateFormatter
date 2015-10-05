#
# Be sure to run `pod lib lint LDOConditionalDateFormatter.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "LDOConditionalDateFormatter"
  s.version          = "1.0.0"
  s.summary          = '"today 2 hours ago" and "yesterday at 4 PM" in one formatter'
  s.homepage         = "https://github.com/lurado/LDOConditionalDateFormatter"
  s.license          = 'MIT'
  s.author           = { "Julian Raschke und Sebastian Ludwig GbR" => "info@lurado.com" }
  s.source           = { :git => "https://github.com/lurado/LDOConditionalDateFormatter.git", :tag => s.version.to_s }

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'LDOConditionalDateFormatter' => ['Pod/Assets/*.lproj']
  }
end
