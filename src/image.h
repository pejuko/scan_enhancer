#ifndef _SCAN_IMAGE_
#define _SCAN_IMAGE_

#include "file.h"

#include <vector>

extern "C" {
#include <leptonica/allheaders.h>
}

namespace ScanEnhancer {

class ImageFile;

class Image {
public:
	Image(PIX *pix, ImageFile *ifile) : p_pix(pix), p_file(ifile) {};
	~Image(void);

private:
	PIX *p_pix;
	ImageFile *p_file;
};

typedef std::vector<Image*> Images;

}

#endif
