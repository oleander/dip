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
        # Convert to valid tool name by replacing non-alphanumeric characters with underscores
        tool_name @command_name.gsub(/[^a-zA-Z0-9_]/, "_")
        description(@command_config[:description] || "Run #{@command_name} command")

        input_schema(
          properties: {
            args: {
              type: "string",
              description: "Additional command-line arguments as a single string (will be shell-parsed)"
            },
            env: {
              type: "object",
              description: "Environment variables to set for the command (key-value pairs where values are strings)",
              additionalProperties: {type: "string"}
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

            # Save current environment state
            original_env_vars = Dip.env.vars.dup

            # Merge environment variables for this execution
            temp_env = original_env_vars.dup
            env.each { |k, v| temp_env[k.to_s] = v.to_s } if env && !env.empty?

            # Execute the command in a subprocess and capture output
            begin
              run_command = Dip::Commands::Run.new(cmd, *all_args)

              # Get the command configuration
              command = run_command.instance_variable_get(:@command)

              # Build the full command line
              cmdline = build_cmdline(command, all_args)

              # Execute in subprocess and capture output
              output = execute_subprocess(cmdline, temp_env, command[:shell])

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
            ensure
              # Restore original environment to prevent pollution between calls
              Dip.env.instance_variable_set(:@vars, original_env_vars)
            end
          end

          private

          def build_cmdline(command, argv)
            cmd = Dip.env.interpolate(command[:command])
            argv = [argv] if argv.is_a?(String)
            argv = argv.map { |arg| Dip.env.interpolate(arg) }
            cmdline = [cmd, *argv, command[:default_args]].compact
            if command[:shell]
              cmdline.join(" ").strip
            else
              cmdline
            end
          end

          def execute_subprocess(cmdline, env_vars, shell)
            # Create pipes for capturing stdout and stderr
            stdout_r, stdout_w = IO.pipe
            stderr_r, stderr_w = IO.pipe

            pid = Process.spawn(
              env_vars,
              cmdline,
              out: stdout_w,
              err: stderr_w
            )

            # Close write ends in parent process
            stdout_w.close
            stderr_w.close

            # Read output
            stdout_output = stdout_r.read
            stderr_output = stderr_r.read

            # Wait for process to complete
            Process.wait(pid)
            status = $?

            # Close read ends
            stdout_r.close
            stderr_r.close

            # Build output
            output = ""
            output += stdout_output unless stdout_output.empty?
            output += "\nSTDERR:\n#{stderr_output}" unless stderr_output.empty?

            if status.success?
              output = "Command executed successfully (no output)" if output.empty?
            else
              output += "\nCommand exited with status #{status.exitstatus}" unless output.include?("exited with status")
            end

            output
          end
        end
      end
    end
  end
end
