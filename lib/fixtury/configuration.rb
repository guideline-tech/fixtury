require "digest"

module Fixtury
  # Provides an interface for managing settings and dependencies related to fixture
  # generation.
  class Configuration

    attr_reader :filepath, :fixture_files, :dependency_files

    def initialize
      @filepath = nil
      @fixture_files = Set.new
      @dependency_files = Set.new
    end

    def log_level
      return @log_level if @log_level

      @log_level = ENV["FIXTURY_LOG_LEVEL"]
      @log_level ||= DEFAULT_LOG_LEVEL
      @log_level = @log_level.to_s.to_sym
      @log_level
    end

    # Delete the storage file if it exists.
    def reset
      File.delete(filepath) if filepath && File.file?(filepath)
    end

    # Set the location of the storage file. The storage file will maintain
    # checksums of all tracked files and serialized references to fixtures.
    #
    # @param path [String] The path to the storage file.
    def filepath=(path)
      @filepath = path.to_s
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

    # The references stored in the dependency file. When stores are initialized
    # these will be used to bootstrap the references.
    #
    # @return [Hash] The references stored in the dependency file.
    def stored_references
      return {} if stored_data.nil?

      stored_data[:references] || {}
    end

    # Dump the current state of the dependency manager to the storage file.
    def dump_file
      return unless filepath

      FileUtils.mkdir_p(File.dirname(filepath))
      File.binwrite(filepath, file_data.to_yaml)
    end

    private

    def file_data
      checksums = {}
      calculate_checksums do |filepath, checksum|
        checksums[filepath] = checksum
      end

      {
        dependencies: checksums,
        references: ::Fixtury.store.references,
      }
    end

    def stored_data
      return nil unless filepath
      return nil unless File.file?(filepath)

      YAML.unsafe_load_file(filepath)
    end

    def files_changed?
      return true if stored_data.nil?

      stored_checksums = (stored_data[:dependencies] || {})
      seen_filepaths = []
      calculate_checksums do |filepath, checksum|
        # Early return if the checksums don't match
        return true unless stored_checksums[filepath] == checksum

        seen_filepaths << filepath
      end

      # If we have a new file or a file has been removed, we need to report a change.
      seen_filepaths.sort != stored_checksums.keys.sort
    end

    def calculate_checksums(&block)
      (fixture_files.to_a | dependency_files.to_a).sort.each do |filepath|
        yield filepath, Digest::MD5.file(filepath).hexdigest
      end
    end


  end
end
