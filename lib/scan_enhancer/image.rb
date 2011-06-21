# -*- coding: utf-8 -*-
# vi: fenc=utf-8:expandtab:ts=2:sw=2:sts=2
# 
# Author::    Petr Kovar (mailto:pejuko@gmail.com)
# Copyright:: Copyright (c) 2011 Petr Kovář
# License::   Distributes under the same terms as Ruby

module ScanEnhancer
  
  # Holds and work with image layout metadata.
  # Detects pages in an image.
  class Image
    
    attr_reader :data, :pages

    def initialize img, opts={}
      @options = opts
      @attrib = {}
      @attrib[:image_dpi] = img.density.to_i
      @attrib[:image_dpi] = opts[:dpi] if opts[:force_dpi] or @attrib[:image_dpi]<100
      @data = img
      @data = @data.scale(@options[:working_dpi].to_f/@attrib[:image_dpi])
      @width = @data.columns
      @height = @data.rows
      @min_obj_size = [2, (@height*@width) / ((@options[:working_dpi]*4)**2)].max
      @min_content_size = (@min_obj_size * Math.sqrt((@height*@width) / ((@options[:working_dpi])**2))).to_i
      info
      desaturate!
      @pages = []
    end

    # print some image information
    def info
      puts <<-ENDINFO
      DPI: #{@data.density}
      Working DPI #{@options[:working_dpi]}
      Width: #{@data.columns}
      Height: #{@data.rows}
      Depth: #{@data.depth}
      Min. Obj. Size: #{@min_obj_size}
      Min. Content Size: #{@min_content_size}
      ENDINFO
    end

    # Analyse page layout and return layout information
    # for each page in an image.
    def analyse
      @attrib[:histogram] = histogram
      @attrib[:threshold] = rightPeak
      #@mask = Magick::Image.constitute(@width, @height, "I", @data).threshold(@attrib[:threshold])
      #@mask.display
      @pages = findPages
      @pages
    end

    # find page contents in image and create Page objects
    # (expects that @data is array of bytes, and the image is well orientated)
    def findPages
      @attrib[:vertical_projection] = verticalProjection
      @attrib[:horizontal_projection] = horizontalProjection
      display_content_mask @attrib[:vertical_projection]
      display_content_mask @attrib[:horizontal_projection], :horizontal

      content = computeContentBox(@attrib[:vertical_projection], @attrib[:horizontal_projection])

      img = constitute(@data)
      draw = Magick::Draw.new
      draw.fill = "#fff0"
      draw.stroke = "#f00f"
      #draw.border_color = 'red'
      #draw.stroke_width = 3
      draw.rectangle(content[:left], content[:top], content[:right], content[:bottom])
      draw.draw(img)
      img.display
      #draw.composite(0,0,@width,@height,img).display
      #pp content
      []
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

    # Fix bugs on given edge
    def fineTuneEdge(c, start_x, start_y, inc_x, inc_y, edge, inc_edge, max)
      x, y = [c[start_x], c[start_y]]
      while (x <= c[:right]) and (y <= c[:bottom])
        break if (c[edge] <= 0) or (c[edge] >= max)
        idx = (y * @width) + x
        idx_top = ((y-inc_x) * @width) + x+inc_y
        idx_bottom = ((y+inc_x) * @width) + x-inc_y
        if @data[idx_top] and @data[idx_bottom] and (@data[idx] <= @attrib[:threshold] or @data[idx_bottom] <= @attrib[:threshold]) and (@data[idx_top] <= @attrib[:threshold])
          p [edge, @attrib[:threshold], @data[idx], @data[idx_bottom], @data[idx_top], c]
          c[edge] += inc_edge
          x, y = [c[start_x], c[start_y]]
        end
        x += inc_x
        y += inc_y
      end
    end

    # Fix some bugs on edges
    def fineTuneContentBox(c)
      p c
      # top edge
      fineTuneEdge(c, :left, :top, +1, 0, :top, -1, @height)

      # bottom edge
      fineTuneEdge(c, :left, :bottom, +1, 0, :bottom, +1, @height)

      # right edge
      fineTuneEdge(c, :right, :top, 0, +1, :right, +1, @width)

      # left edge
      fineTuneEdge(c, :left, :top, 0, +1, :left, -1, @width)

      p c
      c
    end

    # Run vertical or horizontal projection (dir = :vertical | :horizontal)
    def projection(dir)
      w,h = dir==:vertical ? [@width, @height] : [@height, @width]
      content_mask = Array.new(w){[false, 0]}

      w.times do |a|
        obj_height = 0
        gap = 0
        h.times do |b|
          x,y = dir==:vertical ? [a,b] : [b,a]
          idx = (y * @width) + x
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

    # Convert image color space to 8-bit grayscale
    def desaturate!
      @data = @data.quantize(256, Magick::GRAYColorspace).dispatch(0,0,@data.columns,@data.rows,"I",true).map{|pix| (255*pix).to_i}
      @attrib[:desaturated] = true
    end

    # Grayscale 8-bit image histogram
    def histogram
      desaturate! unless @attrib[:desaturated]
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

    # Return number of pages on the image
    def size
      @pages.size
    end

  end
end
