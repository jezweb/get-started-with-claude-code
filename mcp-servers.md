Before you start

Playwright has some dependencies to install

sudo apt-get update && sudo apt-get install -y libavif16

then

npm init playwright@latest



Install these MCP Servers

claude mcp add playwright -s user npx @playwright/mcp@latest 

claude mcp add --transport sse context7 -s user https://mcp.context7.com/sse

To do that you run claude

paste in 

claude mcp add playwright -s user npx @playwright/mcp@latest

hit enter

then paste in 

claude mcp add --transport sse context7 -s user https://mcp.context7.com/sse

hit enter

/exit

claude

that will make those available for all your claude sessions


for firecrawl

claude mcp add --transport sse firecrawl -s user https://mcp.firecrawl.dev/{FIRECRAWL_API_KEY}/sse


for Jina AI

claude mcp add jina-mcp-tools -s user npx jina-mcp-tools -e JINA_API_KEY=jina_api_key


unsplash
https://playbooks.com/mcp/okooo5km-unsplash#claude-code-setup

run this
npm install -g unsplash-mcp-server


claude mcp add unsplash -s user npx unsplash-mcp-server -e UNSPLASH_ACCESS_KEY=API-KEY-HERE
