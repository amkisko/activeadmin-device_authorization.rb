.PHONY: lint audit test clean

lint:
	@echo "No linter configured yet"

audit:
	bundle exec bundler-audit check || true

test:
	bundle exec rspec

clean:
	rm -rf coverage .pray/cache tmp
	rm -f spec/examples.txt *.gem
