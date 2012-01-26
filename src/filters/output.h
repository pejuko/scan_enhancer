#include "../filter.h"

namespace ScanEnhancer {
	class Page;
	class Filter;
	class FilterParams;

	class OutputParams : public FilterParams {
		public:
			OutputParams(void) {};
	};

	class FilterOutput : public Filter {
		virtual FilterParams *new_params(void) { return(new OutputParams()); };
		virtual void process(Page *page, FilterParams *params) {
			OutputParams *p = (OutputParams*)(params);
			PIX *ppix = page->getResult();

			BOX cut;
			Rect *c = page->getContentBox();

			cut.x = c->left * ppix->w;
			cut.y = c->top * ppix->h;
			cut.w = c->right * ppix->w - cut.x;
			cut.h = c->bottom * ppix->h - cut.y;

			ppix = pixClipRectangle(ppix, &cut, 0);
			PIX *npix = pixAddBorderGeneral(ppix, c->left * page->width(), c->top * page->height(), (1.0-c->right) * page->width(), (1.0-c->bottom) * page->height(), 0);
			pixDestroy(&ppix);
			page->setResult(npix);
		};
	};
}
