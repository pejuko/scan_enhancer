#ifndef _SCAN_FILTER_BORDERS_
#define _SCAN_FILTER_BORDERS_

#include "../filter.h"
#include "../rect.h"

#include <iostream>

namespace ScanEnhancer {
	class Page;
	class Filter;
	class FilterParams;

	class BordersParams : public FilterParams {
		public:
			BordersParams(void) : borders() {};
			Rect borders;
	};

	class FilterBorders : public Filter {
		enum Direction {VERTICAL, HORIZONTAL};

		virtual FilterParams *new_params(void) { return(new EqualizeParams()); };
		virtual void process(Page *page, FilterParams *params) {
			BordersParams *p = (BordersParams*)(params);

			PIX *ppix = pixScaleToSize(page->getResult(), 800, 0);
			PIX *pixg = pixRemoveColormap(ppix, REMOVE_CMAP_TO_GRAYSCALE);
			PIX *pix = pixConvertTo8(pixg, FALSE);

			PIX *pt;
			l_uint32 threshold;
			pixOtsuAdaptiveThreshold(pix, pix->w, pix->h, 0, 0, 0, &pt, 0); 
			pixGetPixel(pt, 0, 0, &threshold);
			pixDestroy(&pt);

			PIX *pixb = pixThresholdToBinary(pix, threshold);

			pixDestroy(&ppix);
			pixDestroy(&pixg);
			pixDestroy(&pix);

			detectBorders(pixb, p);
			fineTuneBorders(pixb, p);

			page->setBorders(&(p->borders));

			std::cout << p->borders.toString() << std::endl;

			pixDestroy(&pix);

			ppix = page->getResult();
			BOX *cut = p->borders.toBox(ppix);
			page->setResult(pixClipRectangle(ppix, cut, 0));
		};


	private:

		void detectBorders(PIX *pix, BordersParams *p) {
			int xmid = int(double(pix->w) * 0.333);
			int ymid = int(double(pix->h) * 0.333);

			p->borders.left   = detectBorder(pix, 0, pix->w-1, 1, ymid, pix->w, HORIZONTAL);
			p->borders.top    = detectBorder(pix, 0, pix->h-1, 1, xmid, pix->h, VERTICAL);
			p->borders.right  = detectBorder(pix, pix->w-1, 0, -1, ymid, pix->w, HORIZONTAL);
			p->borders.bottom = detectBorder(pix, pix->h-1, 0, -1, xmid, pix->h, VERTICAL);
		}

		double detectBorder(PIX *pix, int start_pos, int end_pos, int inc, int mid, int max, Direction dir) {
			int min_size = 20;
			int gap = 0;
			l_uint32 v;
			int i = start_pos, border = start_pos;
			while (i != end_pos) {
				int ms = mid - 4*min_size;
				int me = mid + 4*min_size;
				int old_gap = gap;

				int j = ms;
				while (j < me) {
					int x=i, y=j;
					if (dir == VERTICAL) { x=j; y=i; }
					//if (x<0 || y<0 || x>=pix->w || y>=pix->h) break;
					pixGetPixel(pix, x, y, &v);
					if (v) {
						border = i;
						gap = 0;
						break;
					} else if (gap == old_gap) {
						++gap;
					}
					++j;
				}

				if (gap > min_size/2)
					break;
				i += inc;
			}

			return double(border)/double(max);
		};


		void fineTuneBorders(PIX *pix, BordersParams *p) {
			fineTuneBorderCorner(pix, p->borders.left, p->borders.top, 1, 1);
			fineTuneBorderCorner(pix, p->borders.right, p->borders.top, -1, 1);
			fineTuneBorderCorner(pix, p->borders.left, p->borders.bottom, 1, -1);
			fineTuneBorderCorner(pix, p->borders.right, p->borders.bottom, -1, -1);
		}; 


		void fineTuneBorderCorner(PIX *pix, double &x, double &y, int inc_x, int inc_y) {
			int x1 = int(x * double(pix->w));
			int y1 = int(y * double(pix->h));
			int tx, ty;
			l_uint32 v;

			while (1) {
				pixGetPixel(pix, x1, y1, &v);
				if (!v) break;
				tx = x1 + inc_x;
				ty = y1 + inc_y;
				if (tx<0 || tx>=pix->w || ty<0 || ty>=pix->h) break;
				x1 = tx;
				y1 = ty;
			}
			x = double(x1) / double(pix->w);
			y = double(y1) / double(pix->h);
		}
	};
}

#endif
