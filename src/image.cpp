#include "image.h"


namespace ScanEnhancer {

Image::~Image(void)
{
	if (p_pix) delete p_pix;
}

};
