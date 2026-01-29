# frozen_string_literal: true

require "spec_helper"
require "dip/mcp_server"

describe Dip::MCPServer do
  describe "#initialize" do
    context "when dip.yml exists" do
      around do |ex|
        orig = ENV["DIP_FILE"]
        ENV["DIP_FILE"] = fixture_path("cascade", "dip.yml")
        ex.run
        ENV["DIP_FILE"] = orig
        Dip.reset!
      end

      it "creates a server with tools from dip.yml" do
        server = described_class.new
        expect(server.instance_variable_get(:@server)).to be_a(MCP::Server)
      end

      it "registers tools for each interaction command" do
        server = described_class.new
        mcp_server = server.instance_variable_get(:@server)
        tools = mcp_server.tools
        
        expect(tools.length).to be > 0
        # Tools are stored as a hash with tool name as key and tool class as value
        tool_class = tools.values.first
        expect(tool_class).to respond_to(:call)
      end
    end

    context "when dip.yml does not exist" do
      around do |ex|
        orig = ENV["DIP_FILE"]
        ENV["DIP_FILE"] = "/nonexistent/dip.yml"
        ex.run
        ENV["DIP_FILE"] = orig
        Dip.reset!
      end

      it "creates a server with no tools" do
        expect { described_class.new }.to output(/Warning: No dip.yml found/).to_stderr
      end
    end
  end
end
