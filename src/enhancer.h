#ifndef _SCAN_ENHANCER_
#define _SCAN_ENHANCER_

#include "file.h"

namespace ScanEnhancer {

class Enhancer {
public:
	Enhancer(ImageFiles *files);
	void analyze(void);

private:
	ImageFiles *p_files;
};

};

#endif
