module LicenseFinder
  class DependencyList

    attr_reader :dependencies

    def self.from_bundler(whitelist = [])
      new(Bundler.load.specs.map { |spec| GemSpecDetails.new(spec, whitelist).dependency })
    end

    def initialize(dependencies)
      @dependencies = dependencies
    end

    def self.from_yaml(yml)
      deps = YAML.load(yml)
      new(deps.map { |dhash| Dependency.from_hash(dhash) })
    end

    def merge(new_list)
      deps = new_list.dependencies.map do |new_dep|
        old_dep = self.dependencies.detect { |d| d.name == new_dep.name }
        if old_dep && old_dep.license == new_dep.license
          Dependency.new(new_dep.name, new_dep.version, new_dep.license, old_dep.approved || new_dep.approved)
        else
          new_dep
        end
      end

      self.class.new(deps)
    end

    def to_yaml
      result = "--- \n"
      dependencies.sort_by(&:name).inject(result) { |r, d| r << d.to_yaml_entry; r }
    end

    def to_s
      dependencies.sort_by(&:name).map(&:to_s).join("\n")
    end

    def action_items
      dependencies.sort_by(&:name).reject(&:approved).map(&:to_s).join("\n")
    end
  end
end

