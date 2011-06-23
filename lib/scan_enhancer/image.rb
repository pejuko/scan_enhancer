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
    include Utils
    
    attr_reader :data, :pages, :attrib

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
      @attrib[:borders] = {}
      @attrib[:borders][:left] = 0
      @attrib[:borders][:top] = 0
      @attrib[:borders][:right] = @width - 1
      @attrib[:borders][:bottom] = @height - 1
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
      @pages = findPages

      @pages.each do |page|
        page.analyse
      end

      @pages
    end

    # find page contents in image and create Page objects
    # (expects that @data is array of bytes, and the image is well orientated)
    def findPages
#      @attrib[:borders] = detectBorders
      @attrib[:vertical_projection] = verticalProjection
      splitPages
    end

    # Split pages based on vertical projection
    def splitPages
      pages = []
      boxes =  computeContents(@attrib[:vertical_projection], :vertical).sort_by{|c| @width-(c[1]-c[0])}

      if (@width < @height)
        # only one page content => return the largest one
        pages << Page.new(@data, @width, @height, @options)
      else
        # landscape => probably two page layout
        p1, p2 = boxes[0,2]
        w1 = p1[1] - p1[0]
        if p2 and ((p2[1]-p1[0]) >= (w1-2*@min_content_size))
          lp, rp = p1[0]<p2[0] ? [p1,p2] : [p2,p1]
          middle = (lp[1] + rp[0]) / 2
          point = []
          boxes[2..-1].each do |b|
            next if b[0]<lp[1] or b[1]>rp[0]
            point = b if point.empty? or b[2]>point[2]
          end
          point = [middle,middle, 1] if point.empty?
          split_point = (point[0] + point[1]) / 2
          pages << Page.new(cut(0, 0, split_point, @height), split_point, @height, @options)
          pages << Page.new(cut(split_point, 0, @width, @height), @width-split_point, @height, @options)
          pages[0].position[:right] = pages[1].position[:left] = split_point.to_f/@width
        else
          # one page layout
          pages << Page.new(@data, @width, @height, @options)
        end
      end

      pages
    end

    # Convert image color space to 8-bit grayscale
    def desaturate!
      @data = @data.quantize(256, Magick::GRAYColorspace).dispatch(0,0,@data.columns,@data.rows,"I",true).map{|pix| (255*pix).to_i}
    end

    # Return number of pages on the image
    def size
      @pages.size
    end

  end
end
