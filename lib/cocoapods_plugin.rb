# frozen_string_literal: true

Pod::Installer::Xcode::PodsProjectGenerator
  .prepend(Module.new do
             def install_pod_targets(project, pod_targets)
               require 'cocoapods/swift/packager'
               super.tap do |results|
                 Cocoapods::Swift::Packager.integrate(self, project, pod_targets, results)
               end
             end
           end)
