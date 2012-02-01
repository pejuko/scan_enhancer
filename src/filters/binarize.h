#include "../filter.h"

namespace ScanEnhancer {
	class Page;
	class Filter;
	class FilterParams;

	class BinarizeParams : public FilterParams {
		public:
			BinarizeParams(void) : threshold(-1) {};
			int threshold;
	};

	class FilterBinarize : public Filter {
		virtual FilterParams *new_params(void) { return(new BinarizeParams()); };
		virtual void process(Page *page, FilterParams *params) {
			BinarizeParams *p = (BinarizeParams*)(params);
			PIX *pix, *mask;
			PIX *pixg = pixRemoveColormap(page->getResult(), REMOVE_CMAP_TO_GRAYSCALE);
			PIX *ppix = pixConvertTo8(pixg, FALSE);

			if (p->threshold == -1) {
				PIX *pt;
				pixOtsuAdaptiveThreshold(ppix, ppix->w, ppix->h, 0, 0, 0, &pt, 0); 
                pixGetPixel(pt, 0, 0, (l_uint32*)&(p->threshold));
				pixDestroy(&pt);
			}
			pix = pixThresholdToBinary(ppix, p->threshold);
			mask = pixGenHalftoneMask(pix, 0, 0, 1);
			pixInvert(mask, mask);
			ppix = pixConvertTo32(page->getPicture());
			PIX *gpix = pixConvertTo32(pix);
			pixCombineMasked(ppix, gpix, mask);

			pixDestroy(&mask);
			pixDestroy(&pix);
			pixDestroy(&pixg);
			pixDestroy(&gpix);

			page->setResult(ppix);
		};
	};
}
