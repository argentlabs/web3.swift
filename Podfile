def all_pods
  pod 'BigInt', '5.2.0'
  pod 'secp256k1.swift', '~> 0.1'
  pod 'GenericJSON', '~> 2.0'
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
