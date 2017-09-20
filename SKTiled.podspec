Pod::Spec.new do |s|
  s.name                  = "SKTiled"
  s.version               = "1.16"
  s.summary               = "SKTiled is a framework for using Tiled content with Apple's SpriteKit."
  s.description           = <<-DESC
                            SKTiled is a framework for using Tiled content with Apple's SpriteKit, allowing the creation of game assets from .tmx files.
                            DESC
  s.author                = { "Michael Fessenden" => "michael.fessenden@gmail.com" }
  s.homepage              = "https://github.com/mfessenden/SKTiled"
  s.license               = { :type => 'MIT', :file => 'LICENSE.md' }

  s.ios.deployment_target = '9.0'
  s.osx.deployment_target = '10.12'
  s.source                = { :git => "https://github.com/mfessenden/SKTiled.git", :tag => s.version }

  s.source_files          = 'Sources/*.swift'
  s.requires_arc          = true
  s.library               = 'z'
end
