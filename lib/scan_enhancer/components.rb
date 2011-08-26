# -*- coding: utf-8 -*-
# vi: fenc=utf-8:expandtab:ts=2:sw=2:sts=2
# 
# Author::    Petr Kovar (mailto:pejuko@gmail.com)
# Copyright:: Copyright (c) 2011 Petr Kovář
# License::   Distributes under the same terms as Ruby

module ScanEnhancer
 
  class Component < Box
  end

  # TODO: speckles, connect, lines, words, detect should use @image.obj_min_size
  class Components < Array

    attr_reader :bbox

    def initialize(img,components=nil)
      super()
      @image = img

      @bbox = Box.new 9999999999, 9999999999, 0, 0 
      if components
        replace(components)
        bounding_box!
      elsif img
        compute_connected_components
        bounding_box!
      end
    end

    def left; @bbox.left end
    def left=(v); @bbox.left=v end
    def right; @bbox.right end
    def right=(v); @bbox.right=v end
    def top; @bbox.top end
    def top=(v); @bbox.top=v end
    def bottom; @bbox.bottom end
    def bottom=(v); @bbox.bottom=v end
    def width; @bbox.width end
    def height; @bbox.height end
    def middle; @bbox.middle end
    def dist(b); @bbox.dist(b) end
    def intersect?(b); @bbox.intersect?(b) end
    def include?(x,y); @bbox.include?(x,y) end
    def +(b)
      c = Components.new @image, c
      c.join!(b)
    end
    alias :join :+
    def join!(b)
      @bbox.join!(b)
      replace(self | b)
      self
    end

    def compute_connected_components
      peak = @image.rightPeak
      p peak
      p @image.attrib[:threshold]
      threshold = (peak[0]<@image.attrib[:threshold]) ? @image.attrib[:threshold] : peak[0]
      vmos = [1,(@image.min_obj_size)/2].max
      hmos = [1,vmos * 0.5].max
      #hmos = 2
#      hmos = vmos
      #vmos = @image.min_obj_size + 1
      b = @image.borders
      b.height.times do |by|
        #display_components.display if size>0 and by%20==0
        c = nil
        lcs = []
        #p by
        y = by+b.top
        b.width.times do |bx|
          #p bx
          x = bx+b.left
          i = @image.index(x,y)
          next if @image.data[i]>threshold
          if c==nil or (x-c.right)>hmos
            c = Components.new @image, [Component.new(x,y,x,y)]
            lcs.push c
          else
            c.push Component.new(x,y,x,y)
          end
#          p c
        end
#        p "components: #{size}"
#        p "hcomps: #{lcs.size}"
        ucs = select{|a| (y-a.bottom)<=vmos}
#        p "ucs: #{ucs.size}"
        lcs.each_with_index do |lc,i|
          uj = []
          #p lc
          ucs.each do |uc|
            #p uc
            next if lc.left>(uc.right+hmos) or lc.right<(uc.left-hmos)
            uccs = uc.select{|a| d=a.dist(lc); (d[1]<=vmos) and (d[0]<=hmos)}
            uccs.each do |ucc|
              lccs = lc.select{|a| d=a.dist(ucc); (d[1]<=vmos) and (d[0]<=hmos)}
              next if lccs.empty?
              uj << uc
              break
            end
          end
          if uj.empty?
            push lc
          else
            u = uj.shift
            u.join!(lc)
            uj.each{|a| u.join!(a);}
#            lcs.delete(lc)
          end
        end

        joined = true
        while joined
          joined = false
          ucs.each do |uc|
#          jucs = ucs.select{|a| a!=uc and uc.right>=a.left}
            jucs = ucs.select{|a| a.intersect?(uc)}
            jucs.delete(uc)
#            break if jucs.empty?
            jucs.each do |j|
              jcs = j.select{|a| d=a.dist(uc); (d[1]<=vmos) and (d[0]<=hmos)}
              next if jcs.empty?
              joined = true
              uc.join!(j)
              ucs.delete(j)
              delete(j)
            end
          end
        end
#        p "ucs: #{ucs.size}"
#        p "lcs: #{lcs.size}"
#        lcs.each{|a| push a}
#        lcs.each{|a| self << a}
#        p "components: #{size}"
#        puts ""
      end
=begin
      joined = true
      while joined
        p size
        joined = false
        each do |c|
          jcs = select{|a| a.intersect?(c)}
          jcs.delete(c)
          next if jcs.empty?
          joined = true
          jcs.each do |jc|
            c.join!(jc)
            delete(jc)
          end
        end
      end
