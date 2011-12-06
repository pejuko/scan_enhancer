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
    
    attr_reader :data, :pages, :attrib, :width, :height, :borders, :min_obj_size, :min_content_size, :vertical_projection, :horizontal_projection, :filename, :filepage, :depth, :image_width, :image_height, :angle

    def initialize img, opts={}, page=0
      @options = opts
      @attrib = {}
      @depth = img.depth
      @filename = img.filename
      @filepage =  page
      @image_width = img.columns
      @image_height = img.rows
      @dpi = img.density.to_i
      @dpi = opts[:dpi] if opts[:force_dpi] or @dpi<100
      @data = img
      downscale!
      @angle = 0.0
      @width = @data.columns
      @height = @data.rows
      @min_obj_size = [2, (@height*@width) / ((@options[:working_dpi]*4)**2)].max
      @min_content_size = (@min_obj_size * Math.sqrt((@height*@width) / ((@options[:working_dpi])**2))).to_i
      @borders = Box.new(0, 0, @width-1, @height-1)
      desaturate!
      to_data!
      @pages = []
    end

    def load_original
      @data = Magick::Image.read(@filename)[@filepage].contrast(true)
      @width = @data.columns
      @height = @data.rows
      desaturate!
    end

    def downscale!
      @data = @data.scale(@options[:working_dpi].to_f/@dpi).contrast(true)
    end

    # print some image information
    def info
      puts <<-ENDINFO
      Filename: #{@filename}
      File Page: #{@filepage}
      DPI: #{@dpi}
      Working DPI #{@options[:working_dpi]}
      Image Width: #{@image_width}
      Image Height: #{@image_height}
      Data Width: #{@width}
      Data Height: #{@height}
      Depth: #{@depth}
      Min. Obj. Size: #{@min_obj_size}
      Min. Content Size: #{@min_content_size}
      ENDINFO
    end


    # get index in @data
    def index(x, y)
      (y * @width) + x
    end

    # create Magick::Image from data
    def constitute(idata=@data)
      coef = Magick::QuantumRange.to_f / 255.to_f  
      #GC.disable
      img = Magick::Image.constitute(@width, @height, "I", idata.map{|pix| (pix*coef).to_i})
      #GC.enable
      img
    end

    # Analyse page layout and return layout information
    # for each page in an image.
    def analyse
      @attrib[:histogram] = histogram
      p(@attrib[:threshold] = otsuThreshold)
      p rightPeak

      fixPageOrientation!
      @pages = findPages

      @pages.each do |page|
        page.analyse
      end

      @pages
    end

    # detect and fix page orientation (if wrong orientation, top at left is assumed)
    def fixPageOrientation!
      vp = Projection.new(self, Projection::VERTICAL)
      vp.highlight.display if $DISPLAY
      hp = Projection.new(self, Projection::HORIZONTAL)
      hp.highlight.display if $DISPLAY
      if vp.to_boxes.size > hp.to_boxes.size
        @angle = 90

        new_data = Array.new(@data.size){255}
        @height.times do |y|
          @width.times do |x|
            new_idx = x*@height + @height-y-1
            new_data[new_idx] = @data[index(x,y)]
          end
        end
        @data = new_data

        tmp = @height
        @height = @width
        @width = tmp

        tmp = @image_height
        @image_height = @image_width
        @image_width = tmp

        @borders.right = @width - 1
        @borders.bottom = @height - 1
      end
    end

    # finds page contents in image and create Page objects
    # (expects that @data is array of bytes)
    def findPages
      pages = []

      if (@width < @height)
        # only one page layout
        pages << Page.new(self, @data, @width, @height, @options)
      else
        # landscape => probably two page layout
        vp = Projection.new(self, Projection::VERTICAL)
        vp.delete_small!
        #vp.join_adjacent!
        vp.highlight.display if $DISPLAY
        boxes =  vp.to_boxes.sort_by{|b| b.width}.reverse

        p1, p2 = boxes[0,2]
        if p2 and (p2.width >= (p1.width-2*@min_content_size))
          lp, rp = p1.left<p2.left ? [p1,p2] : [p2,p1]
          split_x = (lp.right + rp.left) / 2
          point = nil
          boxes[2..-1].each do |b|
            next if b.left<lp.right or b.right>rp.left
            point = b if point==nil or b.height>point.height
          end
          split_x = point.middle[0] if point
          pages << Page.new(self, cut(0, 0, split_x, @height), split_x, @height, @options)
          pages << Page.new(self, cut(split_x, 0, @width, @height), @width-split_x, @height, @options)
          pages[0].position[:right] = pages[1].position[:left] = split_x.to_f/@width
        else
          # one page layout
          pages << Page.new(self, @data, @width, @height, @options)
        end
      end

      pages
    end

    # Deskew Image
    def deskew!
      #@data = @data.deskew(@attrib[:threshold].to_f/255)
      GC.disable
      @data = @data.rotate(-1*@angle)
      GC.enable
    end

    # Convert image color space to 8-bit grayscale
    def desaturate!
      @data = @data.quantize(256, Magick::GRAYColorspace)
    end

    def to_data!
      #@data = @data.dispatch(0,0,@data.columns,@data.rows,"I",true)
      #GC.disable
      @data = @data.export_pixels(0,0,@data.columns,@data.rows,"I")
      coef = 255.to_f / Magick::QuantumRange.to_f
      ScanEnhancer::profile("desaturate: convert to 0-255 range") {
        @data.map!{|pix| (pix*coef).to_i}
      }
      #GC.enable
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
    def cut!(x1, y1, x2, y2); @data = cut(x1,y1,x2,y2); end

    def threshold! t=@attrib[:threshold]
      if @data.is_a? Array
        @data.each_with_index { |pixel, i| @data[i] = (pixel <= t) ? 0 : 255 }
      else
        @data = @data.threshold((t / 255.0) * Magick::QuantumRange)
      end
      self
    end

    def adjacentPixels(cx,cy,data)
      env = []
      ((cy-1)..(cy+1)).each do |y|
        next if y<0 or y>=@height
        ((cx-1)..(cx+1)).each do |x|
          next if x<0 or x>=@width
          i = index(x,y)
          env << [x, y, i, data[i]]
        end
      end
      env
    end


    # set @data to nil
    def free_data!
      @data = nil
    end

    # Return number of pages on the image
    def size
      @pages.size
    end

    # Grayscale 8-bit image histogram
    def histogram
      hist = Array.new(256){0}
      @data.each do |pix|
        hist[pix] += 1
      end
      hist
    end
    def histogram!; @attrib[:histogram] = histogram; end

    # Detect right peak and right valley in image histogram
    def rightPeak
      @attrib[:histogram] ||= histogram
      j = idx = 255
      valley = idx-1
      valley_sum = 0
      max_value = @attrib[:histogram][j]
      (idx-1).downto(0) do |i|
        if @attrib[:histogram][i] >= max_value
          j = i
          max_value = @attrib[:histogram][j]
          valley = j-1
          valley_sum = @attrib[:histogram][valley]
        else
          valley_sum += @attrib[:histogram][i]
        end

        if valley_sum > 0.3*max_value
          valley = i
          valley_sum = 0
        end

        break if (valley-i > 20)
      end
      [valley - 1, j]
    end

    def display_histogram(hist)
      max = 0
      hist.size.times {|i| max=hist[i] if hist[i]>max}

      draw = Magick::Draw.new
      (hist.size-1).times do |x|
        y = 100 - 100*(hist[x]/max.to_f)
        x2, y2 = [x+1, 100 - 100*hist[x+1]/max.to_f]
        draw.line(x, y, x2, y2)
      end

      img = Magick::Image.new(hist.size, 100)
      draw.draw img
      img.display
    end

    # Detect threshold value using otsu method
    def otsuThreshold
      num_pixels = (@width*@height).to_f
      levels = @attrib[:histogram].size
      pixels = [@attrib[:histogram][0]/num_pixels]
      moment = [@attrib[:histogram][0]/num_pixels]
      (levels-1).times do |i|
        pi = @attrib[:histogram][i+1] / num_pixels
        pixels[i+1] = pixels[i] + pi
        moment[i+1] = moment[i] + (i+1)*pi
      end
      #display_histogram(histogram)
      #display_histogram(pixels)
      #display_histogram(moment)

      threshold = 0
      max_variance = 0
      levels.times do |i|
        variance = (moment[-1]*pixels[i] - moment[i])**2 / (pixels[i]*(1-pixels[i]))
        if variance >= max_variance
          max_variance = variance
          threshold = i
        end
      end

      threshold
    end

  end
end
