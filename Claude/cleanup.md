# Link Build System

We are creating a "mini project build tool" which will allow a developer to build a 
workspace from a set of git-based folders. The tool can either build a "runtime" bound executable, or a development workspace. When the development workspace starts up, it re-creates selected Links to the source folders using the preloaded option to save time, but patches the workspace with any source files that have changed since the workspace was built.

# Phase 1:

1. Instead of environment variables, get all the build parameters except "RIDE" but adding all the variables set inside BuildExe from a JSON file called which is named in a single environment variable called BUILD_CONFIG
2. Also get the list of git folders from the config file, along with the target namespace name, whether the import should be flatten-ed, and whether it needs to be bidirectionally linked at runtime (code changes need to be recorded)
3. Special-case folder names "SQAPL" and "CONGA" - ⎕CY these at build time as the code currently does, rather than Link'ing them
4. Use ⎕WC to pop up the warning in Build

# Phase 2:

5. Update Patch to ask git for a list of files that have been deleted since the last build, and expunge any names corresponding to source files that have been deleted.


