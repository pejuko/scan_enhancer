#include "../filter.h"

namespace ScanEnhancer {
	class Page;
	class Filter;
	class FilterParams;

	class EqualizeParams : public FilterParams {
		public:
			EqualizeParams(void) : fract(0.50), factor(1) {};
			double fract;
			int factor;
	};

	class FilterEqualize : public Filter {
		virtual FilterParams *new_params(void) { return(new EqualizeParams()); };
		virtual void process(Page *page, FilterParams *params) {
			EqualizeParams *p = (EqualizeParams*)(params);
			PIX *ppix = page->getResult();
			pixEqualizeTRC(ppix, ppix, p->fract, p->factor);
		};
	};
}
