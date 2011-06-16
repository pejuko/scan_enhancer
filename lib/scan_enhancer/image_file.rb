# -*- coding: utf-8 -*-
# vi: fenc=utf-8:expandtab:ts=2:sw=2:sts=2
# 
# Author::    Petr Kovar (mailto:pejuko@gmail.com)
# Copyright:: Copyright (c) 2011 Petr Kovář
# License::   Distributes under the same terms as Ruby

module ScanEnhancer

  # Read images from a file. Files like tiff or pdf can have
  # more images.
  class ImageFile
    
    attr_reader :path, :images

    def initialize file
      @path = file
      @images = load_images
    end

    # Load images from a file and create class ScanEnhancer::Image
    def load_images
      Magick::Image.read(@path).map!{|img| Image.new img}
    end

    # Get n-th image from a file.
    def image idx=0
      @images[idx]
    end

    # Can indicate that file has no image.
    def loaded?
      @images.size > 0
    end

    # Number of images in a file.
    def size
      @images.size
    end

    # File name without path.
    def file_name
      File.basename @path
    end

    # Directory path to the file
    def directory
      File.dirname @path
    end

  end
end
