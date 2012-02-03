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
			Rect *b = page->getBorders();

			cut.x = c->left * ppix->w;
			cut.y = c->top * ppix->h;
			cut.w = c->right * ppix->w - cut.x;
			cut.h = c->bottom * ppix->h - cut.y;
			ppix = pixClipRectangle(ppix, &cut, 0);

			int pw = page->width() * b->width();
			int ph = page->height() * b->height();
			PIX *npix = pixAddBorderGeneral(ppix, c->left * pw, c->top * ph, (1.0-c->right) * pw, (1.0-c->bottom) * ph, 0);
			pixDestroy(&ppix);

			page->setResult(npix);
		};
	};
}
