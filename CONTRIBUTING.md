# Contributing to Cisco Catalyst Center PNP Automation

Thank you for your interest in contributing to this project! This document provides guidelines for contributing.

## How to Contribute

### Reporting Issues

If you find a bug or have a suggestion:

1. Check if the issue already exists in [GitHub Issues](https://github.com/ters-golemi/ccc-pnp-c8000v/issues)
2. If not, create a new issue with:
   - Clear title and description
   - Steps to reproduce (for bugs)
   - Expected vs actual behavior
   - Environment details (OS, Python version, Catalyst Center version)
   - Relevant logs or screenshots

### Suggesting Enhancements

Enhancement suggestions are welcome! Please:

1. Check existing issues and pull requests
2. Create an issue describing:
   - The enhancement and its benefits
   - Use cases
   - Possible implementation approach

### Pull Requests

We welcome pull requests! Here's how to contribute code:

#### 1. Fork and Clone

```bash
# Fork the repository on GitHub
# Clone your fork
git clone https://github.com/YOUR_USERNAME/ccc-pnp-c8000v.git
cd ccc-pnp-c8000v
```

#### 2. Create a Branch

```bash
# Create a feature branch
git checkout -b feature/your-feature-name

# Or for bug fixes
git checkout -b fix/your-bug-fix
```

#### 3. Make Changes

- Follow the existing code style
- Add comments for complex logic
- Update documentation if needed
- Test your changes thoroughly

#### 4. Test Your Changes

```bash
# Activate virtual environment
source venv/bin/activate

# Run syntax checks
python3 -m py_compile scripts/*.py

# Test with your Catalyst Center (if available)
python3 scripts/pnp_monitor.py --config configs/config.yml --list-all
```

#### 5. Commit Your Changes

```bash
# Add changed files
git add .

# Commit with descriptive message
git commit -m "Add feature: description of your change"
```

Follow commit message conventions:
- Use present tense ("Add feature" not "Added feature")
- Keep first line under 50 characters
- Add detailed description in subsequent lines if needed

#### 6. Push and Create Pull Request

```bash
# Push to your fork
git push origin feature/your-feature-name
```

Then create a Pull Request on GitHub with:
- Clear title and description
- Reference any related issues
- List of changes made
- Testing performed

## Development Guidelines

### Code Style

#### Python
- Follow PEP 8 style guide
- Use meaningful variable names
- Add docstrings to functions and classes
- Keep functions focused and concise

Example:
```python
def get_device_by_serial(serial_number):
    """
    Get PNP device by serial number
    
    Args:
        serial_number (str): Device serial number
        
    Returns:
        dict: Device information or None if not found
    """
    # Implementation
    pass
```

#### YAML
- Use 2 spaces for indentation
- Use quotes for strings with special characters
- Add comments for complex configurations

#### Shell Scripts
- Use bash shebang: `#!/bin/bash`
- Add error handling: `set -e`
- Use meaningful variable names
- Add comments for complex logic

### Documentation

When adding features:
- Update README.md if needed
- Add examples to documentation
- Update QUICK_START.md for user-facing changes
- Add troubleshooting tips to TROUBLESHOOTING.md

### Testing

Before submitting:
- Test with different Python versions (3.8+)
- Test error handling
- Verify documentation is accurate
- Check for typos and formatting

### File Organization

Place new files in appropriate directories:
- Python scripts → `scripts/`
- Ansible playbooks → `ansible/playbooks/`
- Configuration examples → `configs/`
- Documentation → `docs/`

## What We're Looking For

Contributions that are particularly welcome:

### Features
- Additional API wrapper functions
- Bulk device operations
- Enhanced error handling
- Template management scripts
- Integration with other tools

### Documentation
- More examples and use cases
- Tutorial videos or guides
- Translations
- Architecture diagrams

### Testing
- Unit tests
- Integration tests
- Test fixtures and mocks

### Bug Fixes
- Fix reported issues
- Improve error messages
- Handle edge cases

## Code Review Process

1. Maintainers will review your pull request
2. May request changes or clarifications
3. Once approved, changes will be merged
4. Your contribution will be credited

## Community Guidelines

- Be respectful and constructive
- Help others in issues and discussions
- Follow the code of conduct
- Give credit where it's due

## Getting Help

If you need help:
- Ask in GitHub Discussions
- Reference documentation in `docs/`
- Check existing issues and PRs
- Reach out to maintainers

## Development Setup

### Full Development Environment

```bash
# Clone repository
git clone https://github.com/ters-golemi/ccc-pnp-c8000v.git
cd ccc-pnp-c8000v

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Install development dependencies
pip install pytest pytest-cov pylint black

# Run linter
pylint scripts/*.py

# Format code
black scripts/*.py
```

### Pre-commit Checks

Before committing, run:

```bash
# Check Python syntax
python3 -m py_compile scripts/*.py

# Check YAML syntax
python3 -c "import yaml; yaml.safe_load(open('configs/config.example.yml'))"

# Check shell scripts
bash -n scripts/*.sh

# Check documentation links (if markdown checker available)
markdown-link-check README.md
```

## Project Structure

When contributing, understand the project structure:

```
ccc-pnp-c8000v/
├── scripts/           # Python automation scripts
├── ansible/           # Ansible playbooks and configs
├── configs/           # Configuration templates
├── docs/             # Additional documentation
├── README.md         # Main documentation
├── QUICK_START.md    # Quick start guide
├── CONTRIBUTING.md   # This file
└── requirements.txt  # Python dependencies
```

## Versioning

This project follows semantic versioning (SemVer):
- MAJOR version for incompatible API changes
- MINOR version for backwards-compatible functionality
- PATCH version for backwards-compatible bug fixes

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

## Recognition

Contributors will be:
- Listed in the project's contributors
- Credited in release notes
- Acknowledged in the README (for significant contributions)

## Questions?

If you have questions about contributing:
- Open a discussion on GitHub
- Check existing documentation
- Ask in the issue comments

Thank you for contributing to make PNP automation better!
