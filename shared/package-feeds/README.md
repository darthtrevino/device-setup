# Package feeds

Every platform points its language package managers at the Microsoft scanned artifact proxy
(`packagefeedproxy.microsoft.io`). Each bootstrap installs these files into the per-user location
the tool reads:

| File | Tools | macOS / Linux | Windows |
| --- | --- | --- | --- |
| `npmrc` | npm, pnpm, corepack | `~/.npmrc` | `%USERPROFILE%\.npmrc` |
| `pip.conf` | pip | `~/.config/pip/pip.conf` | `%APPDATA%\pip\pip.ini` |
| `uv.toml` | uv, uvx | `~/.config/uv/uv.toml` | `%APPDATA%\uv\uv.toml` |
| `NuGet.Config` | dotnet, nuget, Visual Studio | `~/.nuget/NuGet/NuGet.Config` | `%APPDATA%\NuGet\NuGet.Config` |

`NuGet.Config` reuses the `nuget.org` key, so it replaces the default nuget.org source instead of
adding a second one alongside it.

Project-level config (a repo's own `.npmrc`, `nuget.config`, `uv.toml`/`pyproject.toml`) still wins
over these user-level files.

Verify on any machine:

```sh
npm config get registry
pip config list
uv pip install --dry-run --no-cache requests   # resolves through the proxy
dotnet nuget list source
```