=end
      #sort_by!{|c| c.middle.reverse}
      p "components: #{size}"
      self
    end

    # remove given components
    def -(cs)
      list = Components.new(@image, self)
      list.delete_if{|x| cs.include?(x)}
      list 
    end

    # append component to array and join with intersected components
    def <<(new_c)
      c = new_c
      intersected = true
      while intersected
        intersected = false
        self.each_with_index do |c2,i|
          next unless c.intersect?(c2)
          c2.join!(c)
          c = delete_at(i)
          intersected = true
          break
        end
        unless intersected
          self.push(c)
          c = nil
        end
      end
      self
    end

    def speckles(ssize=@image.min_obj_size)
      s = []
      each_with_index do |c,i|
        s << c if c.width<=ssize or c.height<=ssize
      end
      Components.new(@image, s)
    end

    def push(*args)
      c = args.first
      #unless @bbox
      #  @bbox = c.dup
      #else
        @bbox.left = c.left if c.left < @bbox.left
        @bbox.right = c.right if c.right > @bbox.right
        @bbox.top = c.top if c.top < @bbox.top
        @bbox.bottom = c.bottom if c.bottom > @bbox.bottom
      #end 
      super *args
    end

    def get(hdist=0.5, vdist=1)
      result = []
      ScanEnhancer::profile("get") {
        all = self.dup
        all.each do |c|
          group = Components.new @image, [c]
          while true
            jcs = all.select{|a| d = a.dist(group.bbox); d[0]<=hdist and d[1]<=vdist}
            break if jcs.empty?
            jcs.each do |jc|
              group.push(jc)
              all.delete(jc)
            end
          end
          result << group
        end
        p result.size
=begin
      get_group = lambda{|c| result.each {|g| return g if g.include?(c)}; g = Components.new @image, [c]; result << g; g}
      group = []
      all = self.dup
      each_with_index do |c,i|
        group = get_group.call(c)
        all.each_with_index do |c2,j|
          next if group.include?(c2)
          d = c.dist(c2)
          if d[0]<=hdist and d[1]<=vdist
            group.push c2
            all.delete_at(j)
          end
        end
      end
=end
      }
      #result.each{|g| g.bounding_box!}
      Components.new @image, result
    end

    def connect(hdist=0.5, vdist=1)
      comp = Components.new(@image, [])
      each do |c|
        newc = c.dup
        each do |c2|
          next if c==c2
          d = newc.dist(c2)
          newc.join!(c2) if d[0]<=hdist and d[1]<=vdist
        end
        comp << newc
      end
      comp
    end

    def words
      connect(7, 1)
    end

    def get_words
      get(7,1)
    end

    def lines
      connect(20, 0)
    end

    def get_lines
      #GC.disable
      result = []
        all = self.dup
        all.each do |c|
          group = Components.new @image, [c]
          while true
            jcs = all.select{|a| d = a.dist(group); d[0]<group.height and ((group.middle[1]-a.middle[1]).abs<=(@image.min_obj_size*2))}
            break if jcs.empty?
            jcs.each do |jc|
              group.push(jc)
              all.delete(jc)
            end
          end
          result << group
        end
      lines = Components.new @image, result

=begin
      result.each do |l|
        lm = l.middle
        jls = result.select{|a| am=a.middle; (lm[1]-am[1]).abs<@image.min_obj_size and a.dist(l)[0]==0}
        jls.each do |jl|
          next if jl==l
          jl.each do |jc|
            jls.push jc
          end
          result.delete(jl)
        end
      end
      lines = Components.new @image, result

#      lines = get(50, 0)
      intersected = true
      while intersected
        intersected = false
        lines.each_with_index do |l,i|
          lines.each_with_index do |l2,j|
            next if l == l2
            lm = l.bbox.middle
            lm2 = l2.bbox.middle
            next if (lm[1] - lm2[1]).abs > @image.min_obj_size
            d = l.bbox.dist(l2.bbox)
            next if d[0] > @image.min_obj_size
            lines.delete_at(j)
            intersected = true
            l2.each do |c|
              l.push c
            end
          end
        end
      end
=end
=begin
      by_height = lines.sort_by{|l| l.bbox.height}
      ref_height = by_height[by_height.size/2]
      lines.delete_if{|l| ((l.bbox.height-2*@image.min_obj_size) > ref_height.bbox.height) or (l.bbox.height<2*@image.min_obj_size)}
      by_width = lines.sort_by{|l| l.bbox.width}
      ref_width = by_width[(by_width.size*0.8).to_i]
      lines.delete_if{|l| (l.bbox.width < ref_width.bbox.width)}
      lines.each{|g| g.sort_by!{|c| c.middle[0]}}
      #GC.enable
=end
      by_height = lines.sort_by{|l| l.height}.delete_if{|l| l.height<2*@image.min_obj_size}
      f,l = ScanEnhancer.segment_by by_height, :height, @image.min_obj_size
      ref_height = by_height[(f+l)/2]
      lines.delete_if{|l| l.height<2*@image.min_obj_size}

      by_width = lines.sort_by{|l| l.bbox.width}.delete_if{|l| l.width<@image.min_obj_size}
      f,l = ScanEnhancer.segment_by by_width, :width, @image.min_content_size
      ref_width = by_width[(f+l)/2]
      lines.delete_if{|l| ((l.width-ref_width.width).abs<@image.min_content_size)}

      lines.each{|g| g.sort_by!{|c| c.middle[0]}}
      lines
    end

    def bounding_box!
      return if empty?

      left = top = 9999999999
      right = bottom = 0

      each do |e|
        c = e
        c = e.bbox if e.class == Components
        left = c.left if c.left < left
        top = c.top if c.top < top
        right = c.right if c.right > right
        bottom = c.bottom if c.bottom > bottom
      end

      @bbox = Box.new left, top, right, bottom
    end



    def highlight(img=@image.constitute, msg=nil, recursive=true)
      each do |c|
        c.highlight img, msg
      end if first.class == Components and recursive
      @bbox.highlight img, msg
    end

    def display_components(img=@image.constitute)
      i = (@img.is_a? Array) ? @image.constitute(img) : img
      self.each do |c|
        c.highlight(i)
      end
      i
    end

  end

end
