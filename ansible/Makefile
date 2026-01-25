.PHONY: help install check deploy deploy-single dry-run verify

# Default target
help:
	@echo "Ansible setup for Proxmox hosts"
	@echo ""
	@echo "Targets:"
	@echo "  make install      - Install Ansible dependencies"
	@echo "  make check        - Check connectivity to hosts"
	@echo "  make deploy       - Deploy to all proxmox hosts"
	@echo "  make deploy-single HOST=10.10.11.47 - Deploy to specific host"
	@echo "  make dry-run      - Run playbook in check mode (no changes)"
	@echo "  make verify       - Verify installation on hosts"
	@echo ""

# Install Ansible
install:
	pip install -r requirements.txt

# Check connectivity
check:
	ansible proxmox -i inventory/proxmox.ini -m ping

# Deploy to all hosts
deploy:
	ansible-playbook -i inventory/proxmox.ini playbooks/setup-proxmox-root.yml

# Deploy to single host
deploy-single:
	@if [ -z "$(HOST)" ]; then \
		echo "Error: HOST variable not set"; \
		echo "Usage: make deploy-single HOST=10.10.11.47"; \
		exit 1; \
	fi
	ansible-playbook -i inventory/proxmox.ini playbooks/setup-proxmox-root.yml --limit $(HOST)

# Dry run (check mode)
dry-run:
	ansible-playbook -i inventory/proxmox.ini playbooks/setup-proxmox-root.yml --check --diff

# Verify installation
verify:
	ansible proxmox -i inventory/proxmox.ini -m shell -a "/root/.nix-profile/bin/home-manager --version"
	ansible proxmox -i inventory/proxmox.ini -m shell -a "which fish"
