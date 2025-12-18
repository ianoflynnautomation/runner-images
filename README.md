# GitHub Actions Runner Images (Custom Fork)

> **Note:** This is a custom fork of the [GitHub Actions Runner Images](https://github.com/actions/runner-images) repository. This fork includes customizations for building and managing Ubuntu runner images in Azure using Terraform infrastructure and automated GitHub Actions workflows.

**Table of Contents**

- [About This Fork](#about-this-fork)
- [Custom Features](#custom-features)
- [Quick Start](#quick-start)
- [Terraform Infrastructure](#terraform-infrastructure)
- [GitHub Actions Workflow](#github-actions-workflow)
- [Available Images](#available-images)
- [Image Definitions](#image-definitions)
- [Software and Image Support](#software-and-image-support)
- [How to Interact with the Repo](#how-to-interact-with-the-repo)
- [FAQs](#faqs)

## About This Fork

This repository is a fork of the official [GitHub Actions Runner Images](https://github.com/actions/runner-images) repository, customized to build and manage Ubuntu runner images in Azure. The fork includes:

- **Terraform Infrastructure**: Automated provisioning of Azure Compute Gallery, user-assigned managed identity, and federated identity credentials for secure OIDC authentication
- **Custom GitHub Actions Workflow**: Automated image building and validation workflow that uses OIDC authentication
- **Custom Image Definitions**: Pre-configured image definitions for Ubuntu 22.04 and 24.04 in Azure Compute Gallery

This fork maintains compatibility with the upstream repository while adding infrastructure-as-code capabilities and automated CI/CD for image building.

## Custom Features

### Terraform Infrastructure

The `terraform/` directory contains infrastructure code to provision:

- **Azure Compute Gallery (Shared Image Gallery)**: Centralized repository for versioned VM images
- **User-Assigned Managed Identity**: Identity used by Packer for Azure authentication
- **Federated Identity Credential**: OIDC-based authentication for GitHub Actions workflows
- **Resource Groups**: Separate resource groups for images, build resources, and networking
- **Role Assignments**: Proper RBAC permissions for the managed identity

### GitHub Actions Workflow

The `.github/workflows/build_custom_ubuntu_runner_image.yaml` workflow provides:

- **Automated Image Building**: Triggered manually via `workflow_dispatch`
- **OIDC Authentication**: Secure authentication to Azure without storing secrets
- **Packer Integration**: Automated Packer template validation and image building
- **Version Management**: Automatic versioning based on GitHub run numbers
- **Multi-Image Support**: Matrix strategy for building multiple Ubuntu versions

## Quick Start

### Prerequisites

1. **Azure Subscription**: An active Azure subscription with appropriate permissions
2. **GitHub Repository**: This repository with GitHub Actions enabled
3. **Terraform**: Version >= 1.9.0, < 2.0.0
4. **Azure CLI**: For authentication and resource management

### Step 1: Deploy Terraform Infrastructure

1. Navigate to the `terraform/` directory:
   ```bash
   cd terraform
   ```

2. Create a `terraform.tfvars` file with your configuration:
   ```hcl
   subscription_id            = "your-subscription-id"
   location                   = "switzerlandnorth"
   name                       = "your-gallery-name"
   image_resource_group_name  = "rg-images"
   build_resource_group_name  = "rg-build"
   network_resource_group_name = "rg-network"
   github_repo               = "your-org/your-repo"
   github_branch             = "refs/heads/main"
   publisher                 = "YourOrganization"
   ```

3. Initialize and apply Terraform:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. Note the output values, especially `workload_identity_client_id`:
   ```bash
   terraform output workload_identity_client_id
   ```

### Step 2: Configure GitHub Secrets

Add the following secrets to your GitHub repository:

- `AZURE_CLIENT_ID`: The client ID from the Terraform output (`workload_identity_client_id`)
- `AZURE_TENANT_ID`: Your Azure tenant ID
- `AZURE_SUBSCRIPTION_ID`: Your Azure subscription ID
- `IMAGE_RESOURCE_GROUP`: The resource group name where images are stored (e.g., `rg-images`)
- `BUILD_RG_NAME`: The resource group name for build resources (e.g., `rg-build`)

### Step 3: Update Workflow Configuration

Update the workflow file `.github/workflows/build_custom_ubuntu_runner_image.yaml` with your specific values:

- `GALLERY_NAME`: Your Azure Compute Gallery name
- `LOCATION`: Your Azure region
- Matrix configuration for the images you want to build

### Step 4: Build Images

1. Go to the **Actions** tab in your GitHub repository
2. Select **Build Custom Ubuntu Runner Image**
3. Click **Run workflow**
4. Monitor the workflow execution

The built images will be available in your Azure Compute Gallery and can be used to create VMs or scale sets.

## Terraform Infrastructure

### Overview

The Terraform configuration in the `terraform/` directory provisions all necessary Azure resources for building and storing runner images.

### Key Resources

- **`azurerm_resource_group.images`**: Resource group for storing images and the compute gallery
- **`azurerm_resource_group.build`**: Resource group for temporary build resources
- **`azurerm_user_assigned_identity.identity`**: Managed identity for authentication
- **`azurerm_federated_identity_credential.github`**: OIDC credential for GitHub Actions
- **`module.compute_gallery`**: Azure Compute Gallery with image definitions

### Image Definitions

The Terraform configuration includes pre-defined image definitions for:

- **Ubuntu 22.04 LTS**: `github-runner-ubuntu-2204`
- **Ubuntu 24.04 LTS**: `github-runner-ubuntu-2404`

Each definition includes:
- OS type and architecture
- Hyper-V generation
- Recommended VM sizes
- End-of-life dates
- Metadata tags

### Customization

To customize the infrastructure:

1. Modify `terraform/variables.tf` to add or change variables
2. Update `terraform/main.tf` to add additional image definitions or resources
3. Adjust the `shared_image_definitions` in the compute gallery module

### Outputs

The Terraform configuration outputs:
- `workload_identity_client_id`: The client ID of the managed identity (required for GitHub secrets)

## GitHub Actions Workflow

### Workflow Overview

The `build_custom_ubuntu_runner_image.yaml` workflow automates the image building process:

1. **Checkout**: Retrieves the repository code
2. **Azure Login**: Authenticates using OIDC (no secrets required)
3. **Packer Setup**: Installs and configures Packer
4. **Validation**: Validates Packer templates before building
5. **Build**: Executes Packer to build the VM image
6. **Publish**: Publishes the image to Azure Compute Gallery

### Workflow Configuration

Key environment variables in the workflow:

- `GALLERY_NAME`: Name of your Azure Compute Gallery
- `LOCATION`: Azure region for resources
- `PACKER_VERSION`: Packer version to use
- `IMAGE_VERSION`: Version format (e.g., `1.0.{run_number}`)

### Matrix Strategy

The workflow uses a matrix strategy to build multiple images. Currently configured for:
- Ubuntu 24.04 (`ubuntu24`)

To add Ubuntu 22.04, uncomment the relevant lines in the matrix configuration.

### Permissions

The workflow requires:
- `contents: read`: To checkout the repository
- `id-token: write`: For OIDC authentication

### Manual Trigger

The workflow is triggered manually via `workflow_dispatch`. To build images:

1. Navigate to Actions → Build Custom Ubuntu Runner Image
2. Click "Run workflow"
3. Select the branch (usually `main`)
4. Click "Run workflow"

## About

This repository contains the source code used to create the VM images for [GitHub-hosted runners](https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners) used for Actions, as well as for [Microsoft-hosted agents](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/hosted?view=azure-devops#use-a-microsoft-hosted-agent) used for Azure Pipelines.

For detailed information on building images manually, see the [instructions](docs/create-image-and-azure-resources.md).

## Available Images

| Image | YAML Label | Included Software |
| --------------------|---------------------|--------------------|
| Ubuntu 24.04 | `ubuntu-latest` or `ubuntu-24.04` | [ubuntu-24.04] |
| Ubuntu 22.04 | `ubuntu-22.04` | [ubuntu-22.04] |
| macOS 26 Arm64 `beta` | `macos-26` or `macos-26-xlarge` | [macOS-26-arm64] |
| macOS 15 | `macos-latest-large`, `macos-15-large`, or `macos-15-intel` | [macOS-15] |
| macOS 15 Arm64 | `macos-latest`, `macos-15`, or `macos-15-xlarge` | [macOS-15-arm64] |
| macOS 14 | `macos-14-large`| [macOS-14] |
| macOS 14 Arm64 | `macos-14` or `macos-14-xlarge`| [macOS-14-arm64] |
| macOS 13 [![Deprecated badge](https://img.shields.io/badge/-Deprecated-red)](https://github.com/actions/runner-images/issues/13046) | `macos-13` or `macos-13-large` | [macOS-13] |
| macOS 13 Arm64 [![Deprecated badge](https://img.shields.io/badge/-Deprecated-red)](https://github.com/actions/runner-images/issues/13046) | `macos-13-xlarge` | [macOS-13-arm64] |
| Windows Server 2025 | `windows-latest` or `windows-2025` | [windows-2025] |
| Windows Server 2022 | `windows-2022` | [windows-2022] |
| Windows Server 2019 [![Deprecated badge](https://img.shields.io/badge/-Deprecated-red)](https://github.com/actions/runner-images/issues/12045) | `windows-2019` | [windows-2019] |

### Label scheme

- In general the `-latest` label is used for the latest OS image version that is GA
- Before moving the`-latest` label to a new OS version we will announce the change and give sufficient lead time for users to update their workflows

[ubuntu-24.04]: https://github.com/actions/runner-images/blob/main/images/ubuntu/Ubuntu2404-Readme.md
[ubuntu-22.04]: https://github.com/actions/runner-images/blob/main/images/ubuntu/Ubuntu2204-Readme.md
[windows-2019]: https://github.com/actions/runner-images/blob/main/images/windows/Windows2019-Readme.md
[windows-2025]: https://github.com/actions/runner-images/blob/main/images/windows/Windows2025-Readme.md
[windows-2022]: https://github.com/actions/runner-images/blob/main/images/windows/Windows2022-Readme.md
[macOS-13]: https://github.com/actions/runner-images/blob/main/images/macos/macos-13-Readme.md
[macOS-13-arm64]: https://github.com/actions/runner-images/blob/main/images/macos/macos-13-arm64-Readme.md
[macOS-14]: https://github.com/actions/runner-images/blob/main/images/macos/macos-14-Readme.md
[macOS-14-arm64]: https://github.com/actions/runner-images/blob/main/images/macos/macos-14-arm64-Readme.md
[macOS-15]: https://github.com/actions/runner-images/blob/main/images/macos/macos-15-Readme.md
[macOS-15-arm64]: https://github.com/actions/runner-images/blob/main/images/macos/macos-15-arm64-Readme.md
[macOS-26-arm64]: https://github.com/actions/runner-images/blob/main/images/macos/macos-26-arm64-Readme.md
[self-hosted runners]: https://help.github.com/en/actions/hosting-your-own-runners

## Image Definitions

### Beta

The purpose of a Beta is to collect feedback on an image before it is released to GA. The goal of a Beta is to identify and fix any potential issues that exist on that
image. Images are updated on a weekly cadence. Any workflows that run on a beta image do not fall under the customer [SLA](https://github.com/customer-terms/github-online-services-sla) in place for Actions.
Customers choosing to use Beta images are encouraged to provide feedback in the runner-images repo by creating an issue. A Beta may take on different availability, i.e. public vs private.

### GA

A GA (General Availability) image has been through a Beta period and is deemed ready for general use. Images are updated on a weekly cadence. In order to be moved to
GA the image must meet the following criteria:

1. Has been through a Beta period (public or private)
2. Most major software we install on the image has a compatible
version for the underlying OS and
3. All major bugs reported during the Beta period have been addressed.

This image type falls under the customer [SLA](https://github.com/customer-terms/github-online-services-sla) for actions. GA images are eventually deprecated according to our guidelines as we only support the
latest 2 versions of an OS.

#### Latest Migration Process

GitHub Actions and Azure DevOps use the `-latest` YAML label (ex: `ubuntu-latest`, `windows-latest`, and `macos-latest`). These labels point towards the newest stable OS version available.


The `-latest` migration process is gradual and happens over 1-2 months in order to allow customers to adapt their workflows to the newest OS version. During this process, any workflow using the `-latest` label, may see changes in the OS version in their workflows or pipelines. To avoid unwanted migration, users can specify a specific OS version in the yaml file (ex: macos-14, windows-2022, ubuntu-22.04).

## Image Releases

Images are built on-demand using the GitHub Actions workflow. Each build creates a new version in the Azure Compute Gallery with the format `1.0.{run_number}`.

To track image builds:
- Monitor the GitHub Actions workflow runs
- Check the Azure Compute Gallery for new image versions
- Review the workflow logs for build details and any issues

*Note:* This fork builds images independently from the upstream repository. For information about upstream releases, see the [original repository](https://github.com/actions/runner-images).

## Software and Image Support

### Support Policy

- Tools and versions will typically be removed 6 months after they are deprecated or have reached end-of-life
- We support (at maximum) 2 GA images and 1 beta image at a time. We begin the deprecation process of the oldest image label once the newest OS image label has been released to GA.
- The images generally contain the latest versions of packages installed except for Ubuntu LTS where we mostly rely on the Canonical-provided repositories.

- Popular tools can have several versions installed side-by-side with the following strategy:

| Tool name | Installation strategy |
|-----------|-----------------------|
| Docker images | not more than 3 latest LTS OS\tool versions. New images or new versions of current images are added using the standard tool request process |
| Java      | all LTS versions |
| Node.js   | 3 latest LTS versions |
| Go        | 3 latest minor versions |
| Python <br/> Ruby | 5 most popular `major.minor` versions |
| PyPy      | 3 most popular `major.minor` versions |
| .NET Core | 2 latest LTS versions and 1 latest version. For each feature version only latest patch is installed. Note for [Ubuntu images see details.](./docs/dotnet-ubuntu.md) |
| GCC <br/> GNU Fortran <br/> Clang <br/> GNU C++ | 3 latest major versions |
| Android NDK | 1 latest non-LTS, 2 latest LTS versions |
| Xcode     | - only one major version of Xcode will be supported per macOS version <br/> - all minor versions of the supported major version will be available <br/> - beta and RC versions will be provided "as-is" in the latest available macOS image only no matter of beta/GA status of the image <br/> - when a new patch version is released, the previous patch version will be replaced |
| Xcode Platforms | - only three major.minor versions of platform tools and simulator runtimes will be available for installed Xcode, including beta/RC versions |

### Package managers usage

We use third-party package managers to install software during the image generation process. The table below lists the package managers and the software installed.
> [!NOTE]
> Third-party repositories are re-evaluated every year to identify if they are still useful and secure.

| Operating system | Package manager                       | Third-party repos and packages |
| :---             |        :---:                          |                           ---: |
| Ubuntu           | [APT](https://wiki.debian.org/Apt)    | [docker](https://download.docker.com/linux/ubuntu) <br/> [Eclipse-Temurin (Adoptium)](https://packages.adoptium.net/artifactory/deb/) <br/> [Erlang](https://packages.erlang-solutions.com/ubuntu) <br/> [Firefox](https://ppa.launchpad.net/mozillateam/ppa/ubuntu) <br/> [git-lfs](https://packagecloud.io/install/repositories/github/git-lfs) <br/> [git](https://launchpad.net/~git-core/+archive/ubuntu/ppa) <br/> [Google Cloud CLI](https://packages.cloud.google.com/apt) <br/> [Heroku](https://cli-assets.heroku.com/channels/stable/apt) <br/> [HHvm](https://dl.hhvm.com/ubuntu) <br/> [MongoDB](https://repo.mongodb.org/apt/ubuntu) <br/> [Mono](https://download.mono-project.com/repo/ubuntu) <br/> [MS Edge](https://packages.microsoft.com/repos/edge) <br/> [PostgreSQL](https://apt.postgresql.org/pub/repos/apt/) <br/> [R](https://cloud.r-project.org/bin/linux/ubuntu)                                      |
|                  | [pipx](https://pypa.github.io/pipx)   | ansible-core <br/>yamllint     |
| Windows          | [Chocolatey](https://chocolatey.org)  | No third-party repos installed |
| macOS            | [Homebrew](https://brew.sh)           | [aws-cli v2](https://github.com/aws/homebrew-tap) </br> [azure/bicep](https://github.com/Azure/homebrew-bicep) </br> [mongodb/brew](https://github.com/mongodb/homebrew-brew)                                                  |
|                  | [pipx](https://pypa.github.io/pipx/)  | yamllint                       |

### Image Deprecation Policy

- Images begin the deprecation process of the oldest image label once a new GA OS version has been released.
- Deprecation process begins with an announcement that sets a date for deprecation
- As it gets closer to the date, GitHub begins doing scheduled brownouts of the image
- During this time there will be an Announcement pinned in the repo to remind users of the deprecation.
- Finally GitHub will deprecate the image and it will no longer be available

### Preinstallation Policy

In general, these are the guidelines we follow when deciding what to pre-install on our images:

- Popularity: widely-used tools and ecosystems will be given priority.
- Latest Technology: recent versions of tools will be given priority.
- Deprecation: end-of-life tools and versions will not be added.
- Licensing: MIT, Apache, or GNU licenses are allowed.
- Time & Space on the Image: we will evaluate how much time is saved and how much space is used by having the tool pre-installed.
- Support: If a tool requires the support of more than one version, we will consider the cost of this maintenance.

### Default Version Update Policy

- In general, once a new version is installed on the image, we announce the default version update 2 weeks prior to deploying it.
- For potentially dangerous updates, we may extend the timeline up to 1 month between the announcement and deployment.

## How to Interact with the Repo

This is a custom fork, so interaction is limited to this repository:

- **Issues**: Use this repository's issue tracker for bug reports or feature requests specific to this fork
- **Pull Requests**: Contributions to this fork are welcome
- **Upstream Issues**: For issues related to the upstream runner-images project, please use the [original repository](https://github.com/actions/runner-images)
- **General Questions**: For general questions about GitHub Actions or runner images, see the [GitHub Actions Community Forum](https://github.community/c/github-actions/41)

## FAQs

<details>
   <summary><b><i>What images are available for GitHub Actions and Azure DevOps?</b></i></summary>

The availability of images for GitHub Actions and Azure DevOps is the same. However, deprecation policies may differ. See documentation for more details:
- [GitHub Actions](https://docs.github.com/en/free-pro-team@latest/actions/reference/specifications-for-github-hosted-runners#supported-runners-and-hardware-resources)
- [Azure DevOps](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/hosted?view=azure-devops&tabs=yaml#software)
</details>

<details>
   <summary><b><i>What image version is used in my build?</b></i></summary>

Usually, image deployment takes 2-3 days, and documentation in the `main` branch is only updated when deployment is finished. To find out which image version and what software versions are used in a specific build, see `Set up job` (GitHub Actions) or `Initialize job` (Azure DevOps) step log.
<img width="1440" alt="actions-runner-image" src="https://github.com/actions/runner-images/assets/88318005/922a8bf5-3e4d-4265-9527-b3b51e6bf9c8">
</details>

<details>
   <summary><b><i>Looking for other Linux distributions?</b></i></summary>

We do not plan to offer other Linux distributions. We recommend using Docker if you'd like to build using other distributions with the hosted runner images. Alternatively, you can leverage [self-hosted runners] and fully customize your VM image to your needs.
</details>

<details>
   <summary><b><i>How do I contribute to the macOS source?</b></i></summary>

macOS source lives in this repository and is available for everyone. However, macOS image-generation CI doesn't support external contributions yet so we are not able to accept pull-requests for now.

We are in the process of preparing macOS CI to accept contributions. Until then, we appreciate your patience and ask you to continue to make tool requests by filing issues.
</details>

<details>
   <summary><b><i>How does GitHub determine what tools are installed on the images?</b></i></summary>

For some tools, we always install the latest at the time of the deployment; for others, we pin the tool to specific version(s). For more details please see the [Preinstallation Policy](#preinstallation-policy)
</details>

<details>
   <summary><b><i>How do I request that a new tool be pre-installed on the image?</b></i></summary>
Please create an issue and get an approval from us to add this tool to the image before creating the pull request.
</details>

<details>
   <summary><b><i>What branch should I use to build custom image?</b></i></summary>
We strongly encourage building images using the main branch.
This repository contains multiple branches and releases that serve as document milestones to reflect what software is installed in the images at certain point of time. Current builds are not idempotent and if one tries to build a runner image using the specific tag it is not guaranteed that the build will succeed.

For this fork, use the GitHub Actions workflow which builds from the branch you select when triggering the workflow.
</details>

<details>
   <summary><b><i>How do I customize the image definitions?</b></i></summary>
To customize image definitions:

1. **Add new image definitions**: Edit `terraform/main.tf` and add entries to the `shared_image_definitions` map in the compute gallery module
2. **Modify existing definitions**: Update the existing entries in `terraform/main.tf`
3. **Update workflow matrix**: Add or modify entries in `.github/workflows/build_custom_ubuntu_runner_image.yaml` matrix strategy
4. **Customize toolset**: Modify the toolset JSON files in `images/ubuntu/toolsets/` to change installed software

After making changes, run `terraform plan` and `terraform apply` to update the infrastructure, then trigger the workflow to build new images.
</details>

<details>
   <summary><b><i>How do I use the built images?</b></i></summary>
Once images are built and published to your Azure Compute Gallery, you can:

1. **Create VMs directly**: Use Azure Portal, CLI, or Terraform to create VMs from the gallery images
2. **Use in VM Scale Sets**: Reference the gallery image in your scale set configuration
3. **Share with other subscriptions**: Configure gallery sharing in Terraform to share images across subscriptions or tenants

To reference an image, use:
- Gallery name: From your Terraform configuration
- Image definition: e.g., `github-runner-ubuntu-2404`
- Image version: e.g., `1.0.123` (from the workflow run number)
</details>

## Maintaining This Fork

### Syncing with Upstream

To keep this fork up-to-date with the upstream repository:

1. **Add upstream remote** (if not already added):
   ```bash
   git remote add upstream https://github.com/actions/runner-images.git
   ```

2. **Fetch upstream changes**:
   ```bash
   git fetch upstream
   ```

3. **Merge upstream changes**:
   ```bash
   git checkout main
   git merge upstream/main
   ```

4. **Resolve conflicts**: If conflicts occur, resolve them carefully, especially in:
   - `images/ubuntu/` directories (image build scripts)
   - `.github/workflows/` (if you want to keep upstream workflows)
   - `terraform/` (your custom infrastructure - likely no conflicts)

5. **Test after syncing**: After syncing, test the workflow to ensure images still build correctly

### Custom Files to Preserve

When syncing with upstream, be careful to preserve:
- `terraform/` directory (entire directory is custom)
- `.github/workflows/build_custom_ubuntu_runner_image.yaml` (custom workflow)
- Any modifications to Packer templates in `images/ubuntu/templates/`
- Custom toolset configurations in `images/ubuntu/toolsets/`

### Original Repository

This fork is based on the [GitHub Actions Runner Images](https://github.com/actions/runner-images) repository. For issues, discussions, or contributions related to the upstream project, please use the original repository.

---

**License**: This fork maintains the same license as the upstream repository. See [LICENSE](LICENSE) for details.
