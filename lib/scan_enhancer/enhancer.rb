# -*- coding: utf-8 -*-
# vi: fenc=utf-8:expandtab:ts=2:sw=2:sts=2
# 
# Main module for scan_enhancer
#
# Author::    Petr Kovar (mailto:pejuko@gmail.com)
# Copyright:: Copyright (c) 2011 Petr Kovář
# License::   Distributes under the same terms as Ruby

module ScanEnhancer
  class Enhancer

    # Create an Enhancer instance and set the options
    def initialize opts={}
      @options = {:dpi=>300, :threads=>1}.merge opts
    end

    # Load and analyse input files
    def load_files files=[]
    end

  end
end
