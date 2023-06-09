# Preparation notes

- How does IB differ from other solutions (terraform, kickstarts, Amazon IB).
- We want to map the abstractions all the way down to the bits in the image.  It's a direct path from a description like "RHEL 9 Azure image for running containers" down to the components we define in the code.
- Briefly focus on things that need to be done at build time (vs boot and runtime).  Some things can be done after build (extra packages and some configs), but other things need to be configured during build (security hardening).
- How long does it usually take to build an image?
- It is a managed service so it needs to guarantee that it builds bootable (usable) images.


