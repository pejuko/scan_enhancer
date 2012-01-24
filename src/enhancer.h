#ifndef _SCAN_ENHANCER_
#define _SCAN_ENHANCER_

#include "file.h"

namespace ScanEnhancer {

class Enhancer {
public:
	Enhancer(ImageFiles *files);
	~Enhancer(void);

	void analyze(void);
	void export_result(void);

private:
	ImageFiles *p_files;
	Images     *p_images;
	FilterQueue m_filterQueue;
};

};

#endif
