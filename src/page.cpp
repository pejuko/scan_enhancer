#include "page.h"

#include <iostream>
#include <string>
#include <sstream>

namespace ScanEnhancer {

Page::Page(Image *img, double left, double top, double right, double bottom)
	: p_image(img), m_left(left), m_top(top), m_right(right), m_bottom(bottom), p_result(0), m_content(), m_borders()
{
	p_pix = p_image->cut(left, top, right, bottom);
	m_width = p_pix->w;
	m_height = p_pix->h;
	p_result = pixClone(p_pix);
}

void Page::free_pix(void)
{
	if (p_pix) pixDestroy(&p_pix);
}

void Page::free_result(void)
{
	if (p_result) pixDestroy(&p_result);
}

void Page::clear_params(void)
{
	for (int i=0; i<params.size(); i++) {
		delete params[i];
	}
	params.clear();
}

void Page::analyse(void)
{
	free_result();
	p_result = pixFindSkewAndDeskew(p_pix, 0, (l_float32*)(&m_angle), 0);
}

void Page::export_result(std::string fname)
{
	std::cout << "out: " << fname << std::endl;
	pixWrite(fname.c_str(), p_result, IFF_TIFF_LZW);
}

Page::~Page(void)
{
	free_pix();
	free_result();
}

}
