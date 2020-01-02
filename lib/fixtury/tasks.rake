# frozen_string_literal: true

namespace :fixtury do
  task :setup

  desc "Clear fixtures from your cache. Accepts a pattern or fixture name such as foo/bar or /foo/*. Default pattern is /*"
  task :clear_cache, [:pattern] => :setup do |_t, args|
    ::Fixtury::Store.instance.clear_cache!(pattern: args[:pattern])
  end
end
