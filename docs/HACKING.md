---
title: Hacking on FileSystemds
category: Contributing
layout: default
SPDX-License-Identifier: LGPL-2.1-or-later
---

# Hacking on FileSystemds

We welcome all contributions to FileSystemds Mobile Platform. If you notice a bug or a missing
feature, please feel invited to fix it, and submit your work as a
[GitHub Pull Request (PR)](https://github.com/spiralgang/FileSystemds/pull/new).

Please make sure to follow our [Coding Style](CODING_STYLE.md) when submitting
patches. Also have a look at our [Contribution Guidelines](CONTRIBUTING.md).

## Development Principles

FileSystemds follows a modular, agent-driven, mobile/cloud-first architecture. When hacking on the project:

- **Design for modularity**: Create replaceable components, not hardwired logic
- **Think agent-first**: APIs and workflows should be automation-friendly
- **Mobile/edge focus**: Consider mobile and edge computing constraints
- **Security by design**: Follow pointer-first artifact management and security best practices

## Testing

When adding new functionality, tests should be added. Please always test your work before submitting a PR.

For mobile platform development:
- Test on actual Android devices when possible
- Consider different screen sizes and orientations
- Test offline capabilities
- Verify resource usage is appropriate for mobile devices

## Building and Testing

### Android APK Build

The project includes automated Android APK building. To test locally:

```bash
# Check the GitHub Actions workflow for build steps
.github/workflows/android-apk-build.yml
```

### Running Tests

```bash
# Run any existing test suite
# (Check for test directories and scripts in the project)
```

## Code Organization

The project is organized with:
- `android/` - Android-specific mobile platform code
- `scripts/` - Build and automation scripts
- `src/` - Core source code
- `docs/` - Documentation

## Pointer-First Artifact Management

Large assets should be handled via pointer-first approaches:
- Use `/productenv/src/UserlAss/hf_prepare.sh` for asset fetching
- Never commit large binaries directly to the repository
- Use appropriate secret-gated access for sensitive assets

## Getting Help

- File issues on [GitHub Issues](https://github.com/spiralgang/FileSystemds/issues)
- Check existing documentation in this `docs/` directory
- Review the [Mobile Platform README](../README_MOBILE.md) for platform-specific information