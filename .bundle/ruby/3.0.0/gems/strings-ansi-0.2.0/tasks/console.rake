# frozen_string_literal: true

desc "Load gem inside irb console"
task :console do
  require "irb"
  require "irb/completion"
  require File.join(__FILE__, "../../lib/strings-ansi")
  ARGV.clear
  IRB.start
end
task c: %w[ console ]
