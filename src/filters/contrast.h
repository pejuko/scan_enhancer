#ifndef _SCAN_FILTER_CONTRAST_
#define _SCAN_FILTER_CONTRAST_

#include "../filter.h"

namespace ScanEnhancer {
	class Page;
	class Filter;
	class FilterParams;

	class ContrastParams : public FilterParams {
		public:
			ContrastParams(void) : factor(0.5) {};
			double factor;
	};

	class FilterContrast : public Filter {
		virtual FilterParams *new_params(void) { return(new EqualizeParams()); };
		virtual void process(Page *page, FilterParams *params) {
			ContrastParams *p = (ContrastParams*)(params);
			PIX *ppix = page->getResult();
			pixContrastTRC(ppix, ppix, p->factor);
		};
	};
}

#endif
