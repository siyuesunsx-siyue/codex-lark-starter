# Security Policy

## Supported Versions

Only the latest release on the default branch receives security patches.

| Version | Supported |
|---------|-----------|
| latest (main branch) | Yes |
| all previous versions | No |

## Reporting a Vulnerability

**Do not open a public issue.**

Send an email to the project maintainers describing the vulnerability.
Include:

- A clear description of the issue.
- Steps to reproduce (if applicable).
- Affected files or components.
- Any suggested fixes you may have.

You will receive an acknowledgment within **48 hours** and a status update
within **5 business days**.

## Scope

Issues in scope:

- Shell scripts that handle user input, environment variables, or file
  paths.
- Configuration files that could expose credentials if mishandled.
- Documentation that recommends insecure practices.
- GitHub Actions workflows that could leak secrets.

Issues out of scope:

- Vulnerabilities in third-party tools (Node.js, Codex CLI, OpenAI API).
  Report those to their respective projects.
- Theoretical attacks requiring physical access to the machine.
- Social engineering or phishing.

## Best Practices for Users

1. **Never commit `config.json`.**  It is listed in `.gitignore` and
   contains your API keys.
2. **Rotate your Feishu App Secret and OpenAI API key periodically.**
3. **Run the bridge behind a firewall.**  By default it binds to
   `127.0.0.1`.  Do not change this to `0.0.0.0` unless you understand
   the implications.
4. **Audit the install scripts before running them.**  All scripts are
   short and documented.  Read them.
5. **Keep your system updated.**  Run `sudo apt update && sudo apt
   upgrade` (or equivalent) regularly.

## Acknowledgments

We maintain a list of security researchers and contributors who have
responsibly disclosed vulnerabilities.  Thank you for helping keep this
project safe.
