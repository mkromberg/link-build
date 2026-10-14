# link-build
Experimental Build system for Linked repositories

link-build builds a Dyalog workspace from a set of git-based source folders. It can
produce either:

* a **development workspace** (`DEV=Y`), saved as `WS`, in which selected folders are
  re-`Link`ed on startup (using the preloaded option, so startup is fast) and any
  source files changed since the workspace was built are patched in; or
* a **stand-alone executable** (`DEV` not set), bound from the same sources.

## Setting up a project

link-build lives in its own folder; each project that uses it needs a small
"build folder" of its own. See `Tests/stats` in this repository for a working example.
A build folder contains:

| File               | Purpose |
|--------------------|---------|
| `linkbuild.json`   | The build configuration (see [Configuration](#configuration)). |
| `linkbuildboot.aplf` | Boot script that links link-build's `APLSource` as namespace `linkbuild` and calls `linkbuild.Build`. Copy it from this repository and change the path to where you cloned link-build. |
| `build.bat`        | Builds the stand-alone executable. |
| `builddev.bat`     | Builds the development workspace (`DEV=Y`). |
| `dev.bat`          | Starts the saved development workspace (`DEV=Y`); `Run` patches and re-links it. |
| `<icon>.ico`       | Icon for the exe (optional; referenced by `exe.icon`, relative to the build folder). |

### Steps

1. Create a build folder, e.g. `c:\devt\myapp\linkbuild`.
2. Copy `linkbuild.sample.json` there as `linkbuild.json` and edit it: product name,
   `GITPATH`, `WS`, `LX`, the list of `folders` and the `exe` section.
3. Create `linkbuildboot.aplf` in the build folder. It must link the link-build source
   and run the build, e.g. (with an absolute path to your link-build clone):

   ```apl
    linkbuildboot
    ⎕SE.Link.Create 'linkbuild' 'c:\devt\link-build\APLSource'
    linkbuild.Build
    ⎕EX 'linkbuildboot'
   ```
4. Create the batch files. Run them from the build folder (they use the current
   directory to find `linkbuild.json` and `linkbuildboot.aplf`):

   `build.bat` - stand-alone exe:
   ```bat
   dyalog.exe LOAD="linkbuildboot.aplf"
   ```
   `builddev.bat` - development workspace, entering the application when done:
   ```bat
   dyalog.exe LOAD="linkbuildboot.aplf" "DEV=Y"
   ```
   `dev.bat` - restart the saved workspace later without rebuilding (it patches itself
   in `Run`, which is its `⎕LX`):
   ```bat
   dyalog.exe DEV=Y LOAD=C:\tmp\myapp.dws
   ```
5. Run `builddev.bat` (or `build.bat`). Add `pull` as a command-line argument to
   `git pull` every source folder before loading it.

If you keep the batch files somewhere other than the build folder, set `BUILD_CONFIG`
(see below) to tell link-build where `linkbuild.json` is. `Tests/stats/build.bat` does
this, running from the link-build root against `Tests\stats`. The `build.bat` in the
link-build root does the same for any config folder: `build Tests\stats DEV=Y`.

Before saving or binding, the build checks each source repo with git and asks for
confirmation (via a `⎕WC` dialog) if any is not on `main` or has uncommitted changes.
If the `RIDE` environment variable is set, RIDE is enabled in the built application
and a warning is shown.

## Configuration

Build parameters are set in a
file named `linkbuild.json`. It is looked for in the folder given by the
`BUILD_CONFIG` environment variable (if the value names a file, its folder is used),
or in the current directory if `BUILD_CONFIG` is not set. See
[linkbuild.sample.json](linkbuild.sample.json) for a complete example, and
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
| `delete`                   | Optional, default `1`. When on, starting a development workspace also removes names whose source files have been deleted since the build - see [Deleted files](#deleted-files). Set to `0` to disable. |

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
| `runtime`    | `1` to bind a runtime exe (flag `8`), `0` for a development (non-runtime) exe. |
| `resource`   | Optional resource file to bind in. |
| `cmdline`    | Default command-line arguments embedded in the bound exe. |
| `icon`       | `.ico` file, relative to the folder containing `linkbuild.json`. |
| `buildcopy`  | Path, relative to `GITPATH`, that the freshly bound exe is also copied to (e.g. an installer staging folder), if it already exists. |
| `details`    | Windows version-resource metadata: `Comments`, `CompanyName`, `FileDescription`, `LegalCopyright`, `ProductName`. `FileVersion`/`ProductVersion` are computed automatically at build time from the current month/year, and a timestamp is appended to `LegalCopyright` automatically - neither is set in the config file. |

## Modified and Deleted files

A development workspace is saved at build time, and acts as a cache. The function `linkbuild.Run` (its `⎕LX`) patches it on
every start by re-fixing source files modified since the save. Files that were
*deleted* in the meantime would otherwise live on in the saved workspace.

When `delete` is on (the default), `Run` asks git, for each linked repo, which files
have been deleted from the working tree since the commit the workspace was built from
(`GitDeleted`, using `git diff --diff-filter=D`). For each deleted `.dyalog` or `.apl*`
file, the corresponding name is expunged from the target namespace (subfolders map to
sub-namespaces unless `flatten` is set), and `Expunged <ns>.<name>` is reported.

Notes:

* Only deletions relative to the build-time commit are detected; the repo must
  still exist at the path used for the build.
* Deletions are not applied if git cannot be run for a folder (a warning is printed).
* Set `"delete": 0` in `linkbuild.json` to skip this step.
