Pod::Spec.new do |s|
  s.name                   = "SKTiled"
  s.version                = "1.23"
  s.summary                = "SKTiled is a framework for using Tiled content with Apple's SpriteKit."
  s.description            = <<-DESC
                            SKTiled is a framework for using Tiled content with Apple's SpriteKit, allowing the creation of game assets from Tiled .tmx files.
                            DESC
  s.author                 = { "Michael Fessenden" => "michael.fessenden@gmail.com" }
  s.homepage               = "https://github.com/mfessenden/SKTiled"
  s.license                = { :type => 'MIT', :file => 'LICENSE.md' }

  s.osx.deployment_target  = '11.0'
  s.ios.deployment_target  = '12.0'
  s.tvos.deployment_target = '12.0'
  s.source                 = { :git => "https://github.com/mfessenden/SKTiled.git", :tag => s.version }

  s.source_files           = 'Sources/*.swift'
  s.requires_arc           = true

  s.swift_versions         = [5, 5.2, 5.3, 5.4, 5.5]

end
