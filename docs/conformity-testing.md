# Shellkit Conformity testing

Conformity refers to the feature-completeness of the installed kit -- does it have all the things it's supposed to have to do versioning and dependency participation and hooking up the environment and supporting secondary self-install?

Once a kit has been built successfully and the owning kit has run its pre-publication tests, a conformity test should
execute which installs the kit (and any declared depends) into docker and probes for the required or expected features.

This is needed because there's a natural disconnect between the evolution of shellkit and its owners: kits can evolve independently of each other and shellkit, yet we want to be able to orchestrate that evolution coherently across all kits so none are left behind to cause trouble.

Thus the need for conformity checking to detect problems.

## Components

- `Makefile` target `shellkit-conformity-image`:
    - This invokes the `make-shellkit-conformity-image.sh` script
    - This requires an image named `shellkit-conformity:{version}`, where `version` is the `shellkit/version` file

- `Makefile` target `conformity-check`:
    - This make target depends on target `shellkit-conformity-image`
    - This runs `shellkit/conformity-check.sh` in the container
    - This maps volumes `host_home` and `docker.sock` and `/workspace` into the container
    - This creates the container `shellkit-conformity-checker`
    - `/workspace` maps to the root source folder of the kit

- `make-conformity-image.sh`
    - This creates `shellkit-conformity:{version}`
    - This expects a `--version n.n.n` arg, which is used to tag the image
    - This does not configure any non-root user.  Generally we expect to run conformity on root
    - This sets `/workspace` as WORKDIR in the image
