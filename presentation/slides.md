---
title: If you wish to build a Linux image from scratch...
theme: black
css: presentation/style.css
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

---

Building images is easy.

Making sure they boot and are useful is a bit harder.


Notes:

The point of this talk:
- Building images is easy.  Building images that boot and are usable is a bit harder.
- We want to restrict what users can build so that it's hard to build unusable images, but we also want to give users the power to make the choices they need.
  - These two things are in some ways in opposition to each other.
  - Our solution is to define abstractions that let us define images as configurations of components.  These components inform both the way we implement the image types in code but also how we present them to users.
- **This talk is about those abstractions/components**, how we define them, how we implement them, and whether they achieve the goal we set out to achieve.

- We want to map the abstractions all the way down to the bits in the image.  It's a direct path from a description like "RHEL 9 Azure image for running containers" down to the components we define in the code.

---

# Part 1
## Image builder
### It builds images

Notes:
- A look at how image builder works and what it's made of.

---

## Image builder

```

           composer cli   image builder   cockpit composer
           ————————————   —————————————   ————————————————
                ⬇️               ⬇️                ⬇️
                ——————————————————————————————————
                         osbuild composer
                         ————————————————
                                ⬇️
                             ———————
                             osbuild
```

Notes:
- This is the rough structure of the image builder stack.  At the top we have user interfaces, like the CLI, cockpit composer (a plugin for cockpit), and the image builder service that runs in console.redhat.com (our hosted service).
- I'll talk a bit about how osbuild works (the bottom part) but the focus of this talk will be almost entirely on the way we define images, which happens in osbuild-composer (the middle part).
- I might mention how the concepts discussed here affect the user interfaces.
TODO: consider adding `images` between osbuild and composer

---

## osbuild

An osbuild manifest

