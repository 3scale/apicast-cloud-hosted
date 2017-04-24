
.DEFAULT_GOAL := help

Gemfile.lock: Gemfile
	bundle check || bundle install

t/servroot:
	mkdir -p $@

nginx: ## Start nginx in foreground
nginx: t/servroot
	openresty -p t/servroot -c $(PWD)/nginx.conf -g 'daemon off;'

.env:
	cp $@.example $@

busted: ## Run busted tests
busted: .env
	bundle exec dotenv bin/busted

prove: ## Run Test::Nginx
prove: Gemfile.lock .env
	TEST_NGINX_BINARY=openresty bundle exec dotenv prove

build: ## Build docker image
	docker build .

target: ## Install deps
	cd apicast && make dependencies

# Check http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
help: ## Print this help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
