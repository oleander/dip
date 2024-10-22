# frozen_string_literal: true

require "json"
require "yaml"
require "json-schema"
require_relative "../command"

module Dip
  module Commands
    class Validate < Dip::Command
      def execute
        root_path = Pathname.new(__dir__).join("..", "..", "..")
        schema_path = root_path.join("schema.json")
        dip_yml_path = root_path.join("dip.yml")

        unless File.exist?(schema_path)
          puts "Error: schema.json not found in the current directory."
          exit 1
        end

        unless File.exist?(dip_yml_path)
          puts "Error: dip.yml not found in the current directory."
          exit 1
        end

        schema = JSON.parse(File.read(schema_path))
        dip_config = YAML.safe_load(File.read(dip_yml_path))

        begin
          JSON::Validator.validate!(schema, dip_config)
          puts "dip.yml is valid according to the schema."
        rescue JSON::Schema::ValidationError => e
          puts "Validation error: #{e.message}"
          exit 1
        end
      end
    end
  end
end
