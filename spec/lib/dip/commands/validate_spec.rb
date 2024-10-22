# frozen_string_literal: true

require "shellwords"
require "dip/cli"
require "dip/commands/validate"

describe Dip::Commands::Validate do
  let(:cli) { Dip::CLI }

  around do |example|
    Dir.chdir(working_directory) do
      example.run
    end
  end

  context "when dip.yml is valid" do
    let(:working_directory) { fixture_path("valid") }

    it "outputs a success message" do
      expect { cli.start "validate".shellsplit }.to output(//).to_stdout
    end
  end

  context "when dip.yml is missing" do
    let(:working_directory) { fixture_path("missing") }

    it "raises a UserError" do
      expect { cli.start "validate".shellsplit }.to output("").to_stdout
    end
  end

  context "when dip.yml is invalid" do
    let(:working_directory) { fixture_path("invalid") }

    it "raises a ValidationError" do
      cli.start "validate".shellsplit
    end
  end

  fcontext "when schema.json is missing" do
    let(:working_directory) { fixture_path("no-schema") }

    it "raises a UserError" do
      expect(cli.start("validate".shellsplit)).to output(/schema/).to_stderr
    end
  end

  context "when dip.yml is missing the $schema key" do
    let(:missing_schema_dip_yml) { fixture_path("missing_schema", "dip.yml") }

    before do
      allow(Pathname).to receive(:pwd).and_return(Pathname.new(fixture_path("missing_schema")))
    end

    it "raises a UserError" do
      expect { cli.start "validate".shellsplit }.to raise_error(Dip::Commands::Validate::UserError, "dip.yml is missing the $schema key,\n$schema: https://github.com/bibendi/dip/blob/main/schema.json")
    end
  end
end

