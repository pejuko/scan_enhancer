module ScanEnhancer
  class ImageFile
    
    attr_reader :path

    def initialize file
      @path = file
      @images = Magick::Image.read @path
    end

    def image idx=0
      @images[idx]
    end

    def loaded?
      @images.size > 0
    end

    def size
      @images.size
    end

    def file_name
      File.basename @path
    end

    def directory
      File.dirname @path
    end

  end
end
