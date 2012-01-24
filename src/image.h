#ifndef _SCAN_IMAGE_
#define _SCAN_IMAGE_

#include "file.h"
#include "page.h"

#include <vector>
#include <string>

extern "C" {
#include <leptonica/allheaders.h>
}

namespace ScanEnhancer {

class ImageFile;
class Page;

class Image {
public:
	Image(PIX *pix, ImageFile *ifile);
	~Image(void);

	void gen_preview(void);
	void gen_thumbnail(void);
	void free_pix(void);
	void clear_pages(void);
	void analyse(void);
	void export_result(std::string prefix);

	PIX *cut(double left, double top, double right, double bottom);
	void find_pages(void);

	int width(void) const { return m_width; };
	int height(void) const { return m_height; };

private:
	PIX *p_pix;
	PIX *p_preview;
	PIX *p_thumbnail;
	std::vector<Page*> *p_pages;
	ImageFile *p_file;
	int m_width, m_height;
};

typedef std::vector<Image*> Images;

}

#endif
