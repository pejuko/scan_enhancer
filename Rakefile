# -*- coding: utf-8 -*-
# vi: fenc=utf-8:expandtab:ts=2:sw=2:sts=2
# 
# Description of the module/program
#
# Author::    Petr Kovar (mailto:pejuko@gmail.com)
# Copyright:: Copyright (c) 2011 Petr Kovář
# License::   Distributes under the same terms as Ruby

require 'rubygems'
require 'rake'
require 'rake/clean'

CLEAN << "*~" << "coverage" << "pkg" << "README.html" << "CHANGELOG.html" << "*.rbc" << "rdoc/" << "yardoc/"

$DOC_FILES = %w(README.md lib/**/*.rb bin/*)

$:.unshift(File.expand_path File.dirname(__FILE__))
Dir["task/**/*.rake"].each do |rake_task|
  load rake_task
end
