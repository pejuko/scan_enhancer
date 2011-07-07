# -*- coding: utf-8 -*-
# vi: fenc=utf-8:expandtab:ts=2:sw=2:sts=2
# 
# Library loading all necessary modules for ScanEnhancer
#
# Author::    Petr Kovar (mailto:pejuko@gmail.com)
# Copyright:: Copyright (c) 2011 Petr Kovář
# License::   Distributes under the same terms as Ruby

require 'pp'
require 'rubygems'
require 'RMagick'

module ScanEnhancer

  def self.profile(str, &block)
    ts = Time.now
    yield
    te = Time.now
    res = te - ts
    STDOUT << "#{str}: #{res} second\n"
    res
  end

  autoload :ImageFile,  'lib/scan_enhancer/image_file.rb'
  autoload :Box,        'lib/scan_enhancer/box.rb'
  autoload :Projection, 'lib/scan_enhancer/projection.rb'
  autoload :Content,    'lib/scan_enhancer/content.rb'
  autoload :Component,  'lib/scan_enhancer/components.rb'
  autoload :Components, 'lib/scan_enhancer/components.rb'
  autoload :Borders,    'lib/scan_enhancer/borders.rb'
  autoload :Image,      'lib/scan_enhancer/image.rb'
  autoload :Page,       'lib/scan_enhancer/page.rb'

end

require 'lib/scan_enhancer/enhancer.rb'
