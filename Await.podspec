Pod::Spec.new do |s|
  s.name     = 'Await'
  s.version  = '0.0.1'
  s.license  = { :type => 'MIT' }
  s.homepage = 'https://github.com/inamiy/Await'
  s.authors  = { 'Yasuhiro Inami' => 'inamiy@gmail.com' }
  s.summary  = 'Swift port of C# Await using Cocoa\'s Run Loop mechanism.'
  s.source   = { :git => 'https://github.com/inamiy/Await.git', :tag => "#{s.version}" }
  s.source_files = 'Await/*.{h,swift}'
  s.frameworks = 'Swift'
  s.requires_arc = true
end