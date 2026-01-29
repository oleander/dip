# MCP Server Configuration Examples

This directory contains example configurations for using the dip MCP server with various MCP clients.

## Claude Desktop Configuration

To use the dip MCP server with Claude Desktop, add the configuration from `claude_desktop_config.json` to your Claude Desktop configuration file:

- **macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
- **Windows**: `%APPDATA%\Claude\claude_desktop_config.json`

Make sure to:
1. Replace `/path/to/your/project` with the absolute path to your project directory
2. Ensure `dip-mcp-server` is in your PATH (install dip gem globally or provide full path)
3. Restart Claude Desktop after updating the configuration

## Example Usage

Once configured, you can ask Claude to:

- "Run the rspec tests" - Will execute your test suite
- "Start the rails server" - Will start your Rails application
- "Run bundle install" - Will install dependencies
- "Execute the provision command" - Will run your provisioning steps

Claude will have access to all commands defined in your `dip.yml` interaction section.

## Verifying Installation

Test that the MCP server is working correctly:

```bash
# Test initialization
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0.0"}}}' | dip-mcp-server

# List available tools
echo '{"jsonrpc":"2.0","id":2,"method":"tools/list"}' | dip-mcp-server
```

If successful, you should see JSON-RPC responses with your available tools.
