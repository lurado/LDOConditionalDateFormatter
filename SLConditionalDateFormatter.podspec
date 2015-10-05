#
# Be sure to run `pod lib lint SLConditionalDateFormatter.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "SLConditionalDateFormatter"
  s.version          = "1.0.0.1"
  s.summary          = '"today 2 hours ago" and "yesterday at 4 PM" in one formatter'
  s.homepage         = "https://github.com/sebastianludwig/SLConditionalDateFormatter"
  s.license          = 'MIT'
  s.author           = { "Sebastian Ludwig" => "sebastian@lurado.de" }
  s.source           = { :git => "https://github.com/sebastianludwig/SLConditionalDateFormatter.git", :tag => s.version.to_s }

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.deprecated_in_favor_of = 'LDOConditionalDateFormatter'

  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'SLConditionalDateFormatter' => ['Pod/Assets/*.lproj']
  }
end
