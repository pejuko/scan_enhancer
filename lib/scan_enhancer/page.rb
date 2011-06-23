# -*- coding: utf-8 -*-
# vi: fenc=utf-8:expandtab:ts=2:sw=2:sts=2
# 
# Author::    Petr Kovar (mailto:pejuko@gmail.com)
# Copyright:: Copyright (c) 2011 Petr Kovář
# License::   Distributes under the same terms as Ruby

module ScanEnhancer

  # Detected page information in an image.
  class Page
    include Utils

    attr_reader :position

    def initialize(data, width, height, opts)
      @options = opts
      @attrib = {}
      @data = data
      @width = width
      @height = height
      @position = {:left => 0.0, :top => 0.0, :right => 1.0, :bottom => 1.0}
      constitute(@data).display

      @min_obj_size = [2, (@height*@width) / ((@options[:working_dpi]*4)**2)].max
      @min_content_size = (@min_obj_size * Math.sqrt((@height*@width) / ((@options[:working_dpi])**2))).to_i
      @attrib[:borders] = {}
      @attrib[:borders][:left] = 0
      @attrib[:borders][:top] = 0
      @attrib[:borders][:right] = @width - 1
      @attrib[:borders][:bottom] = @height - 1
    end

    def analyse
      @attrib[:histogram] = histogram
      @attrib[:threshold] = rightPeak
      # p @attrib

      @mask = Magick::Image.constitute(@width, @height, "I", @data).threshold(@attrib[:threshold])
      @mask.display

      @attrib[:borders] = detectBorders
      @attrib[:vertical_projection] = verticalProjection
      @attrib[:horizontal_projection] = horizontalProjection
      @attrib[:threshold] = rightPeak

      display_content_mask @attrib[:vertical_projection]
      display_content_mask @attrib[:horizontal_projection], :horizontal

      content = computeContentBox(@attrib[:vertical_projection], @attrib[:horizontal_projection])
      highlight content, "Content Box"
    end
  end
end
