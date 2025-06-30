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
