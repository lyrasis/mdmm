require 'mdmm'

module Mdmm
  LOG = Logger.new(File.expand_path(Mdmm::CONFIG.logfile))
end
