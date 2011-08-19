# -*- coding: utf-8 -*-
# vi: fenc=utf-8:expandtab:ts=2:sw=2:sts=2
#
# Author::    Petr Kovar (mailto:pejuko@gmail.com)
# Copyright:: Copyright (c) 2011 Petr Kovář
# License::   Distributes under the same terms as Ruby

module ScanEnhancer

  class Borders < Box

    def initialize(img)
      @image = img
      detect
    end

    # Find left, top, right and bottom borders of the page
    def detect
      xmid = (@image.width * 0.333).to_i
      ymid = (@image.height * 0.333).to_i
      @left = detectBorder(0, @image.width-1, +1, ymid, :horizontal)
      @top = detectBorder(0, @image.height-1, +1, xmid, :vertical)
      @right = detectBorder(@image.width-1, 0, -1, ymid, :horizontal)
      @bottom = detectBorder(@image.height-1, 0, -1, xmid, :vertical)
      self
    end

    # trim borders
    def fineTuneBorders!
      fineTuneBorderCorner!(:left, :top, +1, +1)
      fineTuneBorderCorner!(:right, :top, -1, +1)
      fineTuneBorderCorner!(:left, :bottom, +1, -1)
      fineTuneBorderCorner!(:right, :bottom, -1, -1)
    end

    # map values to <0..1> and return as an array
    def to_f(w=1.0, h=1.0)
      super(@image.width, @image.height, w, h)
    end

  private
    # Remove black corner
    def fineTuneBorderCorner(x, y, inc_x, inc_y)
      x1, y1 = [self.send(x)+inc_x, self.send(y)+inc_y]
      idx = 0
      loop do
        idx = @image.index(x1, y1)
        break if (idx < 0) or (idx >= @image.data.size) or (@image.data[idx] > @image.attrib[:threshold])
        x1 += inc_x
        y1 += inc_y
      end
      [x1,y1]
    end

    def fineTuneBorderCorner!(x, y, inc_x, inc_y)
      x1, y1 = fineTuneBorderCorner(x, y, inc_x, inc_y)
      if @image.index(x1,y1) < @image.data.size
        eval <<-END
          @#{x} = #{x1}
          @#{y} = #{y1}
        END
      end
      [x1, y1]
    end

    # Detect border on given edge
    def detectBorder(start_pos, end_pos, inc, mid, dir)
      gap = 0
      i = border = start_pos
      while i != end_pos
        ms = mid - 4*@image.min_content_size
        me = mid + 4*@image.min_content_size
        old_gap = gap

        j = ms
        while j<me do
          idx = dir==:vertical ? @image.index(j,i) : @image.index(i,j)
          if @image.data[idx] <= @image.attrib[:threshold]
            border = i
            gap = 0
            break
          else
            gap += 1 if gap == old_gap
          end
          j += 1
        end

        break if gap > (@image.min_content_size/2)
        i += inc
      end
      border
    end
  end
end
