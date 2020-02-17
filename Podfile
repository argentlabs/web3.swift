def all_pods
  pod 'BigInt', '5.0.0'
  pod 'secp256k1_ios', '~> 0.1'
end

target 'web3swift' do
  platform :ios, '11.2'
  use_frameworks!
  
  all_pods
  
  target 'web3swiftTests' do
    inherit! :search_paths

    all_pods
  end
end
