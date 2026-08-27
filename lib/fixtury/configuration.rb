require "digest"

module Fixtury
  # Provides an interface for managing settings and dependencies related to fixture
  # generation.
  class Configuration

    attr_reader :fixture_files, :dependency_files, :locator_backend
    attr_accessor :filepath, :reference_ttl, :strict_dependencies

    def initialize
      @fixture_files = Set.new
      @dependency_files = Set.new
      @locator_backend = :memory
      @strict_dependencies = true
    end

    def log_level
      return @log_level if @log_level

      @log_level = ENV["FIXTURY_LOG_LEVEL"]
      @log_level ||= DEFAULT_LOG_LEVEL
      @log_level = @log_level.to_s.to_sym
      @log_level
    end

    def log_level=(level)
      @log_level = level.to_s.to_sym
    end

    def locator_backend=(backend)
      @locator_backend = backend.to_sym
    end

    # Delete the storage file(s) if they exist. Named store files are discovered by
    # globbing the filesystem (e.g. tmp/fixtury.yml and tmp/fixtury.*.yml) so files
    # from stores not instantiated in this process are removed as well.
    def reset
      persisted_filepaths.each { |path| File.delete(path) if File.file?(path) }
    end

    # The file backing the references of the given store. The default store
    # uses the configured filepath directly while named stores embed their name
    # in the filename. e.g. tmp/fixtury.yml => tmp/fixtury.my_cache.yml
    #
    # @param name [Symbol, String] The name of the store.
    # @return [String, nil] The filepath for the given store, nil if no filepath is configured.
    def store_filepath(name = :default)
      name = (name || :default).to_sym
      return filepath if name == :default
      return nil unless filepath

      ext = File.extname(filepath)
      File.join(File.dirname(filepath), "#{File.basename(filepath, ext)}.#{name}#{ext}")
    end

    # Add a file or glob pattern to the list of fixture files.
    #
    # @param path_or_globs [String, Array<String>] The file or glob pattern(s) to add.
    def add_fixture_path(*path_or_globs)
      @fixture_files = fixture_files | Dir[*path_or_globs]
    end
    alias add_fixture_paths add_fixture_path

    # Add a file or glob pattern to the list of dependency files.
    #
    # @param path_or_globs [String, Array<String>] The file or glob pattern(s) to add.
    def add_dependency_path(*path_or_globs)
      @dependency_files = dependency_files | Dir[*path_or_globs]
    end
    alias add_dependency_paths add_dependency_path

    # The references stored in the file backing the given store. When stores are
    # initialized these will be used to bootstrap the references.
    #
    # @param name [Symbol, String] The name of the store.
    # @return [Hash] The references stored in the store's file.
    def stored_references(name = :default)
      data = stored_data(store_filepath(name))
      return {} if data.nil?

      data[:references] || {}
    end

    # Dump the current state of the dependency manager to the storage files.
    # Each instantiated store is dumped to the file associated with its name.
    def dump_file
      return unless filepath

      ::Fixtury.store # ensure the default store is present
      ::Fixtury.stores.each_value do |store|
        path = store_filepath(store.name)
        next unless path

        FileUtils.mkdir_p(File.dirname(path))
        File.binwrite(path, file_data(store.references).to_yaml)
      end
    end

    def changes
      return "new: #{filepath}" if stored_data.nil?

      stored_checksums = (stored_data[:dependencies] || {})
      seen_filepaths = []
      calculate_checksums do |filepath, checksum|
        # Early return if the checksums don't match
        return "change: #{filepath}" unless stored_checksums[filepath] == checksum

        seen_filepaths << filepath
      end

      # If we have a new file or a file has been removed, we need to report a change.
      new_files = seen_filepaths - stored_checksums.keys
      return "added: #{new_files.inspect}" if new_files.any?

      removed_files = stored_checksums.keys - seen_filepaths
      return "removed: #{removed_files.inspect}" if removed_files.any?

      nil
    end


    private

    def file_data(references)
      checksums = {}
      calculate_checksums do |filepath, checksum|
        checksums[filepath] = checksum
      end

      {
        dependencies: checksums,
        references: references,
      }
    end

    def stored_data(path = filepath)
      return nil unless path
      return nil unless File.file?(path)

      YAML.unsafe_load_file(path)
    end

    # All storage files currently on disk: the configured filepath plus any
    # named store files matching its naming pattern.
    def persisted_filepaths
      return [] unless filepath

      ext = File.extname(filepath)
      glob = File.join(File.dirname(filepath), "#{File.basename(filepath, ext)}.*#{ext}")
      [filepath, *Dir[glob]]
    end

    def calculate_checksums(&block)
      (fixture_files.to_a | dependency_files.to_a).sort.each do |filepath|
        yield filepath, Digest::MD5.file(filepath).hexdigest
      end
    end


  end
end
