# standard library
require 'json'
require 'logger'
require 'pp'
require 'yaml'

# external gems
require 'nokogiri'
require 'progressbar'
require 'thor'

module Mdmm
  autoload :VERSION, 'mdmm/version'
  autoload :CONFIG, 'mdmm/config_reader'
  autoload :LOG, 'mdmm/log'
  # silly way to make Mdmm::WRK_DIR act like a global variable
  autoload :WRK_DIR, 'mdmm/wrk_dir'

  autoload :CommandLine, 'mdmm/command_line'
end
