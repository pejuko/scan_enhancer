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

    attr_reader :files, :images, :pages

    # Create an Enhancer instance and set the options
    def initialize opts={}
      @options = {:dpi=>300, :threads=>1, :verbose=>true}.merge opts
      @files, @images, @pages  = [], [], []
    end

    # Load and analyse input files
    def load_files files=[]
      files.each do |file|
        load_file file
      end
      @images.each{|img| @pages += img.analyse}
    end

    # Load, analyse and append an input file
    def load_file file
      ifile = ImageFile.new file
      throw "'#{file}' does not contain any image" unless ifile.loaded?
      puts "#{ifile.size} images loaded from #{ifile.file_name}" if @options[:verbose]
      @files << ifile
      @images += ifile.images
    end

  end
end