```json
{
  "pipelines": [
    {
      "name": "build",
      "runner": "org.osbuild.fedora38",
      "stages": [
        {
          "type": "org.osbuild.rpm",
          "inputs": { ... },
          "options": { ... }
        },
        {
          "type": "org.osbuild.selinux",
          "options": { ... }
        }
      ]
    },
    {
      "name": "os",
      "build": "name:build",
      "stages": [
        {
          "type": "org.osbuild.rpm",
          "inputs": { ... },
        },
        {
          "type": "org.osbuild.locale",
          "options": {
            "language": "en_US"
          }
        },
        {
          "type": "org.osbuild.hostname",
          "options": {
            "hostname": "localhost.localdomain"
          }
        },
        {
          "type": "org.osbuild.timezone",
          "options": {
            "zone": "UTC"
          }
        },
        {
          "type": "org.osbuild.users",
          "options": {
            "users": {
              "achilleas": {
                "key": "..."
              }
            }
          }
        },
        {
          "type": "org.osbuild.fstab",
          "options": {
            "filesystems": [
              {
                "uuid": "6e4ff95f-f662-45ee-a82a-bdf44a2d0b75",
                "vfs_type": "ext4",
                "path": "/",
                "options": "defaults"
              },
              {
                "uuid": "0194fdc2-fa2f-4cc0-81d3-ff12045b73c8",
                "vfs_type": "ext4",
                "path": "/boot",
                "options": "defaults"
              },
              {
                "uuid": "7B77-95E7",
                "vfs_type": "vfat",
                "path": "/boot/efi",
                "options": "defaults,uid=0,gid=0,umask=077,shortname=winnt",
                "passno": 2
              }
            ]
          }
        },
        {
          "type": "org.osbuild.grub2",
          "options": {
            "root_fs_uuid": "6e4ff95f-f662-45ee-a82a-bdf44a2d0b75",
            "boot_fs_uuid": "0194fdc2-fa2f-4cc0-81d3-ff12045b73c8",
            "kernel_opts": "ro no_timer_check console=ttyS0,115200n8 biosdevname=0 net.ifnames=0",
            "legacy": "i386-pc",
            "uefi": {
              "vendor": "fedora",
              "unified": true
            },
            "saved_entry": "ffffffffffffffffffffffffffffffff-6.3.4-201.fc38.x86_64",
            "write_cmdline": false,
            "config": {
              "default": "saved"
            }
          }
        },
        {
          "type": "org.osbuild.systemd",
          "options": {
            "enabled_services": [
              "cloud-init.service",
              "cloud-config.service",
              "cloud-final.service",
              "cloud-init-local.service"
            ],
            "default_target": "multi-user.target"
          }
        },
        {
          "type": "org.osbuild.selinux",
          "options": {
            "file_contexts": "etc/selinux/targeted/contexts/files/file_contexts"
          }
        }
      ]
    },
    {
      "name": "image",
      "build": "name:build",
      "stages": [
        {
          "type": "org.osbuild.truncate",
          "options": {
            "filename": "disk.img",
            "size": "5368709120"
          }
        },
        {
          "type": "org.osbuild.sfdisk",
          "options": {
            "label": "gpt",
            "uuid": "D209C89E-EA5E-4FBD-B161-B461CCE297E0",
            "partitions": [
              {
                "bootable": true,
                "size": 2048,
                "start": 2048,
                "type": "21686148-6449-6E6F-744E-656564454649",
                "uuid": "FAC7F1FB-3E8D-4137-A512-961DE09A5549"
              },
              {
                "size": 409600,
                "start": 4096,
                "type": "C12A7328-F81F-11D2-BA4B-00A0C93EC93B",
                "uuid": "68B2905B-DF3E-4FB3-80FA-49D1E773AA33"
              },
              {
                "size": 1024000,
                "start": 413696,
                "type": "0FC63DAF-8483-4772-8E79-3D69D8477DE4",
                "uuid": "CB07C243-BC44-4717-853E-28852021225B"
              },
              {
                "size": 9048031,
                "start": 1437696,
                "type": "0FC63DAF-8483-4772-8E79-3D69D8477DE4",
                "uuid": "6264D520-3FB9-423F-8AB8-7A0A8E3D3562"
              }
            ]
          },
          "devices": {
            "device": {
              "type": "org.osbuild.loopback",
              "options": {
                "filename": "disk.img",
                "lock": true
              }
            }
          }
        },
        {
          "type": "org.osbuild.mkfs.fat",
          "options": {
            "volid": "7B7795E7"
          },
          "devices": {
            "device": {
              "type": "org.osbuild.loopback",
              "options": {
                "filename": "disk.img",
                "start": 4096,
                "size": 409600,
                "lock": true
              }
            }
          }
        },
        {
          "type": "org.osbuild.mkfs.ext4",
          "options": {
            "uuid": "0194fdc2-fa2f-4cc0-81d3-ff12045b73c8",
            "label": "boot"
          },
          "devices": {
            "device": {
              "type": "org.osbuild.loopback",
              "options": {
                "filename": "disk.img",
                "start": 413696,
                "size": 1024000,
                "lock": true
              }
            }
          }
        },
        {
          "type": "org.osbuild.mkfs.ext4",
          "options": {
            "uuid": "6e4ff95f-f662-45ee-a82a-bdf44a2d0b75",
            "label": "root"
          },
          "devices": {
            "device": {
              "type": "org.osbuild.loopback",
              "options": {
                "filename": "disk.img",
                "start": 1437696,
                "size": 9048031,
                "lock": true
              }
            }
          }
        },
        {
          "type": "org.osbuild.copy",
          "inputs": {
            "root-tree": {
              "type": "org.osbuild.tree",
              "origin": "org.osbuild.pipeline",
              "references": [
                "name:os"
              ]
            }
          },
          "options": {
            "paths": [
              {
                "from": "input://root-tree/",
                "to": "mount://root/"
              }
            ]
          },
          "devices": {
            "boot": {
              "type": "org.osbuild.loopback",
              "options": {
                "filename": "disk.img",
                "start": 413696,
                "size": 1024000
              }
            },
            "boot.efi": {
              "type": "org.osbuild.loopback",
              "options": {
                "filename": "disk.img",
                "start": 4096,
                "size": 409600
              }
            },
            "root": {
              "type": "org.osbuild.loopback",
              "options": {
                "filename": "disk.img",
                "start": 1437696,
                "size": 9048031
              }
            }
          },
          "mounts": [
            {
              "name": "root",
              "type": "org.osbuild.ext4",
              "source": "root",
              "target": "/"
            },
            {
              "name": "boot",
              "type": "org.osbuild.ext4",
              "source": "boot",
              "target": "/boot"
            },
            {
              "name": "boot.efi",
              "type": "org.osbuild.fat",
              "source": "boot.efi",
              "target": "/boot/efi"
            }
          ]
        },
        {
          "type": "org.osbuild.grub2.inst",
          "options": {
            "filename": "disk.img",
            "platform": "i386-pc",
            "location": 2048,
            "core": {
              "type": "mkimage",
              "partlabel": "gpt",
              "filesystem": "ext4"
            },
            "prefix": {
              "type": "partition",
              "partlabel": "gpt",
              "number": 2,
              "path": "/grub2"
            }
          }
        }
      ]
    },
    {
      "name": "qcow2",
      "build": "name:build",
      "stages": [
        {
          "type": "org.osbuild.qemu",
          "inputs": {
            "image": {
              "type": "org.osbuild.files",
              "origin": "org.osbuild.pipeline",
              "references": {
                "name:image": {
                  "file": "disk.img"
                }
              }
            }
          },
          "options": {
            "filename": "disk.qcow2",
            "format": {
              "type": "qcow2",
              "compat": "1.1"
            }
          }
        }
      ]
    }
  ]
}
```


