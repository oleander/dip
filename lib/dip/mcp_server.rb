# frozen_string_literal: true

require "mcp"
require "dip/interaction_tree"
require "shellwords"
require "stringio"

module Dip
  class MCPServer
    class << self
      def start
        new.start
      end
    end

    def initialize
      # Get all interaction commands from dip.yml
      tools = []

      if Dip.config.exist?
        interaction_tree = InteractionTree.new(Dip.config.interaction)
        commands = interaction_tree.list

        # Create tool classes for each command
        tools = commands.map { |name, command| create_tool_class(name, command) }
      else
        warn "Warning: No dip.yml found. Server will start with no tools."
      end

      @server = MCP::Server.new(
        name: "dip-server",
        version: Dip::VERSION,
        instructions: "Docker Interaction Process (dip) server. Provides tools for running Docker Compose and kubectl commands defined in dip.yml configuration.",
        tools: tools
      )
    end

    def start
      # Use stdio transport for MCP communication
      transport = MCP::Server::Transports::StdioTransport.new(@server)
      transport.open
    end

    private

    def create_tool_class(name, command)
      # Create a dynamic tool class for this command
      Class.new(MCP::Tool) do
        @command_name = name
        @command_config = command

        # Set the tool name using the class-level method
        tool_name @command_name.gsub(" ", "_")
        description(@command_config[:description] || "Run #{@command_name} command")

        input_schema(
          properties: {
            args: {
              type: "string",
              description: "Additional arguments to pass to the command"
            },
            env: {
              type: "object",
              description: "Environment variables to set for the command"
            }
          }
        )

        class << self
          attr_reader :command_name, :command_config

          def call(args: "", env: {}, server_context: {})
            require_relative "commands/run"

            # Parse the command and arguments
            cmd_parts = @command_name.split
            cmd = cmd_parts.first
            subcmd_args = cmd_parts[1..] || []

            # Combine with provided args
            all_args = subcmd_args.dup
            all_args += args.shellsplit if args && !args.empty?

            # Merge environment variables into Dip environment
            Dip.env.merge(env) if env && !env.empty?

            # Execute the command and capture output
            begin
              run_command = Dip::Commands::Run.new(cmd, *all_args)

              # Capture output
              output = capture_output do
                run_command.execute
              end

              MCP::Tool::Response.new([{
                type: "text",
                text: output
              }])
            rescue Dip::Error => e
              MCP::Tool::Response.new([{
                type: "text",
                text: "Error: #{e.message}"
              }])
            rescue => e
              MCP::Tool::Response.new([{
                type: "text",
                text: "Unexpected error: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
              }])
            end
          end

          private

          def capture_output
            original_stdout = $stdout
            original_stderr = $stderr

            $stdout = StringIO.new
            $stderr = StringIO.new

            yield

            stdout_output = $stdout.string
            stderr_output = $stderr.string

            output = ""
            output += stdout_output unless stdout_output.empty?
            output += "\nSTDERR:\n#{stderr_output}" unless stderr_output.empty?
            output = "Command executed successfully (no output)" if output.empty?

            output
          ensure
            $stdout = original_stdout
            $stderr = original_stderr
          end
        end
      end
    end
  end
end
