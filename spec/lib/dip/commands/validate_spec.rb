# frozen_string_literal: true

require "shellwords"
require "dip/cli"
require "dip/commands/validate"

describe Dip::Commands::Validate do
  let(:cli) { Dip::CLI }
  let(:result) { cli.start "validate".shellsplit }

  around do |example|
    Dir.chdir(working_directory) do
      example.run
    end
  end

  context "when dip.yml is valid" do
    let(:working_directory) { fixture_path("valid") }

    it "outputs a success message" do
      expect { result }.to output(//).to_stdout
    end
  end

  context "when dip.yml is missing" do
    let(:working_directory) { fixture_path("missing") }

    it "outputs a warning message" do
      expect { result }.to output(/missing/i).to_stderr
    end
  end

  context "when dip.yml is invalid" do
    let(:working_directory) { fixture_path("invalid-with-schema") }

    it "outputs an error message" do
      expect { result }.to output(/invalid/i).to_stderr
    end
  end

  context "when schema.json is missing" do
    let(:working_directory) { fixture_path("no-schema") }

    it "outputs a warning message" do
      expect { result }.to output(/schema/i).to_stderr
    end
  end
end

