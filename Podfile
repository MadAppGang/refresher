source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.4'
#inhibit_all_warnings!
use_frameworks!

target "PullToRefreshDemo" do
    pod 'Refresher', :path => '.'
    
    
    target "RefresherTests" do
        inherit! :search_paths
    end
    
    post_install do |installer|
        installer.pods_project.targets.each do |target|
            target.build_configurations.each do |configuration|
                configuration.build_settings['SWIFT_VERSION'] = "3.0"
            end
        end
    end
end
