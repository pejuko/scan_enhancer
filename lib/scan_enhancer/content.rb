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

      @left = fineTuneEdge(:left, :top, 0, +1, :left, -1, l, r)
      @top = fineTuneEdge(:left, :top, +1, 0, :top, -1, t, b)
      @right = fineTuneEdge(:right, :top, 0, +1, :right, +1, l, r)
      @bottom = fineTuneEdge(:left, :bottom, +1, 0, :bottom, +1, t, b)

      self
    end

    def highlight(img=@image.constitute)
      super(img, "Content Box")
    end

    private

    def computeContentBox
      vp = @image.vertical_projection
      hp = @image.horizontal_projection

      vp.highlight.display
      hp.highlight.display

      vb = vp.to_boxes.sort_by{|b| b.width}.last
      hbs = hp.to_boxes
      @left, @right = [vb.left, vb.right]
      @top, @bottom = [hbs[0].top, hbs[-1].bottom]
    end

    # Fix bugs on given edge
    # it moves the edge if black pixels are presented
    def fineTuneEdge(start_x, start_y, inc_x, inc_y, edge, inc_edge, min, max)
      x, y = self.send(start_x), self.send(start_y)
      while (x <= @right) and (y <= @bottom)
        break if (self.send(edge) <= min) or (self.send(edge) >= max)
        idx = @image.index(x, y)
        idx_top = @image.index(x+inc_y, y-inc_x)
        idx_bottom = @image.index(x-inc_y, y+inc_x)
        if @image.data[idx_top] and @image.data[idx_bottom] and (@image.data[idx_top] <= @image.attrib[:threshold])
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
