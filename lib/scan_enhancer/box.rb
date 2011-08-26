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

    attr_accessor :left, :top, :right, :bottom

    def initialize(left, top, right, bottom)
      @left, @top, @right, @bottom = [left, top, right, bottom]
    end

    def +(box)
      self.class.new(*plus(box))
    end
    alias :join :+

    def join!(box)
      @left, @top, @right, @bottom = plus(box)
    end

    def plus(box)
      left = [@left, box.left].min
      top = [@top, box.top].min
      right = [@right, box.right].max
      bottom = [@bottom, box.bottom].max
      [left, top, right, bottom]
    end

    def width;  @right  - @left + 1; end
    def height; @bottom - @top  + 1; end
    def middle; [(@right+@left)/2, (@bottom+@top)/2]; end

    def dist(b)
      x, y = [0,0]

      if @right < b.left
        x = b.left - @right
      elsif @left > b.right
        x = @left - b.right
      end

      if @bottom < b.top
        y = b.top - @bottom
      elsif @top > b.bottom
        y =  @top - b.bottom
      end

      [x,y]
    end

    def intersect?(b)
      return false if (@right<b.left) or (@left>b.right) or (@top>b.bottom) or (@bottom<b.top)
      true
    end

    def include?(x, y)
      (x >= @left) and (x <= @right) and (y >= @top) and (y <= @bottom)
    end

    # Draw rectangle to the img using STOKE and FILL colors
    def highlight(img, msg=nil)
      context = drawContext.rectangle(@left, @top, @right, @bottom)
      context.draw(img)
      if msg
        x = (@left + @right) / 2
        y = (@top + @bottom) / 2
        context = textContext.text_align(Magick::CenterAlign).text(x, y, msg)
        context.draw(img)
      end
      img
    end

    def invert(max_x, max_y)
      boxes = []
      boxes << Box.new(0, 0, @left-1, max_y-1) if @left > 0
      boxes << Box.new(0, 0, max_x-1, @top-1) if @top > 0
      boxes << Box.new(@right+1, 0, max_x-1, max_y-1) if @right < max_x
      boxes << Box.new(0, @bottom+1, max_x-1, max_y-1) if @bottom < max_y
      boxes
    end

    def fill(img, color = 255)
      draw = Magick::Draw.new
      draw.fill = "#ffff"
      draw.stroke = "#ffff"
      draw.rectangle(@left, @top, @right, @bottom)
      draw.draw(img)
    end

    def to_a
      [@left, @top, @right, @bottom]
    end

    def to_f(iw,ih,w=1.0,h=1.0)
      [(@left.to_f/iw)*w, (@top.to_f/ih)*h, (@right.to_f/iw)*w, (@bottom.to_f/ih)*h]
    end

  private
    
    def drawContext
      draw = Magick::Draw.new

      color = %w(#f00 #0f0 #00f #ff0 #0ff #f0f).sort_by{rand}.first
      draw.fill = color + '8'
      draw.stroke = color + 'f'
      draw
    end

    def textContext
      draw = Magick::Draw.new
      draw.fill = '#00ff'
      draw.stroke = '#00ff'
      draw.font_weight = Magick::NormalWeight
      draw.font_stretch = Magick::NormalStretch
      draw.font_style= Magick::NormalStyle
      draw.text_undercolor '#ccca'
      draw
    end

  end
  
end

