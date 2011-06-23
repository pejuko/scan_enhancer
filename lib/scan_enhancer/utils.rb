# -*- coding: utf-8 -*-
# vi: fenc=utf-8:expandtab:ts=2:sw=2:sts=2
#
# Various image utils used on more places
#
# Author::    Petr Kovar (mailto:pejuko@gmail.com)
# Copyright:: Copyright (c) 2011 Petr Kovář
# License::   Distributes under the same terms as Ruby

module ScanEnhancer

  # includable module to extend object functionality (eg: Image or Page)
  # expects variables: @data, @width, @height
  module Utils

    # Fix bugs on given edge
    def fineTuneEdge(c, start_x, start_y, inc_x, inc_y, edge, inc_edge, min, max)
      x, y = [c[start_x], c[start_y]]
      while (x <= c[:right]) and (y <= c[:bottom])
        break if (c[edge] <= min) or (c[edge] >= max)
        idx = index(x, y)
        idx_top = index(x+inc_y, y-inc_x)
        idx_bottom = index(x-inc_y, y+inc_x)
        if @data[idx_top] and @data[idx_bottom] and (@data[idx] <= @attrib[:threshold] or @data[idx_bottom] <= @attrib[:threshold]) and (@data[idx_top] <= @attrib[:threshold])
          #p [edge, @attrib[:threshold], @data[idx], @data[idx_bottom], @data[idx_top], c]
          c[edge] += inc_edge
          x, y = [c[start_x], c[start_y]]
        end
        x += inc_x
        y += inc_y
      end
    end

    # Fix some bugs on edges
    def fineTuneContentBox(c)
      #p c

      l, t, r, b = @attrib[:borders].values_at(:left, :top, :right, :bottom)
      # top edge
      fineTuneEdge(c, :left, :top, +1, 0, :top, -1, t, b)

      # bottom edge
      fineTuneEdge(c, :left, :bottom, +1, 0, :bottom, +1, t, b)

      # right edge
      fineTuneEdge(c, :right, :top, 0, +1, :right, +1, l, r)

      # left edge
      fineTuneEdge(c, :left, :top, 0, +1, :left, -1, l, r)

      #p c
      c
    end

    # Run vertical or horizontal projection (dir = :vertical | :horizontal)
    def projection(dir)
      w,h = dir==:vertical ? [@width, @height] : [@height, @width]
      mw,mh = dir==:vertical ? [@width, @height-@attrib[:borders][:bottom]] : [@height, @width-@attrib[:borders][:right]]
      content_mask = Array.new(w){[false, 0]}

      w.times do |a|
        obj_height = 0
        gap = 0
        (h-mh).times do |b|
          x,y = dir==:vertical ? [a,b] : [b,a]
          idx = index(x, y)
          if @data[idx] <= @attrib[:threshold]
            obj_height += 1
            obj_height += gap if gap <= @min_obj_size
            gap = 0
          else
            gap += 1
            content_mask[a] = [true, b] if obj_height > @min_obj_size
            obj_height = 0
          end
        end
      end

      content_mask
    end

    # find vertical blocks
    # allow to detect columns, pages => left and right borders
    def verticalProjection
      projection(:vertical)
    end

    # detect horizontal blocks
    # detects top and bottom borders (line detection depends on page skew)
    def horizontalProjection
      projection(:horizontal)
    end

    # helper function
    # creates B/W Magick::Image with highlighted content
    def display_content_mask(cm, dir = :vertical)
      mdata = Array.new(@height){Array.new(@width){200}}
      cm.each_with_index do |meta, i|
        max = 0
        meta[1].times do |y|
          max += 1
          if (dir == :vertical)
            mdata[y][i] = 100
          else
            mdata[i][y] = 100
          end
        end if meta[0]
      end
      mimg = constitute(mdata.flatten)
      img = constitute(@data)
      mimg.composite(
        img, 0, 0, Magick::OverlayCompositeOp
      ).display
    end

    # create Magick::Image from data
    def constitute(idata)
      Magick::Image.constitute(@width, @height, "I", idata.map{|pix| pix/255.0})
    end

    # Grayscale 8-bit image histogram
    def histogram
      hist = Array.new(256){0}
      @data.each do |pix|
        hist[pix] += 1
      end
=begin
      h = @data.color_histogram
      h.keys.sort_by{|pixel| pixel.red}.each do |pixel|
        idx = (pixel.red.to_f / Magick::QuantumRange) * 255
        hist[idx] = h[pixel]
      end
