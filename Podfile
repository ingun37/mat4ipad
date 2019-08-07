# Uncomment the next line to define a global platform for your project
platform :ios, '12.4'

source 'git@github.com:ingun37/my-spec.git'
source 'https://github.com/CocoaPods/Specs.git'
target 'mat4ipad' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for mat4ipad
  pod 'iosMath', :git => 'https://github.com/kostub/iosMath', :commit => 'e9b6ec66911089ca0673dd0034715652e71420c9'
  pod 'RxSwift', '~> 5'
  pod 'RxCocoa', '~> 5'
  pod 'PromisesSwift'
  pod 'TensorFlowLiteSwift'
  pod 'SignedNumberRecognizer'
  pod 'AlgebraEvaluator', '~> 0.1.3'
  pod 'numbers'
  target 'mat4ipadTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'mat4ipadUITests' do
    inherit! :search_paths
    # Pods for testing
  end

end
