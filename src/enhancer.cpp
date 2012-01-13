#include "file.h"
#include "enhancer.h"

#include <iostream>

namespace ScanEnhancer {

Enhancer::Enhancer(ImageFiles *files)
	: p_files(files)
{
}


void Enhancer::analyze(void)
{
	for (int i=0; i<p_files->size(); i++) {
		Images *images = p_files->at(i)->load_images();
		std::cout << i << std::endl;
	}
}

}
