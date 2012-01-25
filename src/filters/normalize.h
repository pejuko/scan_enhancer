#include "../filter.h"

namespace ScanEnhancer {
	class Page;
	class Filter;
	class FilterParams;

	class FilterNormalize : public Filter {
		virtual FilterParams *new_params(void) { return(new FilterParams()); };
		virtual void process(Page *page, FilterParams *params) {
			PIX *pix = pixBackgroundNormSimple(page->getResult(), 0, 0);
			page->setResult(pix);
		};
	};
}
