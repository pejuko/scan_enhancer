# -*- coding: utf-8 -*-
# vi: fenc=utf-8:expandtab:ts=2:sw=2:sts=2
# 
# Author::    Petr Kovar (mailto:pejuko@gmail.com)
# Copyright:: Copyright (c) 2011 Petr Kovář
# License::   Distributes under the same terms as Ruby

module ScanEnhancer

  class Content < Box

    def initialize(img)
      super(0,0,img.width-1,img.height-1)
      @image = img
      computeContentBox
    end

    # Fix some bugs on edges
    def fineTuneContentBox!
      l, t, r, b = @image.borders.to_a

      change = true
      while change
        old_l, old_t, old_r, old_b = [@left, @top, @right, @bottom]
        @left = fineTuneEdge(:left, :top, 0, +1, :left, -1, l, r)
        @top = fineTuneEdge(:left, :top, +1, 0, :top, -1, t, b)
        @right = fineTuneEdge(:right, :top, 0, +1, :right, +1, l, r)
        @bottom = fineTuneEdge(:left, :bottom, +1, 0, :bottom, +1, t, b)
        change = (@left != old_l) or (@top != old_t) or (@right != old_r) or (@bottom != old_b)
      end

      self
    end

    def highlight(img=@image.constitute)
      super(img, "Content Box")
    end

    def fill(color=255)
      super(@image, color)
    end

    def fill_invert
      invert(@image.width, @image.height).each do |box|
        box.fill(@image)
      end
    end

    private

    def computeContentBox
      vp = @image.vertical_projection
      hp = @image.horizontal_projection

      if $DISPLAY
        vp.highlight.display
        hp.highlight.display
      end

      vb = vp.to_boxes.sort_by{|b| b.width}.last
      hbs = hp.to_boxes
      @left, @right = [vb.left, vb.right]
      @top, @bottom = [hbs[0].top, hbs[-1].bottom]
    end

    # Fix bugs on given edge
    # it moves the edge if black pixels are presented
    def fineTuneEdge(start_x, start_y, inc_x, inc_y, edge, inc_edge, min, max)
      x, y = self.send(start_x), self.send(start_y)
      while (x <= @right) and (y <= @bottom) and (self.send(edge) > min) and (self.send(edge) < max)
        top_x, top_y = (x != 0) ? [x, y+inc_edge] : [x+inc_edge, y]
        idx_top = @image.index(top_x, top_y)
        if @image.data[idx_top] and (@image.data[idx_top] <= @image.attrib[:threshold])
          eval %~@#{edge} += inc_edge~
          x, y = [self.send(start_x), self.send(start_y)]
        end
        x += inc_x
        y += inc_y
      end
      self.send(edge)
    end
  end

end
