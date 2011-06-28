# -*- coding: utf-8 -*-
# vi: fenc=utf-8:expandtab:ts=2:sw=2:sts=2
# 
# Author::    Petr Kovar (mailto:pejuko@gmail.com)
# Copyright:: Copyright (c) 2011 Petr Kovář
# License::   Distributes under the same terms as Ruby

module ScanEnhancer

  # Detected page information in an image.
  class Page < Image

    attr_reader :position, :content, :borders

    def initialize(data, width, height, opts)
      @options = opts
      @attrib = {}
      @data = data
      @width = width
      @height = height
      @position = {:left => 0.0, :top => 0.0, :right => 1.0, :bottom => 1.0}
      @min_obj_size = [2, (@height*@width) / ((@options[:working_dpi]*4)**2) + 1].max
      @min_content_size = (@min_obj_size * Math.sqrt((@height*@width) / ((@options[:working_dpi])**2))).to_i
      @borders = Box.new(0, 0, @width-1, @height-1)
    end

    def analyse
      @attrib[:histogram] = histogram
      @attrib[:threshold] = rightPeak[0]

      @borders = Borders.new(self)
      @borders.fineTuneBorders!
      @borders.highlight(constitute, "Borders").display if $DISPLAY

      @vertical_projection = Projection.new(self, Projection::VERTICAL)
      @vertical_projection.join_adjacent!
      @vertical_projection.delete_small!

      @horizontal_projection = Projection.new(self, Projection::HORIZONTAL)
      @horizontal_projection.join_adjacent!
      @horizontal_projection.delete_small!

      @content = Content.new(self)
      @content.fineTuneContentBox!
      @content.highlight.display if $DISPLAY
    end

    def export(file_name)
      constitute.write(file_name)
    end
  end
end
