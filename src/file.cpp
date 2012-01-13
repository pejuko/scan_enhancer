#include "file.h"

namespace ScanEnhancer {

Image *ImageFile::load_image(int idx)
{
	std::vector<Image*> *images = load_images();
	Image *image = images->at(idx);
	for (int i=0; i<images->size(); i++) {
		if (i != idx) delete images->at(i);
	}
	delete images;
	return image;
}

Images *ImageFile::load_images(void)
{
	Images *images = new std::vector<Image*>();

	images->push_back(new Image(pixRead(m_fname.c_str()), this));

	m_images = images->size();

	return images;
}

};
