# -*- coding: utf-8 -*-
# vi: fenc=utf-8:expandtab:ts=2:sw=2:sts=2
#
# Author::    Petr Kovar (mailto:pejuko@gmail.com)
# Copyright:: Copyright (c) 2011 Petr Kovář
# License::   Distributes under the same terms as Ruby

module ScanEnhancer

  class Projection

    VERTICAL = :vertical
    HORIZONTAL = :horizontal

    attr_reader :projection, :contents

    def initialize(image, type)
      @image, @data, @threshold, @type = [image, image.data, image.attrib[:threshold], type]
      @projection = computeProjection
      @contents = computeContents
    end

    # delete too small content and border content
    def delete_small!
      @contents.delete_if do |c|
#        ((c[1] - c[0]) < @image.min_content_size*0.6) or
        ((c[1] - c[0]) < @image.min_obj_size) or
        ((c[0] - @image.min_obj_size <= 0) and (c[2]<@image.min_content_size)) or
        ((c[1] + @image.min_obj_size >= @projection.size) and (c[2]<@image.min_content_size))
      end
    end

    # join adjacent contents
    def join_adjacent!
      join = []
      j = true
      while j
        j = false
        @contents.each do |c| 
          if join.empty?
            join << c
            next
          end
          if (join[-1][1] + @image.min_content_size) >= c[0]
            join[-1][1] = c[1]
            join[-1][2] = c[2] if c[2] > join[-1][2]
            j = true
          else
            join << c
          end
        end
        @contents = join
        join = []
      end
      @contents
    end

    def show_mask(img=@image.constitute)
      mdata = Array.new(@image.height){Array.new(@image.width){200}}
      @projection.each_with_index do |meta, i|
        max = 0
        meta[1].times do |y|
          max += 1
          if (@type == VERTICAL)
            mdata[y][i] = 100
          else
            mdata[i][y] = 100
          end
        end if meta[0]
      end
      mimg = @image.constitute(mdata.flatten)
      mimg.composite(
        img, 0, 0, Magick::OverlayCompositeOp
      )
    end

    # Draw boxes into given image or create new image
    def highlight(img=@image.constitute)
      to_boxes.each do |box|
        box.highlight(img)
      end
      img
    end

    # Array of contents translated to Box objects
    def to_boxes
      boxes = []
      @contents.each do |c|
        if @type == VERTICAL
          boxes << Box.new(c[0], 0, c[1], c[2])
        else
          boxes << Box.new(0, c[0], c[2], c[1])
        end
      end
      boxes
    end

  private

    # Get list of content boxes from vertical/horizontal projection
    def computeContents
      lengths = @projection.map{|c,l| l}.sort.delete_if{|x| x < @image.min_content_size}
      median = lengths[lengths.size/2]
      border = @type==VERTICAL ? @image.borders.top : @image.borders.left

      # detect content
      contents = []
      content = nil
      @projection.each_with_index do |m, i|
        c, l = m
        next if (@type==VERTICAL) and (@image.borders.left >= i or @image.borders.right <= i)
        next if (@type==HORIZONTAL) and (@image.borders.top >= i or @image.borders.bottom <= i)
        if (l-border)/median.to_f > 0.1
          content ||= [i, i, l]
          content[1] = i
          content[2] = l if l > content[2]
        else
          contents << content if content
          content = nil
        end
      end
      contents << content if content

      contents
    end

    # Run vertical or horizontal projection
    def computeProjection
      w,h = @type==:vertical ? [@image.width, @image.height] : [@image.height, @image.width]
      mw,mh = @type==:vertical ? [@image.width, @image.height-@image.borders.bottom] : [@image.height, @image.width-@image.borders.right]
      content_mask = Array.new(w){[false, 0]}

      w.times do |a|
        obj_height = 0
        gap = 0
        (h-mh).times do |b|
          x,y = @type==:vertical ? [a,b] : [b,a]
          idx = @image.index(x, y)
          #p [idx, w, h, mh, a, b, x, y, @image.width, @image.height]
          if @data[idx] <= @threshold
            obj_height += 1
            obj_height += gap if gap <= @image.min_obj_size
            gap = 0
          else
            gap += 1
            content_mask[a] = [true, b] if obj_height > @image.min_obj_size
            obj_height = 0
          end
        end
      end

      content_mask
    end

  end

end
