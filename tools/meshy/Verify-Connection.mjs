import { Client } from '@modelcontextprotocol/sdk/client/index.js';
import { StdioClientTransport } from '@modelcontextprotocol/sdk/client/stdio.js';
import { fileURLToPath } from 'node:url';

const transport = new StdioClientTransport({
  command: 'C:\\Program Files\\nodejs\\node.exe',
  args: [fileURLToPath(new URL('./Start-Meshy.mjs', import.meta.url))],
  cwd: fileURLToPath(new URL('.', import.meta.url)),
  stderr: 'pipe',
});
let diagnostics = '';
transport.stderr?.on('data', chunk => { diagnostics += String(chunk); });
const client = new Client({ name: 'pooping-birds-meshy-check', version: '1.0.0' });
try {
  await client.connect(transport, { timeout: 60000 });
  const { tools } = await client.listTools();
  const result = await client.callTool({
    name: 'meshy_check_balance', arguments: { response_format: 'json' },
  });
  if (result.isError) throw new Error('Meshy balance verification failed.');
  const balance = result.structuredContent?.balance;
  if (!Number.isFinite(balance)) throw new Error('Unexpected balance response.');
  console.log(JSON.stringify({ connected: true, server: client.getServerVersion(),
    toolCount: tools.length, balance, generationRequested: false }, null, 2));
} catch (error) {
  console.error('Meshy MCP connection verification failed. Check configuration, credentials and network access.');
  const sanitized = `${error.message}\n${diagnostics}`
    .replace(/msy_[A-Za-z0-9_-]+/g, '[redacted]')
    .replace(/Bearer\s+\S+/gi, 'Bearer [redacted]');
  console.error(sanitized.slice(0, 2000));
  process.exitCode = 1;
} finally {
  await client.close();
  await transport.close();
}
