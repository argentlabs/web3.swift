Pod::Spec.new do |s|
  s.name = 'web3.swift'
  s.version = '1.6.0'
  s.license = 'MIT'
  s.summary = 'Ethereum API for Swift'
  s.homepage = 'https://github.com/argentlabs/web3.swift'
  s.authors = { 'Julien Niset' => 'julien@argent.xyz', 'Matt Marshall' => 'matt@argent.xyz', 'Miguel Angel Quiñones' => 'miguel@argent.xyz' }
  s.source = { :git => 'https://github.com/argentlabs/web3.swift.git', :tag => s.version.to_s }
  s.module_name = 'web3'

  s.swift_version = '5.5'
  s.ios.deployment_target = '13.0'

  s.source_files = 'web3swift/src/**/*.swift', 'web3swift/lib/**/*.{c,h,swift}'
  s.pod_target_xcconfig = {
    'SWIFT_INCLUDE_PATHS[sdk=iphonesimulator*]' => '$(inherited) $(PODS_TARGET_SRCROOT)/web3swift/lib/**',
    'SWIFT_INCLUDE_PATHS[sdk=iphoneos*]' => '$(inherited) $(PODS_TARGET_SRCROOT)/web3swift/lib/**'
  }
  s.preserve_paths = 'web3swift/lib/**/module.map'


  s.dependency 'BigInt', '~> 5.0.0'
  s.dependency 'secp256k1.swift', '~> 0.1'
  s.dependency 'GenericJSON', '~> 2.0'
  s.dependency 'Logging', '~> 1.0.0'

end
