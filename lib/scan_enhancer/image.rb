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
      @data = @data.scale @options[:working_dpi].to_f/@attrib[:image_dpi]
      @width = @data.columns
      @height = @data.rows
      info
      desaturate!
      @pages = []
    end

    # print some image information
    def info
      puts <<-ENDINFO
      DPI: #{@data.density}
      Width: #{@data.columns}
      Height: #{@data.rows}
      Depth: #{@data.depth}
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
      vertical_mask = verticalProjection
      horizontal_mask = horizontalProjection
#      display_content_mask(vertical_mask)
#      display_content_mask(horizontal_mask, :horizontal)

      content = computeContentBox(vertical_mask, horizontal_mask)
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
      pp content
      []
    end

    def computeContentBox(vm, hm)
      c = {
        :left => 0,
        :right => @width,
        :top => 0,
        :bottom => @height
      }
      0.upto(vm.size){|i| if vm[i][0] then c[:left] = i; break; end }
      (vm.size-1).downto(0){|i| if vm[i][0] then c[:right] = i; break; end }
      0.upto(hm.size){|i| if hm[i][0] then c[:top] = i; break; end }
      (hm.size-1).downto(0){|i| if hm[i][0] then c[:bottom] = i; break; end }
      c
    end

    # find vertical blocks
    # allow to detect columns, pages => left and right borders
    def verticalProjection
      min_line_height = @height / @options[:working_dpi]
      content_mask = Array.new(@width){[false, 0]}

      @width.times do |x|
        obj_height = 0
        @height.times do |y|
          idx = (y * @width) + x
          if @data[idx] <= @attrib[:threshold]
            obj_height += 1
          else
            if obj_height > min_line_height
#              puts "min_line_height: #{min_line_height}, obj_height: #{obj_height}"
              content_mask[x][0] = true
              content_mask[x][1] = y
            end
            obj_height = 0
          end
        end
      end

      content_mask
    end

    # detect horizontal blocks
    # detects top and bottom borders (line detection depends on page skew)
    def horizontalProjection
      min_line_height = @height / @options[:working_dpi]
      content_mask = Array.new(@height){[false, 0]}

      @height.times do |y|
        obj_width = 0
        @width.times do |x|
          idx = (y * @width) + x
          if @data[idx] <= @attrib[:threshold]
            obj_width += 1
          else
            if obj_width > min_line_height
#              puts "min_line_height: #{min_line_height}, obj_height: #{obj_height}"
              content_mask[y][0] = true
              content_mask[y][1] = x
            end
            obj_height = 0
          end
        end
      end

      content_mask
    end

    # helper function
    # creates B/W Magick::Image with highlighted content
    def display_content_mask(cm, dir = :vertical)
      mdata = Array.new(@height){Array.new(@width){255}}
      cm.each_with_index do |meta, i|
        meta[1].times do |y|
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
