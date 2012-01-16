#include "file.h"
#include "enhancer.h"

#include <iostream>

namespace ScanEnhancer {

Enhancer::Enhancer(ImageFiles *files)
	: p_files(files)
{
	p_images = new Images();
}

Enhancer::~Enhancer(void)
{
	for (int i=0; i<p_images->size(); i++) delete p_images->at(i);
	delete p_images;
}

void Enhancer::analyze(void)
{
	for (int i=0; i<p_files->size(); i++) {
		Images *images = p_files->at(i)->load_images();
		for (int idx=0; idx<images->size(); idx++) {
			Image *img = images->at(idx);
			img->gen_preview();
			img->gen_thumbnail();
			img->free_pix();
			p_images->push_back(img);
		}
		delete images;
		std::cout << i << std::endl;
	}
}

}
