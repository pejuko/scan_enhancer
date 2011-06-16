# -*- coding: utf-8 -*-
# vi: fenc=utf-8:expandtab:ts=2:sw=2:sts=2
# 
# Author::    Petr Kovar (mailto:pejuko@gmail.com)
# Copyright:: Copyright (c) 2011 Petr Kovář
# License::   Distributes under the same terms as Ruby

module ScanEnhancer

  # Detected page information in an image.
  class Page

    #def initialize(img, x, y, width, height)
    def initialize(img)
      @image = img
      #@x, @y, @width, @height = x, y, width, height
    end
  end
end
