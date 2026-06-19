<p align="center">
  <picture>
    <source srcset="packages/console/app/src/asset/logo-ornate-dark.svg" media="(prefers-color-scheme: dark)">
    <source srcset="packages/console/app/src/asset/logo-ornate-light.svg" media="(prefers-color-scheme: light)">
    <img src="packages/console/app/src/asset/logo-ornate-light.svg" alt="Rimuru AI logo">
  </picture>
</p>
<p align="center">The open source AI coding agent.</p>
<p align="center">
  <a href="https://www.npmjs.com/package/rimuru-ai"><img alt="npm version" src="https://img.shields.io/npm/v/rimuru-ai?style=flat-square" /></a>
  <a href="https://github.com/gowdaman-dev/rimuru-ai/actions/workflows/publish-npm.yml"><img alt="Build status" src="https://img.shields.io/github/actions/workflow/status/gowdaman-dev/rimuru-ai/publish-npm.yml?style=flat-square&branch=dev" /></a>
</p>

<p align="center">
  <a href="README.md">English</a>
</p>

---

## Installation

### Linux & macOS

```bash
curl -fsSL https://raw.githubusercontent.com/gowdaman-dev/rimurucode-ai/main/install | bash
```

### Windows

**PowerShell:**
```powershell
irm https://raw.githubusercontent.com/gowdaman-dev/rimurucode-ai/main/install.ps1 | iex
```

**Git Bash / WSL:**
```bash
curl -fsSL https://raw.githubusercontent.com/gowdaman-dev/rimurucode-ai/main/install | bash
```

### npm (All Platforms)

```bash
npm install -g rimuru-ai@latest
```

### What Gets Installed

| Path | Contents |
|------|----------|
| `~/.rimuru/bin/rimuru` | CLI binary |
| `~/.config/rimuru/agents/` | 30 agent definitions (Veldora tiers + specialists) |
| `~/.config/rimuru/commands/` | Built-in slash commands |
| `~/.config/rimuru/skills/` | Reusable skill modules |
| `~/.config/rimuru/opencode.jsonc` | Agent registrations, plugins, MCP config |

---

## Desktop App (BETA)

