#include "../filter.h"

namespace ScanEnhancer {
	class Page;
	class Filter;
	class FilterParams;

	class DeskewParams : public FilterParams {
		public:
			DeskewParams(void) : angle(1000) {};
			double angle;
	};

	class FilterDeskew : public Filter {
		virtual FilterParams *new_params(void) { return(new DeskewParams()); };
		virtual void process(Page *page, FilterParams *params) {
			DeskewParams *p = (DeskewParams*)(params);
			PIX *pix;
			if (p->angle == 1000) {
				pix = pixFindSkewAndDeskew(page->getResult(), 0, (l_float32*)(&(p->angle)), 0);
			} else {
				double deg2rad = 3.1415926535 / 180.;
				pix = pixRotate(page->getResult(), deg2rad * p->angle, L_ROTATE_AREA_MAP, L_BRING_IN_WHITE, 0, 0);
			}
			page->setResult(pix);
		};
	};
}