Notes:
- osbuild is a command line utility that takes a manifest and returns one or more filesystem trees.
- osbuild consumes a manifest, a big json structure that describes some sources (e.g., rpm urls) and a series of pipelines.
- A pipeline is a series of steps called stages, each of which modifies a filesystem tree in different ways.
- osbuild makes **no guarantees** about what the manifest will produce.  It simply and stupidly executes the stages as described and returns the filesystem trees that are specified on the command line.

---

## osbuild

Pipelines and stages

```
Pipeline: build                    Pipeline: image
  org.osbuild.rpm                    org.osbuild.truncate
  org.osbuild.selinux                org.osbuild.sfdisk
Pipeline: os                         org.osbuild.mkfs.fat
  org.osbuild.kernel-cmdline         org.osbuild.mkfs.ext4
  org.osbuild.rpm                    org.osbuild.mkfs.ext4
  org.osbuild.fix-bls                org.osbuild.copy
  org.osbuild.locale                 org.osbuild.grub2.inst
  org.osbuild.hostname             Pipeline: qcow2
  org.osbuild.timezone               org.osbuild.qemu
  org.osbuild.users
  org.osbuild.fstab
  org.osbuild.grub2
  org.osbuild.systemd
  org.osbuild.selinux
```

---

## osbuild

- org.osbuild.rpm: install packages to a tree
- org.osbuild.selinux: set selinux file contexts
- org.osbuild.hostname: write /etc/hostname
- org.osbuild.sfdisk: partition a device

Notes:
TODO: consider moving this slide one step up, describe some stages, and then show the pipelines and stages explaining how it works.

---

# Part 2
## Defining image types

Notes:
- On its own, osbuild isn't very useful.  No one is expected to write manifests by hand.
- So we provide a library that holds the domain knowledge of what a bootable image of a specific distribution should look like and how to create a manifest that will produce it.
- These are the base images we define in composer and present to the user.

---

## Defining image types

All our configurations should be
- Buildable
- Usable

Note:
- Like I mentioned earlier: osbuild makes no guarantees about what it will produce for any given manifest.
- osbuild-composer on the other hand needs to:
  - produce the image the user requested,
  - and the image should be bootable (usable).
- The easy way to guarantee this is to restrict user choice: the smaller the configuration space, the fewer things we have to think about and test.
- But the more we restrict user choice, the less useful our project becomes.

---

## Defining image types

1. OS distribution
2. Hardware architecture
3. Target environment

