require 'mdmm'

module Mdmm
  class ConfigReader
    attr_reader :wrk_dir
    attr_reader :logfile
    attr_reader :colls

    def initialize
      config = YAML.load_file('config/config.yaml')
      @wrk_dir = config['wrk_dir']
      @logfile = config['logfile']
      @colls = Dir.children(@wrk_dir).select{ |n| File.directory?("#{@wrk_dir}/#{n}") }
    end
  end

  CONFIG = Mdmm::ConfigReader.new
end
