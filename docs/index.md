---
layout: default
SPDX-License-Identifier: LGPL-2.1-or-later
---

# FileSystemds Mobile Platform

FileSystemds is a modular, agent-driven orchestration system designed for modern mobile/cloud-first environments. Built from highly modified foundations, it's evolving into a next-generation platform for mobile operations.

## Key Features

- **Modular Architecture**: Replaceable components instead of monolithic design
- **Agent-Driven Workflows**: Event-driven, API-first automation for both human and non-human contributors
- **Mobile/Cloud/Edge Ready**: Cross-platform, stateless design optimized for modern environments
- **Pointer-First Artifact Management**: Secure, audited handling of large assets and models
- **Observable & Testable**: Structured logging, metrics, and comprehensive testing

## Getting Started

For complete installation and usage instructions, see the [Mobile Platform Documentation](../README_MOBILE.md).

## Documentation Categories

{% assign by_category = site.pages | group_by:"category" %}
{% assign extra_pages = site.data.extra_pages | group_by:"category" %}
{% assign merged = by_category | concat: extra_pages | sort:"name" %}

{% for pair in merged %}
  {% assign category = pair.name %}
  {% if category != "" %}

### {{ category }}

    {% assign sorted_pages = pair.items | sort: "title" %}
    {% for page in sorted_pages %}
      {% if page.title and page.title != "" %}
* [{{ page.title }}]({{ page.url | relative_url }})
      {% endif %}
    {% endfor %}
  {% endif %}
{% endfor %}

## Architecture Overview

FileSystemds represents a transition from legacy personal computing software to a modern, modular platform. The architecture emphasizes:

- **Modular Services**: Each major feature is a replaceable module
- **API-First Design**: All functionality is accessible via clean APIs
- **Event-Driven Operations**: Reactive, autonomous workflows
- **Mobile-First Principles**: Optimized for mobile and edge computing environments

For detailed architectural information, see the [Architecture Documentation](ARCHITECTURE.md).

## Contributing

We welcome contributions that advance our modular, agent-driven vision. See our [Contributing Guidelines](CONTRIBUTING.md) for details on how to get involved.