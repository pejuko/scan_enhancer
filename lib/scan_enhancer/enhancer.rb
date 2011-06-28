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
      @options = {:dpi=>300, :output_dpi=>300, :working_dpi=>150, :force_dpi=>false, :threads=>1, :verbose=>true}.merge opts
      @page_number_start = 1
      @page_number_step = 1
      @files, @images, @pages  = [], [], []
    end

    # export pages to files
    def export
      @pages.each_with_index do |page, i|
        page.content.fill_invert
        page.threshold!
        page.export("page-%04d.png" % [@page_number_start + @page_number_step*i])
      end
    end

    # Load and analyse input files
    def load_files files=[]
      files.each do |file|
        load_file file
      end
    end

    private

    # Load, analyse and append an input file
    def load_file file
      ifile = ImageFile.new file, @options
      throw "'#{file}' does not contain any image" unless ifile.loaded?
      puts "#{ifile.size} images loaded from #{ifile.file_name}" if @options[:verbose]
      @files << ifile
      ifile.images.each do |image|
        image.info
        @images << image
        @pages += image.analyse
      end
    end

  end
end
