Pod::Spec.new do |s|
  s.name = 'web3.swift'
  s.version = '0.0.1'
  s.license = 'MIT'
  s.summary = 'Ethereum API for Swift'
  s.homepage = 'https://github.com/argentlabs/web3.swift'
  s.authors = { 'Julien Niset' => 'julien@argent.im', 'Gerald Goldstein' => 'gerald@argent.im', 'Matt Marshall' => 'matt@argent.im' }
  s.source = { :git => 'https://github.com/argentlabs/web3.swift.git', :tag => s.version.to_s }

  s.requires_arc = true
  s.pod_target_xcconfig = {
      'SWIFT_VERSION' => '4.0'
  }

  s.ios.deployment_target = '9.0'

  s.source_files = 'web3swift/src/**/*.swift'

  s.dependency 'BigInt', '~> 3.0.1'
  end