import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

try {
  const secretBuffer = execFileSync(
    'C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe',
    ['-NoLogo', '-NoProfile', '-NonInteractive', '-File',
      fileURLToPath(new URL('./Read-Key.ps1', import.meta.url))],
    { windowsHide: true, timeout: 15000, stdio: ['ignore', 'pipe', 'pipe'] },
  );
  const key = secretBuffer.toString('utf8').trim();
  secretBuffer.fill(0);
  if (!key.startsWith('msy_')) throw new Error('Invalid credential format.');
  process.env.MESHY_API_KEY = key;
  process.env.MESHY_API_HOST = 'https://api.meshy.ai';
  process.env.TRANSPORT = 'stdio';
  process.chdir(fileURLToPath(new URL('../../', import.meta.url)));
  // Keep the MCP transport in this Node process; PowerShell only decrypts the key.
  await import('./node_modules/@meshy-ai/meshy-mcp-server/dist/index.js');
} catch {
  // Never print a child-process error object or captured credential output.
  console.error('Meshy startup failed. Check the encrypted credential and installed dependencies.');
  process.exitCode = 1;
}
