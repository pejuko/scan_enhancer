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

    def initialize(img,components=nil)
      super()
      @image = img
      if components
        replace(components)
      elsif img
        compute_connected_components
      end
    end

    def compute_connected_components
      #peak = @image.rightPeak
      threshold = @image.attrib[:threshold]
      vmos = (@image.min_obj_size/2.0)#-0.25
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
      #sort_by!{|c| c.middle}
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

    def lines
      connect(20, 0)
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