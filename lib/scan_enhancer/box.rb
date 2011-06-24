# -*- coding: utf-8 -*-
# vi: fenc=utf-8:expandtab:ts=2:sw=2:sts=2
#
# Author::    Petr Kovar (mailto:pejuko@gmail.com)
# Copyright:: Copyright (c) 2011 Petr Kovář
# License::   Distributes under the same terms as Ruby

module ScanEnhancer

  class Box

    STROKE = "#f00f"
    FILL = "#fff0"

    attr_reader :left, :top, :right, :bottom

    def initialize(left, top, right, bottom)
      @left, @top, @right, @bottom = [left, top, right, bottom]
    end

    def +(box)
      left = [@left, box.left].min
      top = [@top, box.top].min
      right = [@right, box.right].max
      bottom = [@bottom, box.bottom].max
      self.class.new(left, top, right, bottom)
    end
    alias :join :+

    def width;  @right  - @left + 1; end
    def height; @bottom - @top  + 1; end
    def middle; [(@right+@left)/2, (@bottom+@top)/2]; end

    # Draw rectangle to the img using STOKE and FILL colors
    def highlight(img, msg=nil)
      context = drawContext.rectangle(@left, @top, @right, @bottom)
      context.draw(img)
      if msg
        x = (@left + @right) / 2
        y = (@top + @bottom) / 2
        context = drawContext.text_align(Magick::CenterAlign).text(x, y, msg)
        context.draw(img)
      end
      img
    end

    def to_a
      [@left, @top, @right, @bottom]
    end

  private
    
    def drawContext
      draw = Magick::Draw.new
      draw.fill = FILL
      draw.stroke = STROKE
      draw
    end

  end
  
end

