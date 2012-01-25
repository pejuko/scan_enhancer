#include "../filter.h"

namespace ScanEnhancer {
	class Page;
	class Filter;
	class FilterParams;

	class DewarpParams : public FilterParams {
		public:
			DewarpParams(void) {};
	};

	class FilterDewarp: public Filter {
		virtual FilterParams *new_params(void) { return(new DewarpParams()); };
		virtual void process(Page *page, FilterParams *params) {
			DewarpParams *p = (DewarpParams*)(params);
			PIX *ppix = page->getResult();
			/*
			PIX *ppixs = pixScaleToSize(ppix, 800, 0);
			PIX *pixt, *pixt2;
			PTAA *ptaa;

			ptaa = pixGetTextlineCenters(ppixs, 0);
			pixt = pixCreateTemplate(ppixs);
			pixt2 = pixDisplayPtaa(pixt, ptaa);
			pixDisplayWithTitle(pixt2, 500, 100, "text line centers", 1);
			*/

			L_DEWARP *dew = dewarpCreate(ppix, 0, 60, 3, 1);
			dewarpBuildModel(dew, 0);
			dewarpApplyDisparity(dew, ppix, 0);
			dewarpDestroy(&dew);

			//page->setResult(ppix);
		};
	};
}
