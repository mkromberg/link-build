# link-build
Experimental Build system for Linked repositories

(More documentation to come)

## Configuration

Build parameters (previously individual environment variables) now live in a JSON
file, pointed to by the `BUILD_CONFIG` environment variable. See
[build-config.sample.json](build-config.sample.json) for a complete example, and
`ReadConfig.aplf` for how it's loaded. `DEV` and `RIDE` remain plain environment
variables, inspected directly by `Build`/`Patch`, since they describe how the
tool itself is invoked rather than what it builds.

### Top-level parameters

| Parameter                | Meaning |
|---------------------------|---------|
| `PRODUCT`                  | Product name, used in build banners and dialog titles. |
| `WS`                       | Name of workspace to save.  |
| `LX`                       | Latent expression. In a dev workspace it's appended after `Patch`; in a standalone exe it becomes `⎕LX` as-is. |
| `GITPATH`                  | Root folder containing the git repos named in `folders` (e.g. `c:\devt\`). Each folder's `path` is resolved relative to this. |

### `folders`

A list of the source folders to bring into the workspace, each built either by
linking to a git clone or (for `SQAPL`/`CONGA`) by `⎕CY`-ing a prebuilt workspace:

| Field      | Meaning |
|------------|---------|
| `name`     | Logical name of the folder. The literal names `SQAPL` and `CONGA` are special-cased: instead of being linked, they're copied at build time with `⎕CY` (`path` is then the workspace name to copy, e.g. `"sqapl"`). |
| `ns`       | Target namespace the folder's code is loaded into (`"#"` for the root, or a named namespace like `"A2K"`). |
| `path`     | Path to the git folder, relative to `GITPATH` (e.g. `"myapp/dyalog"`). For `SQAPL`/`CONGA` entries, the `⎕CY` workspace name instead. |
| `flatten`  | Whether the import/link should flatten the folder's structure into `ns` rather than preserving subfolders as sub-namespaces. |
| `link`     | Whether the folder is bidirectionally linked at runtime in a dev workspace (`⎕SE.Link.Create`, so edits made in the session are recorded back to the source files via `Patch`). When `false` (or when building a standalone exe), the folder is brought in with a one-way `⎕SE.Link.Import` instead. Ignored for `SQAPL`/`CONGA`. |

### `exe`

Parameters used only when building a standalone executable (`DEV` is off), passed
to `BuildExe`:

| Field        | Meaning |
|--------------|---------|
| `filename`   | Path of the exe to bind. |
| `type`       | Bind type, e.g. `"StandaloneNativeExe"`. |
| `flags`      | Bind flags bitmask (`8` = Runtime). |
| `resource`   | Optional resource file to bind in. |
| `icon`       | `.ico` file for the exe's icon. |
| `cmdline`    | Default command-line arguments embedded in the bound exe. |
| `buildfile`  | Path, relative to `GITPATH`, that the freshly bound exe is also copied to (e.g. an installer staging folder), if it already exists. |
| `details`    | Windows version-resource metadata: `Comments`, `CompanyName`, `FileDescription`, `LegalCopyright`, `ProductName`. `FileVersion`/`ProductVersion` are computed automatically at build time from the current month/year, and a timestamp is appended to `LegalCopyright` automatically - neither is set in the config file. |
