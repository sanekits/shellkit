# Shellkit Conformity testing

Conformity refers to the feature-completeness of the installed kit -- does it have all the things it's supposed to have to do versioning and dependency participation and hooking up the environment and supporting secondary self-install?

Once a kit has been built successfully and the owning kit has run its pre-publication tests, a conformity test should
execute which installs the kit (and any declared depends) into docker and probes for the required or expected features.

This is needed because there's a natural disconnect between the evolution of shellkit and its owners: kits can evolve independently of each other and shellkit, yet we want to be able to orchestrate that evolution coherently across all kits so none are left behind to cause trouble.

Thus the need for conformity checking to detect problems.

## Components

- `Makefile` target `conformity-check`:
    - This make target depends on the shared shellkit-component.mk *(see
        `${ShellkitWorkspace}/.devcontainer/shellkit-component.mk` )*
    - This runs `shellkit/conformity-check.sh` in the shellkit-conformity container
    - Volumes `host_home` and `/workspace` are mapped into the container
    - `/workspace` maps to the `ShellkitWorkspace` folder

