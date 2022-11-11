# Shellkit Loader

## Goals

- Every kit installs the loader if it's missing or old
- The shellkit-loader.bashrc is the only thing that must be registered in the static shell init files
- Kits can declare dependencies and the loader will
    - topo-sort during init
    - shout if a cycle is found
    - shout if a dependency is not installed
    - ensure that each kit is loaded exactly once per init cycle

## Design

- shellkit-loader.bashrc:
    - Installer hooks this into the static shell init
    - This lives in ~/.local/bin, there can only be one per environment
    - This is installed as a plain file, not a symlink
    - This declares SHELLKIT_LOADER_VER as a simple int
    - The installer never overwrites a newer version of this
    - This strives to be light (inject minimal definitions into environment)
    - Defines a SHELLKIT_LOAD_DISABLE flag which turns off running the load process if defined

- shellkit_loader() function:
    - This is defined in shellkit-loader.bashrc
    - This defers most heavy lifting to ~/.local/bin/shellkit-loader.sh
    - This sources the list of kit loaders printed by shellkit-loader.sh

- shellkit-loader.sh:
    - This lives in ~/.local/bin, may be a symlink or plain file
    - This prints a version number (int) when called with --version
    - The installer never overwrites a newer version of this
    - This does a scan of ~/.local/bin/*/Kitname to identify kits
    - This does a topo sort based on the [kit]/load-depends file
    - This prints the load order as its only stdout
    - This prints errors for:
        - Dependency cycle detection
        - Missing dependency
    - This does a best-effort to produce the load order output in the face of errors
    - If a kit lacks a <kitname>.bashrc load file, this won't print it in the load order but does still consider load-depends

- [kit]/load-depends:
    - This is a simple list of kit names, one per line
    - This permits comments.  Everything after the hash is ignored
    - This permits blank lines

- setup-base.sh: [existing script]
    - This is modified to install shellkit-loader.bashrc + shellkit-loader.sh.  Both are installed as a matched pair.
    - This calls the old "shellkit-loader.sh --version" before overwriting it, protecting newer from overwrite by older

- create-kit.sh: [existing script]
    - This is modified to add a boilerplate [kit]/bin/load-depends file into the new kit

-  templates/make-kit.mk.template
    - This adds a pre-publish dependency on the compliance check target for new kits
    - Legacy kits can add this target manually once their compliance is upgraded


