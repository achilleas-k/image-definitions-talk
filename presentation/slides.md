---
title: If you wish to build a Linux image from scratch...
theme: black
css: ../style.css
revealOptions:
  transition: 'none'

---

## If you wish to build a Linux image from scratch...

... you must first invent the universe of image definitions

> Achilleas Koutsou

2023-06-16

---

# Part 0
## Overview

Notes:

The point of this talk:
- Building images is easy.  Building images that boot and are usable is a bit harder.
- We want to restrict what IB can build so that it's hard to build unusable images, but we also want to give users the power to make the choices they need.
  - These two things are in some ways in opposition to each other.
  - Our solution is to define abstractions that let us define images as configurations of components.  These components inform both the way we implement the image types in code but also how we present them to users.
- **This talk is about those abstractions/components**, how we define them, how we implement them, and whether they achieve the goal we set out to achieve.

- We want to map the abstractions all the way down to the bits in the image.  It's a direct path from a description like "RHEL 9 Azure image for running containers" down to the components we define in the code.

---

# Part 1
## Image builder
## The image building service

Notes:
- How image builder works.

Describe a manifest in three ways:
1. Show a real one
2. `jqstages` simplification.
3. Similar to `jqstages` but with natural-language descriptions of stages.

---

# Part 2
## Defining image types

Notes:

Refer to the manifests in the previous section to explain how choices affect stages and stage options.
Perhaps the easiest example to explain is package selection:
- Distro and Platform (architecture) define a base set of packages (and repositories).
- Environment adds packages based on where the image will run (bootloaders, cloud tools).
- Workload adds packages related to what the image will be used for.

Other stages are of course also modified by these choices, so maybe add a couple more examples.

---

# Part 3
## Image definition components

Notes:
- Distro
- Platform
- Environment
- Workload

How is each of these represented in code and how do they interact with one another.  How do we ensure they don't create broken images.

---

# Part 4
## User experience

Notes:
- What choices do we give users and how do these choices map to the components we defined.
