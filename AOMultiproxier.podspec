Pod::Spec.new do |s|
  s.name             = "AOMultiproxier"
  s.version          = "0.1.0"
  s.summary          = "A simple proxy class that multiplexes and dispatches protocol methods to multiple objects."
  s.description      = <<-DESC
                        How many times have you needed multiple delegates for a UIScrollView?
                        AOMultiproxier solves this problem by placing itself as a proxy between the owner object and
                        multiple delegates.
                       DESC
  s.homepage         = "https://github.com/alessandroorru/AOMultiproxier"
  s.license          = 'MIT'
  s.author           = { "Alessandro Orrù" => "alessandro.orr@gmail.com" }
  s.source           = { :git => "https://github.com/alessandroorru/AOMultiproxier.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/alessandroorru'

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes'
  s.resource_bundles = {
    'AOMultiproxier' => ['Pod/Assets/*.png']
  }
end
