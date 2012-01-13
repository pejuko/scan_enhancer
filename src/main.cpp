#include "file.h"
#include "image.h"
#include "enhancer.h"

#include <iostream>

int main(int argc, char **argv)
{
	ScanEnhancer::ImageFiles files;

	for (int i=1; i<argc; i++) {
		files.push_back( new ScanEnhancer::ImageFile(argv[i]) );
	}

	ScanEnhancer::Enhancer enhancer(&files);
	enhancer.analyze();

	for (int i=0; i<files.size(); i++) {
		delete files[i];
	}

	return 0;
}
