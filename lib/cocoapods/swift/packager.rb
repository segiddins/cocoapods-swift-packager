# frozen_string_literal: true

require "set"
require "xcodeproj"

require_relative "packager/version"

module Cocoapods
  module Swift
    module Packager
      class Error < StandardError; end

      def self.integrate(generator, project, _pod_targets, results)
        return unless generator.config.podfile.plugins.key?("cocoapods-swift-packager")

        unless Gem::Version.create(Pod::VERSION) >= Gem::Version.create("1.11")
          raise Pod::Informative,
            "cocoapods-swift-packager requires a CocoaPods version >= 1.6.0"
        end

        plugin_config = generator.config.podfile.plugins["cocoapods-swift-packager"]

        target_to_swift_package = {}
        results.each do |pod_name, installation_result|
          # TODO: this is really a map to swift package targets, could lead to dupes
          target_to_swift_package[installation_result.native_target] =
            plugin_config.dig("pod_dependencies", pod_name) || []
        end
        swift_packages = target_to_swift_package.values.flatten(1).to_set
        swift_package_results = {}

        swift_packages.each do |product_name|
          packages = plugin_config["packages"].select { |p| p["products"].any? { _1["name"] == product_name } }
          if packages.size != 1
            raise Pod::Informative,
              "Couldnt find package for #{product_name} in #{plugin_config["packages"]}"
          end

          package = packages[0]

          package_ref = project.new(Xcodeproj::Project::XCRemoteSwiftPackageReference).tap do
            _1.repositoryURL = package["repositoryURL"]
            _1.requirement = package["requirement"]
          end
          project.root_object.package_references << package_ref

          package_product_dependency = project.new(Xcodeproj::Project::XCSwiftPackageProductDependency).tap do
            _1.package = package_ref
            _1.product_name = product_name
          end

          build_file = project.new(Xcodeproj::Project::PBXBuildFile).tap do
            _1.product_ref = package_product_dependency
          end

          swift_package_results[product_name] = build_file
        end

        target_to_swift_package.each do |native_target, swift_package_product_names|
          swift_package_product_names.each do |swift_package_product_name|
            build_file = swift_package_results.fetch(swift_package_product_name)

            native_target.frameworks_build_phases.files << build_file
            native_target.package_product_dependencies << build_file.product_ref

            native_target.build_configurations.each do |config|
              config.build_settings["SWIFT_INCLUDE_PATHS"] =
                ["$(inherited)", "$(BUILD_DIR)/$(CONFIGURATION)$(EFFECTIVE_PLATFORM_NAME)"]
            end
          end
        end
      end
    end
  end
end
