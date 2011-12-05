# -*- coding: utf-8 -*-
# vi: fenc=utf-8:expandtab:ts=2:sw=2:sts=2
# 
# Author::    Petr Kovar (mailto:pejuko@gmail.com)
# Copyright:: Copyright (c) 2011 Petr Kovář
# License::   Distributes under the same terms as Ruby

module ScanEnhancer

  # Detected page information in an image.
  class Page < Image

    attr_reader :position, :content, :borders, :angle

    def initialize(image, data, width, height, opts)
      @options = opts
      @image = image
      @filename = @image.filename
      @filepage = @image.filepage
      @attrib = {}
      @data = data
      @width = width
      @height = height
      @position = {:left => 0.0, :top => 0.0, :right => 1.0, :bottom => 1.0}
#      @min_obj_size = [2, ((@height*@width) / (@options[:dpi]**2) + 1)/2].max
      @min_obj_size = [2, (@height*@width) / ((@options[:working_dpi]*4)**2) + 1].max
      @min_content_size = (@min_obj_size * Math.sqrt((@height*@width) / (@options[:working_dpi]**2))).to_i
      @borders = Box.new(0, 0, @width-1, @height-1)
      @angle = 0
      info
    end

    def analyse
      ScanEnhancer::profile("get histogram and threshold") {
        @attrib[:histogram] = histogram
        @attrib[:threshold] = otsuThreshold
        @attrib[:peak] = rightPeak
      }

      ScanEnhancer::profile("borders detect") {
        @borders = Borders.new(self)
        @borders.fineTuneBorders!
      }
      @borders.highlight(constitute, "Borders").display if $DISPLAY

      ScanEnhancer::profile("vertical projection") {
        @vertical_projection = Projection.new(self, Projection::VERTICAL)
        @vertical_projection.join_adjacent!
        @vertical_projection.delete_small!
      }

      ScanEnhancer::profile("horizontal projection") {
        @horizontal_projection = Projection.new(self, Projection::HORIZONTAL)
        @horizontal_projection.join_adjacent!
        @horizontal_projection.delete_small!
      }

      ScanEnhancer::profile("content detection") {
        @content = Content.new(self)
        @content.fineTuneContentBox!
      }
      @content.highlight.display if $DISPLAY

      ScanEnhancer::profile("conected components") {
        @components = Components.new(self)
        @components.display_components.display if $DEBUG or $DISPLAY
      }
      ScanEnhancer::profile("get_lines") {
        @lines = []
        @lines = @components.get_lines
      }
      if $DISPLAY or $DEBUG
        img = constitute
        gc = Magick::Draw.new
        #@components.each do |l|
        #  l.highlight img, nil, false
        #end
      end
      angles = []

      @lines.each_with_index do |line|
        cross_baseline = lambda {|j|
          c, pc, nc = line[j], line[j-1], line[j+1]
          (pc and (c.bottom-pc.bottom)>@min_obj_size/2) or
          (nc and (c.bottom-nc.bottom)>@min_obj_size/2)
        }

        height = line.height
        #slh = sl.sort_by{|c| c.height}
        slh = line.sort_by{|c| c.height}
        slh.each_with_index do |c,i|
          slh.delete_at(i) if cross_baseline.call(i)
        end
        f = f2 = l = 0
        h = slh.first.height
        slh.each_with_index do |c,i|
          next c.height-h < @image.min_obj_size
          if i-1-f2 > l-f
            f = f2
            l = i-1
          end
          while f2<slh.size and c.height-slh[f2].height > @image.min_obj_size
            f2 += 1
          end
          h = slh[f2].height
        end
        if slh.size-1-f2 > l-f
          f = f2
          l = slh.size-1
        end
        nc = slh[(f+l)/2]
        sl = line.select{|c| ((c.height-nc.height).abs<=@image.min_obj_size) and (not cross_baseline.call(line.index(c)))}
        next if sl.empty?
        i = line.index(nc)
        nci = sl.index(nc)
        search_similar = lambda{|i,inc,max|
          tmp = sl[i]
          while i!=max
            c = sl[i]
            ci = line.index(c)
            if (tmp.bottom-c.bottom).abs <= @min_obj_size/2
              tmp = c
            end
            i += inc
          end
          tmp
        }
        next unless nci
        first = search_similar.call(nci,-1,-1)
        last = search_similar.call(nci,1,sl.size)
        angle = 0.0
        if first!=last
          c = last.middle[0] - first.middle[0]
          b = first.bottom - last.bottom
          angle = Math.atan(b.to_f / c.to_f) * (180.0/Math::PI)
          angles <<  [angle,c]
        end
        if $DISPLAY or $DEBUG
          nc.highlight img
          first.highlight img
          last.highlight img
          gc.line(first.middle[0], first.bottom, last.middle[0], last.bottom)
          line.highlight img, "#{angle}", false
        end
      end
