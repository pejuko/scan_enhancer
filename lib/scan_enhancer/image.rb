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
    
    attr_reader :data, :pages, :attrib, :width, :height, :borders, :min_obj_size, :min_content_size, :vertical_projection, :horizontal_projection, :filename, :filepage, :depth

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
      Magick::Image.constitute(@width, @height, "I", idata.map{|pix| (pix*coef).to_i})
    end

    # Analyse page layout and return layout information
    # for each page in an image.
    def analyse
      @attrib[:histogram] = histogram
      @attrib[:threshold] = otsuThreshold
      @pages = findPages

      @pages.each do |page|
        page.analyse
      end

      @pages
    end

    # find page contents in image and create Page objects
    # (expects that @data is array of bytes, and the image is well orientated)
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
      @data = @data.deskew(@attrib[:threshold].to_f/255)
    end

    # Convert image color space to 8-bit grayscale
    def desaturate!
      @data = @data.quantize(256, Magick::GRAYColorspace)
    end

    def to_data!
      #@data = @data.dispatch(0,0,@data.columns,@data.rows,"I",true)
      @data = @data.export_pixels(0,0,@data.columns,@data.rows,"I")
      coef = 255.to_f / Magick::QuantumRange.to_f
      ScanEnhancer::profile("desaturate: convert to 0-255 range") {
        @data.map!{|pix| (pix*coef).to_i}
      }
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
#      p @attrib[:histogram]
      j = idx = 255
      valley = idx-1
      valley_sum = 0
      max_value = @attrib[:histogram][j]
      (idx-1).downto(0) do |i|
        if @attrib[:histogram][i] >= max_value
          j = i
          max_value = @attrib[:histogram][j]
          valley = j-1
          valley_sum = 0
        else
          valley_sum += @attrib[:histogram][i]
        end

        if valley_sum > 0.3*max_value
          valley = i
          valley_sum = 0
        end

        break if (valley-i > 70)
      end
      [valley - 1, j]
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
