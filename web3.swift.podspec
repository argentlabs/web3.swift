Pod::Spec.new do |s|
  s.name = 'web3.swift'
  s.version = '0.0.1'
  s.license = 'MIT'
  s.summary = 'Ethereum API for Swift'
  s.homepage = 'https://github.com/argentlabs/web3.swift'
  s.authors = { 'Julien Niset' => 'julien@argent.im', 'Matt Marshall' => 'matt@argent.im' }
  s.source = { :git => 'https://github.com/argentlabs/web3.swift.git', :tag => s.version.to_s }
  s.module_name = 'web3'

  s.swift_version = '4.0'
  s.ios.deployment_target = '9.0'

  s.source_files = 'web3swift/src/**/*.swift', 'web3swift/lib/**/*.{c,h}'
  s.pod_target_xcconfig = {'SWIFT_INCLUDE_PATHS' => '$(PODS_TARGET_SRCROOT)/web3swift/lib/**'}
  s.preserve_paths = 'web3swift/lib/**/module.map'

  s.dependency 'BigInt', '~> 3.0.1'

end
