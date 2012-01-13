#ifndef _SCAN_IMAGE_FILE_
#define _SCAN_IMAGE_FILE_

#include "image.h"

#include <string>
#include <vector>

namespace ScanEnhancer {

class Image;

class ImageFile {
public:
	ImageFile(std::string fname) : m_fname(fname) {};

	Image *load_image(int idx);
	std::vector<Image*> *load_images(void);

	int count(void) const { return m_images; };

private:
	std::string m_fname;
	int m_images;
};

typedef std::vector<ImageFile*> ImageFiles;
}

#endif
