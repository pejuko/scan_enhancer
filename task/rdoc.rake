# -*- coding: utf-8 -*-
# vi: fenc=utf-8:expandtab:ts=2:sw=2:sts=2
# 
# Description of the module/program
#
# Author::    Petr Kovar (mailto:pejuko@gmail.com)
# Copyright:: Copyright (c) 2011 Petr Kovář
# License::   Distributes under the same terms as Ruby

require 'rake/rdoctask'

desc "Generate RDoc documentation"
Rake::RDocTask.new(:rdoc) do |t|
  t.main = "README.md"
  t.rdoc_dir = "rdoc/"
  t.rdoc_files.include $DOC_FILES
  #t.options << "-a  -d -x spec/ -x test/ -U -S -N -o doc/rdoc/ -p -w 2"
  t.options = %w(-a  -d -x spec/ -x test/ -U -S -N -p -w 2)
end