#      p angles
#      angles = ScanEnhancer.segment_by(angles, :last, @min_obj_size)
      angles.sort_by!{|a| a[0].abs}
      p angles
      @angle = angles.first[0]
      p @angle
      #@lines.highlight img
=begin
      if $DISPLAY2 or $DEBUG
        @lines.each_with_index do |g,j|
          g.display_components(img)
          g.highlight img, j.to_s
          g.each_with_index do |c,i|
            if i>0
              x1 = g[i-1].middle[0]
              y1 = g[i-1].bottom
              x2 = g[i].middle[0]
              y2 = g[i].bottom
              gc.line( x1, y1, x2, y2 )
            end
          end
        end
      end
=end
      if $DISPLAY or $DEBUG
        gc.draw(img) unless @lines.empty?
        img.display
      end
=begin
      @words = @components.words
      @lines = @words.lines
      @speckles = @lines.speckles(@min_obj_size*2)
      @components.display_components.display # if $DISPLAY
      @words.display_components.display
      @lines.display_components.display
      @speckles.display_components.display
      (@lines - @speckles).display_components.display
=end
    end

    def load_original
      super
      @content.remap!
    end

    def export(file_name)
      iw = @image.image_width * (@position[:right] - @position[:left])
      ih = @image.image_height * (@position[:bottom] - @position[:top])
      c = @content.to_f(iw, ih).map{|x| x.to_i}
      b = @borders.to_f(iw, ih).map{|x| x.to_i}

      if @position[:left] > 0
        s = @image.image_width * @position[:left]
        c[0] += s
        c[2] += s
        b[0] += s
        b[2] += s
      end
      #if @position[:right] < 1
      #  c[2] -= @image.image_width * (1-@position[:right])
      #end

      chop = "-fill white"
      chop += %~ -draw "rectangle 0,0 #{iw},#{c[1]-1}"~
      chop += %~ -draw "rectangle 0,0 #{c[0]-1},#{@image.image_height}"~
      chop += %~ -draw "rectangle 0,#{c[3]+1} #{@image.image_width},#{@image.image_height}"~
      chop += %~ -draw "rectangle #{c[2]+1},0 #{@image.image_width},#{@image.image_height}"~

      w = b[2]-b[0]
      h = b[3]-b[1]
      crop = %~-crop "#{w}x#{h}+#{b[0]}+#{b[1]}"~

      rotate = ""
      if @angle
        rotate = %~-rotate "#{@angle}"~
        threshold = %~-threshold #{@attrib[:threshold]}~
      end

      threshold = %~-threshold "#{@attrib[:threshold]}"~

      if @image.filename =~ /.pdf$/i
        src = "#{@image.filename}[#{@image.filepage}]"
      else
        src = @image.filename
      end
      cmd = %~gm convert #{src} #{chop} #{crop} #{rotate} #{threshold} #{file_name}~
#      cmd = %~gm convert "#{@image.filename}[#{@image.filepage}]" -crop "#{c[2]-c[0]}x#{c[3]-c[1]}+#{c[0]}+#{c[1]}" -rotate #{@angle} -threshold #{@attrib[:threshold]} #{file_name}~
      puts cmd
      system(cmd)

=begin
      GC.disable
      img = @data
      img = constitute if @data.is_a? Array
      depth = @image.depth.to_i
      img.write(file_name) {
        if depth > 1
          self.compression = Magick::ZipCompression
        else
          self.compression = Magick::FaxCompression
        end
      }
      GC.enable
=end
    end
  end
end
