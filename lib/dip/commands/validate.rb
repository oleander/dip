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

        unless schema_path.exist?
          abort "Error: schema.json not found in the current directory"
        end

        unless dip_yml_path.exist?
          abort "Error: dip.yml not found in the current directory"
        end

        schema = JSON.parse(schema_path.read)
        dip_config = YAML.safe_load(dip_yml_path.read)

        JSON::Validator.validate!(schema, dip_config)
      rescue JSON::Schema::ValidationError => e
        abort "Validation error: #{e.message}"
      else
        puts "dip.yml is valid according to the schema"
      end
    end
  end
end
