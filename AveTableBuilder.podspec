Pod::Spec.new do |s|
    s.name             = 'AveTableBuilder'
    s.version          = '1.0.0'
    s.summary          = 'Create UIKit TableViews in a declarative, SwiftUI-like way'
    s.homepage         = 'https://github.com/AndreasVerhoeven/AveTableBuilder'
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.author           = { 'Andreas Verhoeven' => 'cocoapods@aveapps.com' }
    s.source           = { :git => 'https://github.com/AndreasVerhoeven/AveTableBuilder.git', :tag => s.version.to_s }
    s.module_name      = 'AveTableBuilder'

    s.swift_versions = ['5.7']
    s.ios.deployment_target = '13.0'
    s.source_files = 'Sources/*/*.swift'
    
    s.dependency 'AutoLayoutConvenience'
    s.dependency 'AveDataSource'
    s.dependency 'UIKitAnimations'
    s.dependency 'AveFontHelpers'
end
