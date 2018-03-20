 def all_pods
  pod 'BigInt', '~> 3.0.1'
end

target 'web3swift' do
  platform :ios, '11.2'
  use_frameworks!
  
  all_pods
  
  target 'web3swiftTests' do
    inherit! :search_paths
  end
end
