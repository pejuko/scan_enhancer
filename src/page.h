#ifndef _SCAN_PAGE_
#define _SCAN_PAGE_

#include "image.h"
#include "filter.h"

#include <vector>
#include <string>

extern "C" {
#include <leptonica/allheaders.h>
}

namespace ScanEnhancer {

class Image;
class Filter;
class FilterParams;
class FilterQueue;

class Page {
public:
	Page(Image *img, double left, double top, double right, double bottom);
	~Page(void);

	void free_pix(void);
	void free_result(void);
	void clear_params(void);

	void analyse(void);
	void export_result(std::string fname);

	PIX *getResult(void) { return p_result; };
	void setResult(PIX *pix) { free_result(); p_result = pix; };

	int width(void) const { return m_width; };
	int height(void) const { return m_height; };

private:
	Image *p_image;
	double m_left, m_top, m_right, m_bottom;
	PIX   *p_pix, *p_result;
	double m_width, m_height;
	double m_angle;
	std::vector<FilterParams*> params;

	friend class FilterQueue;
};

typedef std::vector<Page*> Pages;

}

#endif
