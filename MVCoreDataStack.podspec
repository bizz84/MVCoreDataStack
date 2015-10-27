Pod::Spec.new do |s|
  s.name         = 'MVCoreDataStack'
  s.version      = '0.1.0'
  s.summary      = 'Sample demo app showing how to use parent-child managed object contexts for optimal performance'
  s.license      = 'MIT'
  s.homepage     = 'https://github.com/bizz84/MVCoreDataStack'
  s.author       = { 'Andrea Bizzotto' => 'bizz84@gmail.com' }
  s.ios.deployment_target = '8.0'

  s.source       = { :git => "https://github.com/bizz84/MVCoreDataStack.git", :tag => s.version }

  s.source_files = 'MVCoreDataStack/*.{swift}'

  s.screenshots  = []

  s.requires_arc = true
end
