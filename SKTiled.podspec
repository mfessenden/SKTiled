Pod::Spec.new do |s|
  s.name                  = "SKTiled"
  s.version               = "1.12"
  s.summary               = "SKTiled is a lightweight framework for using Tiled files with Apple's SpriteKit."
  s.description           = <<-DESC
                            SKTiled is a simple framework for using Tiled files with Apple's SpriteKit, allowing the creation of game assets from .tmx files.
                            DESC
  s.author                = { "Michael Fessenden" => "michael.fessenden@gmail.com" }
  s.homepage              = "https://github.com/mfessenden/SKTiled"
  s.license               = { :type => 'MIT', :file => 'LICENSE.md' }
  #s.screenshot            = "https://raw.githubusercontent.com/mfessenden/SKTiled/gh-pages/images/header.png"

  s.ios.deployment_target = '9.0'
  s.osx.deployment_target = '10.11'
  s.source                = { :git => "https://github.com/mfessenden/SKTiled.git", :tag => s.version }

  # s.source_files = "Sources/*.{swift}", "zlib/*"
  s.source_files          = 'Sources/*.swift'
  s.requires_arc          = true
  s.library               = 'z'
  s.preserve_path         = 'zlib/*'
  s.pod_target_xcconfig   =  { 'SWIFT_INCLUDE_PATHS' => '$(PODS_ROOT)/SKTiled/zlib' }
end
