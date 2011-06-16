# -*- coding: utf-8 -*-
# vi: fenc=utf-8:expandtab:ts=2:sw=2:sts=2
# 
# Author::    Petr Kovar (mailto:pejuko@gmail.com)
# Copyright:: Copyright (c) 2011 Petr Kovář
# License::   Distributes under the same terms as Ruby

module ScanEnhancer
  
  # Holds and work with image layout metadata.
  # Detects pages in an image.
  class Image
    
    attr_reader :data, :pages

    def initialize img
      @data = img
      info
      @pages = []
      @attrib = {}
    end

    # print some image information
    def info
      puts <<-ENDINFO
      DPI: #{data.density}
      Width: #{data.width}
      Height: #{data.height}
      Depth: #{data.depth}
      ENDINFO
    end

    # Analyse page layout and return layout information
    # for each page in an image.
    def analyse
      @attrib[:histogram] = histogram
      @attrib[:threshold] = rightPeak
      @mask = @data.threshold @attrib[:threshold]
      @pages << Page.new(self)
      @pages
    end

    # Convert image color space to 8-bit grayscale
    def desaturate!
      @data = @data.quantize 256, Magick::GRAYColorspace
      @attrib[:desaturated] = true
    end

    # Grayscale 8-bit image histogram
    def histogram
      desaturate! unless @attrib[:desaturated]
      hist = Array.new(256){0}
      h = @data.color_histogram
      h.keys.sort_by{|pixel| pixel.red}.each do |pixel|
        idx = (pixel.red.to_f / Magick::QuantumRange) * 255
        hist[idx] = h[pixel]
      end
      hist
    end

    # Detect right peak in image histogram
    def rightPeak
      @attrib[:histogram] ||= histogram
      j = idx = 255
      max_value = @attrib[:histogram][j]
      (idx-1).downto(0) do |i|
        if @attrib[:histogram][i] > max_value
          j = i
          max_value = @attrib[:histogram][j]
        end
        break if @attrib[:histogram][i] < (max_value*0.66)
      end
      ((j-1).to_f/256) * Magick::QuantumRange
    end

    # Return number of pages on the image
    def size
      @pages.size
    end

  end
end
