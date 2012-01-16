#include "image.h"


namespace ScanEnhancer {


void Image::gen_preview(void)
{
	if (p_preview) delete p_preview;

	p_preview = pixScaleToSize(p_pix, 800, 0);
}

void Image::gen_thumbnail(void)
{
	if (p_thumbnail) delete p_thumbnail;

	p_thumbnail = pixScaleToSize(p_preview, 160, 0);
}

void Image::free_pix(void)
{
	if (p_pix) delete p_pix;
	p_pix = 0;
}

Image::~Image(void)
{
	if (p_pix) delete p_pix;
	if (p_preview) delete p_preview;
	if (p_thumbnail) delete p_thumbnail;
}

};