=end
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
      #(valley.to_f/256) * Magick::QuantumRange
      valley
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
      #(valley.to_f/256) * Magick::QuantumRange
      valley
    end

    def highlight(rect, msg=nil)
      img = constitute(@data)
      draw = Magick::Draw.new
      draw.fill = "#fff0"
      draw.stroke = "#f00f"
      draw.rectangle(rect[:left], rect[:top], rect[:right], rect[:bottom])
      draw.draw(img)
      if msg
        draw = Magick::Draw.new
        draw.fill = "#ffff"
        draw.stroke = "#000f"
        draw.text(rect[:left]+15, rect[:top]+2, msg)
        draw.draw(img)
      end
      img.display
      #draw.composite(0,0,@width,@height,img).display
    end

    def index(x, y)
      (y * @width) + x
    end


    # Remove black corner
    def fineTuneBorderCorner(b, x, y, inc_x, inc_y)
      x1, y1 = [b[x]+inc_x, b[y]+inc_y]
      idx = 0
      loop do
        idx = index(x1, y1)
        break if @data[idx] > @attrib[:threshold]
        x1 += inc_x
        y1 += inc_y
      end
      if idx < @data.size
        b[x] = x1 
        b[y] = y1
      end
      b
    end

    # trim borders
    def fineTuneBorders(b)
      fineTuneBorderCorner(b, :left, :top, +1, +1)
      fineTuneBorderCorner(b, :right, :top, -1, +1)
      fineTuneBorderCorner(b, :left, :bottom, +1, -1)
      fineTuneBorderCorner(b, :right, :bottom, -1, -1)
    end

    # Detect border on given edge
    def detectBorder(start_pos, end_pos, inc, mid, dir)
      gap = 0
      border = 0

      i = start_pos
      while i != end_pos
        ms = mid - @min_content_size
        me = mid + @min_content_size
        old_gap = gap

        j = ms
        while j<me do
          idx = dir==:vertical ? index(j,i) : index(i,j)
          if @data[idx] <= @attrib[:threshold]
            gap = 0
            break
          end
          j += 1
        end

        gap += 1 if gap == old_gap

        if gap > @min_content_size
          border = i
          break
        end

        i += inc
      end

      border - (inc*gap)
    end

    # Find left, top, right and bottom borders of the page
    def detectBorders
      xmid = @width / 2
      ymid = @height / 2
      borders = {
        :left   => detectBorder(0, @width-1, +1, ymid, :horizontal),
        :top    => detectBorder(0, @height-1, +1, xmid, :vertical),
        :right  => detectBorder(@width-1, 0, -1, ymid, :horizontal),
        :bottom => detectBorder(@height-1, 0, -1, xmid, :vertical)
      }
      #fineTuneBorders(borders)
      highlight borders, "borders"
      p borders
      borders
    end

    # Get list of content boxes from vertical/horizontal projection
    def computeContents(mask, dir=:vertical)
      median = 99999
      lengths = mask.map{|c,l| l}.sort.delete_if{|x| x== 0}
      median = lengths[lengths.size/2]

      # detect content
      contents = []
      content = nil
      mask.each_with_index do |m, i|
        c, l = m
        next if (dir==:vertical) and (@attrib[:borders][:left] >= i or @attrib[:borders][:right] <= i)
        next if (dir==:horizontal) and (@attrib[:borders][:top] >= i or @attrib[:borders][:bottom] <= i)
        if l/median.to_f > 0.1
          content ||= [i, i, l]
          content[1] = i
          content[2] = l if l > content[2]
        else
          contents << content if content
          content = nil
        end
      end

      # join adjacent content boxes
      join = []
      j = true
      while j
        j = false
        contents.each do |c| 
          if join.empty?
            join << c
            next
          end
          if (join[-1][1] + @min_content_size) >= c[0]
            join[-1][1] = c[1]
            join[-1][2] = c[2] if c[2] > join[-1][2]
            j = true
          else
            join << c
          end
        end
        contents = join
        join = []
      end

      # delete too small content and border content
      contents << content if content
      contents.delete_if do |c|
        ((c[1] - c[0]) < @min_obj_size) or
        ((c[0] - @min_obj_size <= 0) and (c[2]<@min_content_size)) or
        ((c[1] + @min_obj_size >= mask.size) and (c[2]<@min_content_size))
      end

      img = constitute(@data)
      draw = Magick::Draw.new
      draw.fill = "#fff0"
      draw.stroke = "#f00f"
      contents.each do |c|
        if dir == :vertical
          draw.rectangle(c[0], 0, c[1], c[2])
        else
          draw.rectangle(0, c[0], c[2], c[1])
        end
        draw.draw(img)
      end
      img.display

      contents
    end

    # Return bounding content box
    def computeContentBox(vm, hm)
      c = {
        :left => 0,
        :right => @width,
        :top => 0,
        :bottom => @height
      }
      @attrib[:vertical_contents] = computeContents(vm, :vertical)
      @attrib[:horizontal_contents] = computeContents(hm, :horizontal)

      # select the largest boxes
      vb = @attrib[:vertical_contents].sort_by{|c| c[1]-c[0]}
      hb = @attrib[:horizontal_contents]

      c[:left] = vb.last[0]
      c[:right] = vb.last[1]
      c[:top] = hb.first[0]
      c[:bottom] = [vb.last[2], hb.last[1]].min
      
      fineTuneContentBox(c)

      c
    end

    # cut rectangel from @data
    def cut(x1, y1, x2, y2)
      w, h = [x2-x1, y2-y1]
      new_data = Array.new(w*h){255}
      h.times do |y|
        w.times do |x|
          old_idx = index(x1+x, y1+y)
          new_idx = (y * w) + x
          new_data[new_idx] = @data[old_idx]
        end
      end
      new_data
    end

  end
end
