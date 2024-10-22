# frozen_string_literal: true

require "json"
require "yaml"
require "json-schema"
require_relative "../command"

module Dip
  module Commands
    class Validate < Dip::Command
      Error = Class.new(StandardError)
      ValidationError = Class.new(Error)
      UserError = Class.new(Error)

      def execute(output = $stdout)
        root_path = Pathname.new(__dir__).join("../../..")
        schema_path = root_path.join("schema.json")
        dip_yml_path = Pathname.pwd.join("dip.yml")

        unless schema_path.exist?
          raise UserError, "schema.json not found in the current directory"
        end

        unless dip_yml_path.exist?
          raise UserError, "dip.yml not found in the current directory"
        end

        schema = JSON.parse(schema_path.read)
        dip_config = YAML.safe_load(dip_yml_path.read)

        dip_config.fetch("$schema") do
          raise UserError, "dip.yml is missing the $schema key,\n$schema: https://github.com/bibendi/dip/blob/main/schema.json"
        end

        JSON::Validator.validate!(schema, dip_config)
      rescue JSON::Schema::ValidationError => e
        raise ValidationError, "Invalid dip.yml: #{e.message}"
      end
    end
  end
end