Notes:
- When we talk about the images that we build, we refer to an image file or archive that contains an operating system tree.
- An **image type** is a predefined image configuration.
- Ignoring any user customizations, the base configuration needs to specify at the very least the OS distribution, the hardware architecture, and the target environment.
- For example:
  - Fedora 38 x86 for azure
  - RHEL 9 aarch64 for aws

---

## Defining image types

1. OS distribution: Base packages and repositories
2. Hardware architecture: Package/repository architecture, bootloader, firmware
3. Target environment: Packages, configurations

Notes:
- An image type is a configuration of these three choices.
- Considering the osbuild stages we saw earlier, each choice affects stages and stage options.
  - The distribution defines a base set of package names and repositories (content sources)
  - The architecture defines the architecture of those packages (and repositories) as well as extra packages and configurations, like specific firmware, bootloader configs, etc.
  - The environment adds packages, like cloud agents, and modifies configurations, like firewall rules.
- It's important that our image definitions abstract away any knowledge of the manifest, pipelines, and stages.

---

# Part 3
## Image definition components

Notes:
- This is the part of the talk where I describe things we haven't finalised yet in the project, so some things might be a bit more conceptual or could change in the future.
- We want to define the choices we saw earlier as abstractions in our code but also in conceptually in the way we reason about image definitions and the way we present choices to the user.

---

## Image definition components

1. Distribution
2. Platform
3. Environment
4. Workload


Notes:
- On top of the three choices we've seen already, we add another one that represents what the image is intended for, the workload.
- Overall we have:
  - Distro: as before.
  - Platform: a generalisation of the architecture we saw earlier, which can include variations or more specific choices, like firmware packages for specific devices.
  - Environment: also as before.
  - Workload: the intended use of the image, which can be user defined or predefined by the project for common workloads (e.g., a _web server_ workload which contains packages, firewall rules, and sane defaults for running a web service).
- We can go through a scenario with these components and see how the abstractions have concrete effects on the content and stages for the final image.

---

## Image definition components

1. Distribution: Fedora 38
    - Repositories: All Fedora 38 repos
    - Packages: `@core`
    - Stages: Fedora 38 build environment

Notes:
- We start by selecting a distribution that gives us a set of repositories and packages.

---

## Image definition components

2. Architecture: x86_64
    - Repositories: Fedora 38 **x86_64**
    - Packages: `@core` + `grub2-efi-x64` + `shim-x64`
    - Stages: Fedora 38 build environment + grub2 config + grub2 install

Notes:
- Then we select the architecture which narrows down the repositories and adds boot-related packages as well as extra stages to configure and install the bootloader

---

## Image definition components

3. Environment: AWS EC2
    - Repositories: Fedora 38 **x86_64**
    - Packages: `@core` + `grub2-efi-x64` + `shim-x64` + `@Fedora Cloud Server` + `cloud-init`
    - Stages: build environment + grub2 config + grub2 install + systemd (enable cloud-init)

Notes:
- Selecting the AWS EC2 environment adds the cloud server packages and a systemd stage to enable the cloud-init service on boot, which takes care of resizing partitions and creating users on first boot through the AWS cloud console.

---

## Image definition components

4. Workload: Web server
    - Repositories: Fedora 38 **x86_64**
    - Packages: `@core` + `grub2-efi-x64` + `shim-x64` + `@Fedora Cloud Server` + `cloud-init` + `nginx`
    - Stages: build environment + grub2 config + grub2 install + systemd (enable cloud-init) + nginx config

Notes:
- And finally, selecting the web server workload adds a web server, nginx, and the appropriate stage to configure it if necessary.

---

# Part 4
## User experience

Notes:
- What choices do we give users and how do these choices map to the components we defined.

---

## User experience

Current state
1. Select distribution
2. Select image type: `guest-image`, `aws`, `azure`, `gcp`, ...

Notes:
- Up until now, the experience has been pretty straightforward
- Users can select a distribution version, build x86 (on the service) or the host architecture (on prem), and then select an image type.

---

## User experience

Expose all the components

Notes:
- But why not just expose all the components instead?
- Meaning: Select a distribution version (like now), select an environment

---
