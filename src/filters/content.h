#include "../filter.h"

namespace ScanEnhancer {
	class Page;
	class Filter;
	class FilterParams;

	class ContentParams : public FilterParams {
		public:
			ContentParams(void) : left(0.0), top(0.0), right(1.0), bottom(1.0) {};
			bool isMax(void) { return (left==0.0) && (right==1.0) && (top==0.0) && (bottom==1.0); };

			double left, top, right, bottom;
	};

	class FilterContent : public Filter {
		virtual FilterParams *new_params(void) { return(new ContentParams()); };
		virtual void process(Page *page, FilterParams *params) {
			ContentParams *p = (ContentParams*)(params);
			PIX *ppix = page->getResult();

			if (p->isMax()) {
				BOX *cbox = 0;
				BOXA *boxa;
				NUMA *na;
				NUMAA *naa;

				pixGetWordBoxesInTextlines(ppix, 1, 5, 8, ppix->w/2, 100, &boxa, &na);
				naa = boxaExtractSortedPattern(boxa, na);
				//boxa = pixConnCompBB(ppix, 4);
				boxaGetExtent(boxa, 0, 0, &cbox);

				p->left = double(cbox->x) / double(ppix->w);
				p->top = double(cbox->y) / double(ppix->h);
				p->right = p->left + double(cbox->w) / double(ppix->w);
				p->bottom = p->top + double(cbox->h) / double(ppix->h);

				page->setContentBox(p->left, p->top, p->right, p->bottom);

				boxDestroy(&cbox);
				boxaDestroy(&boxa);
				numaDestroy(&na);
				numaaDestroy(&naa);
			}
		};
	};
}
