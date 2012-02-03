#include "../filter.h"

namespace ScanEnhancer {
	class Page;
	class Filter;
	class FilterParams;

	class DekeystoneParams : public FilterParams {
		public:
			DekeystoneParams(void) {};
	};

	class FilterDekeystone : public Filter {
		virtual FilterParams *new_params(void) { return(new DekeystoneParams()); };
		virtual void process(Page *page, FilterParams *params) {
			DekeystoneParams *p = (DekeystoneParams*)(params);
			PIX *ppix = page->getPicture();
			PIX *deskew = pixDeskewLocal(ppix, 10, 0, 0, 0.0, 0.0, 0.0);
			page->setResult(deskew);
		};
	};
}
