# Security policy

## Supported versions

Only the latest default-branch version of each plugin is supported. Older plugin releases, forks, and copied agent/skill files are unsupported.

## Private vulnerability reporting

Use GitHub private vulnerability reporting from the repository's **Security** tab, or contact the owner privately through the contact method on the owner's GitHub profile if unavailable. Include affected plugin/script paths, impact, and a minimal proof of concept. Do not include live credentials or private prompt/data content.

Do **not** disclose vulnerabilities through public GitHub issues, discussions, or pull requests before coordinated disclosure.

## Security expectations

- Review plugin, hook, agent, skill, and MCP changes as executable supply-chain changes.
- Use least-privilege OAuth and keep MCP credentials out of the repository.
- Pin and review third-party integrations where supported; review marketplace updates before broad rollout.
- Treat repository and user-provided text as untrusted data in agent workflows.

# Security & Privacy Remediation Backlog

The standard scan found no validated vulnerabilities in the reviewed scope. No remediation work was invented; continue dependency, secret, workflow, plugin-hook, and MCP integration review as the repository evolves.
