# frozen_string_literal: true

RSpec.describe Cocoapods::Swift::Packager do
  it "has a version number" do
    expect(Cocoapods::Swift::Packager::VERSION).not_to be nil
  end
end
