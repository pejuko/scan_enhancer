# -*- coding: utf-8 -*-
# vi: fenc=utf-8:expandtab:ts=2:sw=2:sts=2
# 
# Description of the module/program
#
# Author::    Petr Kovar (mailto:pejuko@gmail.com)
# Copyright:: Copyright (c) 2011 Petr Kovář
# License::   Distributes under the same terms as Ruby

require 'yard'

desc "Generate YARD documentation"
YARD::Rake::YardocTask.new do |t|
  t.files = $DOC_FILES
  t.options = ['--output-dir=yardoc']
end
