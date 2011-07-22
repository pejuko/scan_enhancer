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

    def initialize(image, data, width, height, opts)
      @options = opts
      @image = image
      @filename = @image.filename
      @filepage = @image.filepage
      @attrib = {}
      @data = data
      @width = width
      @height = height
      @position = {:left => 0.0, :top => 0.0, :right => 1.0, :bottom => 1.0}
      @min_obj_size = [2, (@height*@width) / ((@options[:working_dpi]*4)**2) + 1].max
      @min_content_size = (@min_obj_size * Math.sqrt((@height*@width) / ((@options[:working_dpi])**2))).to_i
      @borders = Box.new(0, 0, @width-1, @height-1)
      info
    end

    def analyse
      ScanEnhancer::profile("get histogram and threshold") {
        @attrib[:histogram] = histogram
        @attrib[:threshold] = otsuThreshold
      }

      ScanEnhancer::profile("borders detect") {
        @borders = Borders.new(self)
        @borders.fineTuneBorders!
      }
      @borders.highlight(constitute, "Borders").display if $DISPLAY

      ScanEnhancer::profile("vertical projection") {
        @vertical_projection = Projection.new(self, Projection::VERTICAL)
        @vertical_projection.join_adjacent!
        @vertical_projection.delete_small!
      }

      ScanEnhancer::profile("horizontal projection") {
        @horizontal_projection = Projection.new(self, Projection::HORIZONTAL)
        @horizontal_projection.join_adjacent!
        @horizontal_projection.delete_small!
      }

      ScanEnhancer::profile("content detection") {
        @content = Content.new(self)
        @content.fineTuneContentBox!
      }
      @content.highlight.display if $DISPLAY

      ScanEnhancer::profile("conected components") {
        @components = Components.new(self)
      }
      ScanEnhancer::profile("get_lines") {
        @lines = @components.get_lines
      }
      img = constitute
      gc = Magick::Draw.new
      p @lines.size
      #@lines.highlight img
      @lines.each_with_index do |g,j|
        #g.display_components(img)
        g.highlight img, j.to_s
        g.each_with_index do |c,i|
          if i>0
            x1 = g[i-1].middle[0]
            y1 = g[i-1].bottom
            x2 = g[i].middle[0]
            y2 = g[i].bottom
            gc.line( x1, y1, x2, y2 )
          end
        end
      end
      gc.draw(img)
      img.display
=begin
      @words = @components.words
      @lines = @words.lines
      @speckles = @lines.speckles(@min_obj_size*2)
      @components.display_components.display # if $DISPLAY
      @words.display_components.display
      @lines.display_components.display
      @speckles.display_components.display
      (@lines - @speckles).display_components.display
=end
    end

    def load_original
      super
      @content.remap!
    end

    def export(file_name)
      img = @data
      img = constitute if @data.is_a? Array
      depth = @image.depth.to_i
      img.write(file_name) {
        if depth > 1
          self.compression = Magick::ZipCompression
        else
          self.compression = Magick::FaxCompression
        end
      }
    end
  end
end
