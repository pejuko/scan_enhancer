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
      @options = {:dpi=>600, :output_dpi=>300, :working_dpi=>150, :force_dpi=>false, :threads=>1, :verbose=>true}.merge opts
      @page_number_start = 1
      @page_number_step = 1
      @files, @images, @pages  = [], [], []
    end

    # export pages to files
    def export
      @pages.each_with_index do |page, i|
        puts "Export:"
=begin
        page.load_original
        ScanEnhancer::profile("fill_invert") {
          page.content.fill_invert
        }
        ScanEnhancer::profile("Deskew") {
          page.deskew!
        }
        ScanEnhancer::profile("threshold") {
          page.threshold!
        }
=end
        ScanEnhancer::profile("export") {
          page.export("page-%04d.tif" % [@page_number_start + @page_number_step*i])
        }
        page.free_data!
        puts ""
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
        image.free_data!
        image.pages.each{|page| page.free_data!}
      end
    end

  end
end
