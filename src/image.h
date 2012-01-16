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
	Image(PIX *pix, ImageFile *ifile) : p_pix(pix), p_preview(0), p_thumbnail(0), p_file(ifile) {};
	~Image(void);

	void gen_preview(void);
	void gen_thumbnail(void);
	void free_pix(void);

private:
	PIX *p_pix;
	PIX *p_preview;
	PIX *p_thumbnail;
	ImageFile *p_file;
};

typedef std::vector<Image*> Images;

}

#endif
