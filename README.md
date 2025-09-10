




### Legacy README.md

System and Service Manager

[![OBS Packages Status](https://build.opensuse.org/projects/system:systemd/packages/systemd/badge.svg?type=default)](https://build.opensuse.org/project/show/system:systemd)<br/>
[![Semaphore CI 2.0 Build Status](https://the-real-systemd.semaphoreci.com/badges/systemd/branches/main.svg?style=shields)](https://the-real-systemd.semaphoreci.com/projects/systemd)<br/>
[![Coverity Scan Status](https://scan.coverity.com/projects/350/badge.svg)](https://scan.coverity.com/projects/systemd)<br/>
[![OSS-Fuzz Status](https://oss-fuzz-build-logs.storage.googleapis.com/badges/systemd.svg)](https://oss-fuzz-build-logs.storage.googleapis.com/index.html#systemd)<br/>
[![CIFuzz](https://github.com/systemd/systemd/actions/workflows/cifuzz.yml/badge.svg)](https://github.com/systemd/systemd/actions/workflows/cifuzz.yml)</br>
[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/1369/badge)](https://bestpractices.coreinfrastructure.org/projects/1369)<br/>
[![Fossies codespell report](https://fossies.org/linux/test/systemd-main.tar.gz/codespell.svg)](https://fossies.org/linux/test/systemd-main.tar.gz/codespell.html)</br>
[![Translation status](https://translate.fedoraproject.org/widget/systemd/svg-badge.svg)](https://translate.fedoraproject.org/engage/systemd/)</br>
[![Coverage Status](https://coveralls.io/repos/github/systemd/systemd/badge.svg?branch=main)](https://coveralls.io/github/systemd/systemd?branch=main)</br>
[![Packaging status](https://repology.org/badge/tiny-repos/systemd.svg)](https://repology.org/project/systemd/versions)</br>
[![OpenSSF Scorecard](https://api.securityscorecards.dev/projects/github.com/systemd/systemd/badge)](https://securityscorecards.dev/viewer/?platform=github.com&org=systemd&repo=systemd)

## Userland Apps Integration

FileSystemds includes a next-generation userland-apps MobileOps platform that delivers secure, robust installation and management of applications and development environments. This industry-benchmark system provides enterprise-grade application management capabilities.

### Quick Start

```bash
# Install and launch R statistical computing environment
./tools/userland-apps/r-lang

# Install Git GUI interface  
./tools/userland-apps/git-gui

# Install and play Zork text adventure game
./tools/userland-apps/zork
```

### Features

- **Security**: Input validation, secure privilege escalation, concurrent execution safety
- **Reliability**: Idempotent operations, comprehensive error handling, detailed logging
- **Portability**: OS detection, multi-distribution support, POSIX compliance
- **Testing**: Comprehensive test suite with security and functionality validation

### Documentation

- Complete usage guide: [docs/userland-apps.md](docs/userland-apps.md)
- Application metadata: [data/apps.csv](data/apps.csv)
- Asset inventory: [share/assets/manifest.csv](share/assets/manifest.csv)

### Testing

```bash
# Run complete userland-apps test suite
./tests/userland-apps/test-userland-apps.sh

# Test individual tools
./tools/userland-apps/r-lang --help
./tools/userland-apps/git-gui --version
```

## Details

Most documentation is available on [systemd's web site](https://systemd.io/).

Assorted, older, general information about systemd can be found in the [systemd Wiki](https://www.freedesktop.org/wiki/Software/systemd).

Information about build requirements is provided in the [README file](README).

Consult our [NEWS file](NEWS) for information about what's new in the most recent systemd versions.

Please see the [Code Map](docs/ARCHITECTURE.md) for information about this repository's layout and content.

Please see the [Hacking guide](docs/HACKING.md) for information on how to hack on systemd and test your modifications.

Please see our [Contribution Guidelines](docs/CONTRIBUTING.md) for more information about filing GitHub Issues and posting GitHub Pull Requests.

When preparing patches for systemd, please follow our [Coding Style Guidelines](docs/CODING_STYLE.md).

If you are looking for support, please contact our [mailing list](https://lists.freedesktop.org/mailman/listinfo/systemd-devel), join our [IRC channel #systemd on libera.chat](https://web.libera.chat/#systemd) or [Matrix channel](https://matrix.to/#/#systemd-project:matrix.org)

Stable branches with backported patches are available in the [stable repo](https://github.com/systemd/systemd-stable).

We have a security bug bounty program sponsored by the [Sovereign Tech Fund](https://www.sovereigntechfund.de/) hosted on [YesWeHack](https://yeswehack.com/programs/systemd-bug-bounty-program)

Repositories with distribution packages built from git main are [available on OBS](https://software.opensuse.org//download.html?project=system%3Asystemd&package=systemd)
