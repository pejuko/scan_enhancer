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

    def initialize img, opts={}
      @options = opts
      @attrib = {}
      @attrib[:image_dpi] = img.density.to_i
      @attrib[:image_dpi] = opts[:dpi] if opts[:force_dpi] or @attrib[:image_dpi]<100
      @data = img.scale @options[:working_dpi].to_f/@attrib[:image_dpi]
      desaturate!
      info
      @pages = []
    end

    # print some image information
    def info
      puts <<-ENDINFO
      DPI: #{@data.density}
      Width: #{@data.columns}
      Height: #{@data.rows}
      Depth: #{@data.depth}
      ENDINFO
    end

    # Analyse page layout and return layout information
    # for each page in an image.
    def analyse
      @attrib[:histogram] = histogram
      @attrib[:threshold] = rightPeak
      @mask = @data.threshold @attrib[:threshold]
      @mask.display
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

    # Detect right peak and right valley in image histogram
    def rightPeak
      @attrib[:histogram] ||= histogram
#      p @attrib[:histogram]
      j = idx = 255
      valley = idx-1
      max_value = @attrib[:histogram][j]
      (idx-1).downto(0) do |i|
        if @attrib[:histogram][i] >= max_value
          j = i
          max_value = @attrib[:histogram][j]
          valley = j-1
        elsif @attrib[:histogram][i] > 0.1*max_value
          valley = i
        end
=begin
        p @attrib[:histogram][i], 0.25*max_value
        p "right_peak> i:#{i}, j:#{j}, valley:#{valley}, max_value:#{max_value}"
=end
        break if (valley-i > 15)
      end
      (valley.to_f/256) * Magick::QuantumRange
    end

    # Detect left peak and right valley in image histogram
    def leftPeak
      @attrib[:histogram] ||= histogram
#      p @attrib[:histogram]
      j = idx = 0
      valley = idx+1
      max_value = @attrib[:histogram][j]
      (idx+1).upto(255) do |i|
        if @attrib[:histogram][i] >= max_value
          j = i
          max_value = @attrib[:histogram][j]
          valley = j+1
        elsif @attrib[:histogram][i] > 0.1*max_value
          valley = i
        end
=begin
        p @attrib[:histogram][i], 0.25*max_value
        p "left_peak> i:#{i}, j:#{j}, valley:#{valley}, max_value:#{max_value}"
=end
        break if (i-valley > 15)
      end
      (valley.to_f/256) * Magick::QuantumRange
    end

    # Return number of pages on the image
    def size
      @pages.size
    end

  end
end
