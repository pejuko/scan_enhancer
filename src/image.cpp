#include "image.h"

#include <string>
#include <sstream>

namespace ScanEnhancer {

Image::Image(PIX *pix, ImageFile *ifile)
	: p_pix(pix), p_preview(0), p_thumbnail(0), p_file(ifile), m_width(pix->w), m_height(pix->h)
{
	p_pages = new Pages();
}

void Image::gen_preview(void)
{
	if (p_preview) pixDestroy(&p_preview);

	p_preview = pixScaleToSize(p_pix, 800, 0);
}

void Image::gen_thumbnail(void)
{
	if (p_thumbnail) pixDestroy(&p_thumbnail);

	p_thumbnail = pixScaleToSize(p_preview, 160, 0);
}

void Image::free_pix(void)
{
	if (p_pix) pixDestroy(&p_pix);
}

void Image::clear_pages(void)
{
	if (p_pages) {
		for (int i=0; i<p_pages->size(); i++) {
			delete p_pages->at(i);
		}
	} else {
		p_pages = new Pages();
	}
	p_pages->clear();
}

void Image::analyse(void)
{
	find_pages();
	for (int i=0; i<p_pages->size(); i++) {
		p_pages->at(i)->analyse();
	}
}

void Image::export_result(std::string prefix)
{
	for (int i=0; i<p_pages->size(); i++) {
		std::stringstream fname;
		fname << prefix << "_" << i+1 << ".tif";
		p_pages->at(i)->export_result(fname.str());
	}
}

PIX *Image::cut(double left, double top, double right, double bottom)
{
	BOX cbox;
	cbox.x = int(m_width * left);
	cbox.y = int(m_height * top);
	cbox.w = int(m_width * (right-left));
	cbox.h = int(m_height * (bottom-top));

	return pixClipRectangle(p_pix, &cbox, 0);
}

void Image::find_pages(void)
{
	clear_pages();
	p_pages->push_back(new Page(this, 0.0, 0.0, 1.0, 1.0));
}

Image::~Image(void)
{
	if (p_pix) pixDestroy(&p_pix);
	if (p_preview) pixDestroy(&p_preview);
	if (p_thumbnail) pixDestroy(&p_thumbnail);
	clear_pages();
	delete p_pages;
}

};
