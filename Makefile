.PHONY: help check init clean download upload ansible apply destroy plan
.DEFAULT_GOAL: help
.PRECIOUS: imports.tf terraform.tfvars

CMD=$(shell which tofu || which terraform)
ECHO=$(shell which figlet || which echo)

.gitignore:
	curl https://www.toptal.com/developers/gitignore/api/terraform,visualstudiocode,direnv > $@

.git: .gitignore
	git init

init: check .terraform ## Fetch files from S3 and init

download: clean imports.tf terraform.tfvars ## Refetch the imports and vars

help: ## Display this help
	@$(ECHO) Infrastructure
	@echo Options:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
	@echo
	@cat README.md

.terraform: imports.tf terraform.tfvars
	$(CMD) init \
		-backend-config="key=${TERAFORM_BUCKET_PATH}/state.tfstate" \
		-backend-config="bucket=${TERAFORM_BUCKET}" \
		-backend-config="region=${TERAFORM_BUCKET_REGION}"
	@touch $@

imports.tf:
	@aws s3 cp s3://${TERAFORM_BUCKET}/${TERAFORM_BUCKET_PATH}/$@ . || touch $@

terraform.tfvars:
	@aws s3 cp s3://${TERAFORM_BUCKET}/${TERAFORM_BUCKET_PATH}/$@ . || touch $@

upload: imports.tf terraform.tfvars
	@for f in $^; do aws s3 cp $$f s3://${TERAFORM_BUCKET}/${TERAFORM_BUCKET_PATH}/$$f; done

check: ## Check the env vars are set
ifndef TERAFORM_BUCKET
	$(error "TERAFORM_BUCKET is required!")
endif
ifndef TERAFORM_BUCKET_REGION
	$(error "TERAFORM_BUCKET_REGION is required!")
endif
ifndef TERAFORM_BUCKET_PATH
	$(error "TERAFORM_BUCKET_PATH is required!")
endif

check_jq:
	@if ! command -v jq >/dev/null 2>&1; then \
		echo "jq is not installed!"; exit 1; \
	fi

clean: ## Remove fetched files
	@rm -f imports.tf terraform.tfvars

apply: check .terraform ## Apply the terraform
	$(CMD) apply

destroy: check .terraform ## Destroy the terraform
	$(CMD) destroy

plan: check .terraform ## Plan the terraform
	$(CMD) plan

inventory.ini: ## Generate the inventory
	$(CMD) output -json | jq -r '. | to_entries | map("[webservers]\n\(.value.value)") | .[]' > $@

ansible: inventory.ini playbooks/roles/server/files/id_rsa.pub check_jq ## Run ansible
	ansible-playbook -i inventory.ini playbooks/main.yml

playbooks/roles/server/files/id_rsa.pub:
	mkdir -p $(dir $@)
	cp ~/.ssh/id_rsa.pub $@

tf_outputs.json:
	$(CMD) output -json > $@

post-setup: tf_outputs.json inventory.ini playbooks/roles/server/files/id_rsa.pub ## Run post playbook
	ansible-playbook -i inventory.ini playbooks/post.yml
