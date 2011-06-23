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
      @mask = Magick::Image.constitute(@width, @height, "I", @data).threshold(@attrib[:threshold])
      @mask.display
      @pages = findPages
      @pages
    end

    # find page contents in image and create Page objects
    # (expects that @data is array of bytes, and the image is well orientated)
    def findPages
#      @attrib[:borders] = detectBorders
      @attrib[:vertical_projection] = verticalProjection
      #pages = splitPages
      @attrib[:horizontal_projection] = horizontalProjection
      display_content_mask @attrib[:vertical_projection]
      display_content_mask @attrib[:horizontal_projection], :horizontal

      content = computeContentBox(@attrib[:vertical_projection], @attrib[:horizontal_projection])
      highlight content, "Content Box"

      #pp content
      []
    end

    # Split pages based on vertical projection
    def splitPages
      pages = []
      boxes =  computeContents(@attrib[:vertical_contents], :vertical).sort_by{|c| c[1]-c[0]}

      if @width < @height
        # only one page content => return the largest one
        pages << Page.new(@data, @width, @height)
      else
        # probably two page layout
      end

      pages
    end

    # Convert image color space to 8-bit grayscale
    def desaturate!
      @data = @data.quantize(256, Magick::GRAYColorspace).dispatch(0,0,@data.columns,@data.rows,"I",true).map{|pix| (255*pix).to_i}
      @attrib[:desaturated] = true
    end

    # Return number of pages on the image
    def size
      @pages.size
    end

  end
end
