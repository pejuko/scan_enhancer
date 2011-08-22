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
      @bbox = nil
      if components
        replace(components)
        bounding_box!
      elsif img
        compute_connected_components
        bounding_box!
      end
    end

    def compute_connected_components
      #peak = @image.rightPeak
      threshold = @image.attrib[:threshold]
      vmos = (@image.min_obj_size/2)
      hmos = vmos * 0.6
      #vmos = 1
      #hmos = 0.5
      b = @image.borders
      b.height.times do |by|
        b.width.times do |bx|
          x,y = [bx+b.left, by+b.top]
          i = @image.index(x,y)
          next if @image.data[i]>threshold
          x1 = [0,x-hmos].max
          y1 = [0,y-vmos].max
          x2 = [b.right, x+hmos].min
          y2 = [b.bottom, y+vmos].min
          self << Component.new(x1, y1, x2, y2)
        end
      end
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
      unless @bbox
        @bbox = c.dup
      else
        @bbox.left = c.left if c.left < @bbox.left
        @bbox.right = c.right if c.right > @bbox.right
        @bbox.top = c.top if c.top < @bbox.top
        @bbox.bottom = c.bottom if c.bottom > @bbox.bottom
      end 
      super *args
    end

    def get(hdist=0.5, vdist=1)
      result = []
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
      #result.each{|g| g.bounding_box!}
      Components.new @image, result
    end

    def connect(hdist=0.5, vdist=1)
      comp = Components.new(@image, [])
      each do |c|
        newc = c.dup
        each do |c2|
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
      lines = get(50, 0)
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
      by_height = lines.sort_by{|l| l.bbox.height}
      ref_height = by_height[by_height.size/2]
      lines.delete_if{|l| ((l.bbox.height-2*@image.min_obj_size) > ref_height.bbox.height) or (l.bbox.height<2*@image.min_obj_size)}
      by_width = lines.sort_by{|l| l.bbox.width}
      ref_width = by_width[(by_width.size*0.8).to_i]
      lines.delete_if{|l| (l.bbox.width < ref_width.bbox.width)}
      lines.each{|g| g.sort_by!{|c| c.middle[0]}}
      #GC.enable
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



    def highlight(img=@image.constitute, msg=nil)
      each do |c|
        c.highlight img, msg
      end if first.class == Components
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