Rimuru AI is also available as a desktop application. Download from the [releases page](https://github.com/gowdaman-dev/rimuru-ai/releases).

| Platform | Download |
|----------|----------|
| macOS (Apple Silicon) | `rimuru-desktop-mac-arm64.dmg` |
| macOS (Intel) | `rimuru-desktop-mac-x64.dmg` |
| Windows | `rimuru-desktop-windows-x64.exe` |
| Linux | `.deb`, `.rpm`, or `.AppImage` |

---

## Agent Architecture

Rimuru AI ships with **Veldora** and **Veldora-Pro** — two hierarchically organized meta-agent tiers plus a documentation specialist.

### Primary Agents

| Agent | Tier | Role |
|-------|------|------|
| `veldora` | Base | General-purpose meta-agent — routes tasks to specialist subagents, improves Rimuru setup (configs, plugins, MCPs, token efficiency) |
| `veldora-pro` | Pro | Unrestricted meta-agent — same as veldora with `bash:allow` (no confirmations). Directly applies changes |
| `veldora-doc` | Docs | Documentation specialist — creates, reviews, formats, and maintains all project documentation |

### Veldora Base Tier — Development Pipeline

```
FrontCraft → BackForge → DataVault → PipelineForge
```

| Subagent | Alias | Scope |
|----------|-------|-------|
| `veldora-frontend-dev` | FrontCraft | UI components, responsive layouts, design systems, WCAG accessibility |
| `veldora-backend-dev` | BackForge | REST/GraphQL APIs, auth flows, business logic, service integration |
| `veldora-database` | DataVault | Schema design, migrations, query optimization, indexing, deployment |
| `veldora-cicd` | PipelineForge | CI/CD pipelines, Docker, Kubernetes, rollback strategies |

### Veldora Base Tier — Agentic Pipeline

```
PromptAlchemist → AgentSmith → MCPForge → SkillForge
```

| Subagent | Alias | Scope |
|----------|-------|-------|
| `veldora-prompt-enhancer` | PromptAlchemist | Prompt analysis, rewriting, scoring, few-shot construction |
| `veldora-agent-tool-dev` | AgentSmith | Agent design, tool binding, loop architecture, multi-agent coordination |
| `veldora-mcp-creator` | MCPForge | MCP server/client configs, tool schemas, auth configuration |
| `veldora-skill-creator` | SkillForge | Reusable skill definitions, trigger design, versioning |

### Veldora Base Tier — Evolutionary Core

| Subagent | Alias | Role |
|----------|-------|------|
| `veldora-great-sage` | Great Sage | Absorbs every task outcome, analyzes errors, writes corrective KB rules, prevents recurrence across ALL subagents |

### Veldora Pro Tier — Advanced Development Pipeline

| Subagent | Alias | Pro Features |
|----------|-------|-------------|
| `veldorapro-frontend-dev` | FrontCraft Pro | Multi-framework output (React/Vue/Web Components), design system generation, Storybook, performance auditing |
| `veldorapro-backend-dev` | BackForge Pro | Microservices design, event-driven patterns, OpenAPI 3.0, rate-limiting middleware |
| `veldorapro-database` | DataVault Pro | Polyglot persistence, sharding/replication, query analysis, disaster recovery |
| `veldorapro-cicd` | PipelineForge Pro | Multi-env pipelines, security scanning (SAST/DAST), blue-green/canary, IaC generation |

### Veldora Pro Tier — Advanced Agentic Pipeline

| Subagent | Alias | Pro Features |
|----------|-------|-------------|
| `veldorapro-prompt-enhancer` | PromptAlchemist Pro | Multi-model optimization (GPT-4/Claude/Gemini/Mistral), adversarial patching, prompt compression |
| `veldorapro-agent-tool-dev` | AgentSmith Pro | Hierarchical multi-agent systems, evaluation harness, memory architecture, Rimuru-native config |
| `veldorapro-mcp-creator` | MCPForge Pro | Multi-server orchestration, dynamic tool discovery, streaming support |
| `veldorapro-skill-creator` | SkillForge Pro | Skill composition, conflict detection, benchmarking, marketplace manifests |

### Veldora Pro Tier — Supreme Evolutionary Core

| Subagent | Alias | Role |
|----------|-------|------|
| `veldorapro-great-sage` | Raphael | Cross-domain synthesis, predictive correction, rule evolution, capability forecasting, system health scoring |

### Generalist Subagents

| Subagent | Scope |
|----------|-------|
| `backend` | API development, business logic, auth |
| `database` | Schema design, migrations, queries |
| `frontend` | React/Vue/Angular, CSS, a11y |
| `fullstack` | End-to-end feature implementation |
| `devops` | CI/CD, containers, K8s, Terraform |
| `system-engineer` | Server admin, networking, performance |
| `ethical-hacking` | Penetration testing, OWASP/MITRE ATT&CK |
| `document-prep` | PDF, LibreOffice, DOCX generation |
| `erp-architect` | SAP, Oracle NetSuite, Odoo, Dynamics 365 |

---

## Great Sage Protocol

Inspired by Rimuru Tempest's Great Sage ability from *Tensei Shitara Slime Datta Ken*, every subagent's output flows through the Great Sage evolutionary core:

```
ABSORB → ANALYZE → EVOLVE → PREVENT
```

- **ABSORB**: Full task traces from every subagent execution
- **ANALYZE**: Classify outcomes as errors, inefficiencies, success patterns, or new capabilities
- **EVOLVE**: Write corrective rules to the persistent knowledge base (`great_sage/rules/`)
- **PREVENT**: Inject proactive corrections before future tasks so errors never recur

The Great Sage runs silently beneath every other agent process — the system learns from every interaction and never repeats a failure it has already absorbed.

---

## Project Status

This is the main repository for Rimuru AI — an AI-powered development tool. It is actively developed with enhanced MCP server integration, expanded agent system, and custom identity/logo.

## Documentation

For configuration details, refer to the project-level `.rimuru/` configuration files in this repo or visit [rimurucode.vercel.app/docs](https://rimurucode.vercel.app/docs).

## Contributing

Interested in contributing? Check the [contributing docs](./CONTRIBUTING.md) before submitting a pull request.

---
