# Meshy connection

The official `@meshy-ai/meshy-mcp-server` is pinned to 0.6.0 in this directory, with an npm lockfile. The global Codex MCP server is named `meshy`; its command launches `Start-Meshy.mjs` with the installed Node runtime. Existing Roblox Studio MCP and Rojo configurations are unchanged.

The API credential is encrypted with Windows user protection (DPAPI) at `%USERPROFILE%\.codex\secrets\meshy-api-key.dpapi`. It is not stored in game sources, Rojo configuration, npm files or Codex's MCP configuration. The internal `Read-Key.ps1` helper supplies the decrypted value through a private child-process pipe. Do not run that helper directly in a terminal. The launcher provides the key in memory to the official server, which authenticates against `https://api.meshy.ai` over HTTPS.

Restart Codex or restart its MCP connections to load the new tools into its tool catalog. The server launches on demand; no extra background HTTP service is needed.

From the project directory:

```powershell
# Check registered configuration; no secret is printed.
codex mcp get meshy
# Verify the MCP handshake, tool discovery and read-only account balance.
node tools/meshy/Verify-Connection.mjs
# Restore the pinned dependencies if needed.
Set-Location tools/meshy
npm ci --ignore-scripts
```

Verified on 7 October 2026: authenticated MCP initialization succeeded, 24 tools were discovered, and the balance check returned 1,150 credits. No generation job was requested or charged during setup.

For POOPING BIRDS assets, generate a preview, inspect the silhouette, refine approved geometry, then download GLB/FBX into a named asset folder. Review scale, triangles, UVs, materials, rigging and collision in Blender/Studio before importing. Asset generation uses Meshy credits; connecting the API does not itself authorize an arbitrary batch or purchases. Do not put the API key into any Roblox Script, LocalScript, ModuleScript, attribute or plugin source. Rojo continues to synchronize Luau; imported meshes require the Studio asset-import workflow.

Official references: [Meshy MCP](https://docs.meshy.ai/en/api/ai), [Meshy authentication](https://docs.meshy.ai/en/api/authentication), [Codex MCP configuration](https://learn.chatgpt.com/docs/extend/mcp?surface=cli).
