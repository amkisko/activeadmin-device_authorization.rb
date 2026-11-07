.PHONY: release lint audit test clean

release:
	ruby usr/bin/release.rb

lint:
	bundle exec rubocop
	bundle exec rbs validate
	ruby usr/bin/check_locale_parity.rb
	ruby usr/bin/check_loc.rb

audit:
	@for lock in Gemfile.lock gemfiles/*.gemfile.lock; do \
		if [ "$${lock}" = "gemfiles/rails72.gemfile.lock" ]; then \
			echo "==> $${lock} (skip: Rails 7.2 has no published fix yet; see docs/dependencies/20261107120000_rails-72-unpatched-advisories.md)"; \
			continue; \
		fi; \
		echo "==> $${lock}"; \
		bundle exec bundler-audit check --gemfile-lock "$${lock}" || exit 1; \
	done

test: lint
	bundle exec polyrun parallel-rspec --workers 5 --merge-failures

clean:
	rm -rf coverage .pray/cache tmp
	rm -f spec/examples.txt *.gem
