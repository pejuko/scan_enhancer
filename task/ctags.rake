# -*- coding: utf-8 -*-
# vi: fenc=utf-8:expandtab:ts=2:sw=2:sts=2
# 
# update ctags
#
# Author::    Petr Kovar (mailto:pejuko@gmail.com)
# Copyright:: Copyright (c) 2011 Petr Kovář
# License::   Distributes under the same terms as Ruby

RUBY_FILES = %w(bin/scan_enhancer lib/*.rb lib/**/*.rb)
desc "Update tags using ctags"
task :ctags do |t|
  system("ctags #{RUBY_FILES.join(' ')}")
end
