#!/bin/bash

# 1. Install Project Dependencies
# Uses pnpm to respect the lockfile
echo "📦 Installing project dependencies..."
pnpm install

# 2. Install Tooling Dependencies
# Ensures the MCP SDK and TSX runner are available for the script
echo "➕ Installing @modelcontextprotocol/sdk and tsx..."
pnpm add -D @modelcontextprotocol/sdk tsx

# 3. Create 'scripts/ask-cloudflare.ts' (if missing)
# This guarantees the tool is available even if you haven't committed it yet.
if [ ! -f "scripts/ask-cloudflare.ts" ]; then
  echo "🛠️  Creating scripts/ask-cloudflare.ts..."
  mkdir -p scripts
  cat << 'EOF' > scripts/ask-cloudflare.ts
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";

async function askCloudflare() {
  const query = process.argv[2];
  if (!query) {
    console.error("\n❌ Usage: pnpm exec tsx scripts/ask-cloudflare.ts \"Query\"");
    process.exit(1);
  }

  console.log(`\n🔍 Asking Cloudflare Docs: "${query}"...`);

  const transport = new StdioClientTransport({
    command: "npx", 
    args: ["-y", "mcp-remote", "https://docs.mcp.cloudflare.com/mcp"],
  });

  const client = new Client(
    { name: "jules-client", version: "1.0.0" },
    { capabilities: {} }
  );

  try {
    await client.connect(transport);
    const tools = await client.listTools();
    const toolName = tools.tools.find(t => t.name === "ask" || t.name === "search")?.name;
    
    if (!toolName) throw new Error("No search tool found.");

    const result = await client.callTool({
      name: toolName,
      arguments: { question: query, query: query },
    });

    // @ts-ignore
    const answer = result.content.find(c => c.type === "text")?.text;
    console.log("\n--- Answer ---\n" + (answer || "No result") + "\n--------------\n");
  } catch (err) {
    console.error("Error:", err);
  } finally {
    process.exit(0);
  }
}

askCloudflare();
EOF
else
  echo "✅ scripts/ask-cloudflare.ts already exists."
fi

# 4. Validation
echo "✅ Environment Ready."
echo "👉 Try it: pnpm exec tsx scripts/ask-cloudflare.ts 'How do I use D1?'"
