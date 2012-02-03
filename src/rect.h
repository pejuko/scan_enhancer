#ifndef _SCAN_RECT_
#define _SCAN_RECT_

#include <string>
#include <sstream>

#include <leptonica/allheaders.h>

namespace ScanEnhancer {
	struct Rect {
		Rect() : left(0.0), top(0.0), right(1.0), bottom(1.0) {}
		Rect(double l, double t, double r, double b) : left(l), top(t), right(r), bottom(b) {}
		double left, top, right, bottom;

		double width(void) const { return right - left; };
		double height(void) const { return bottom - top; };

		void set(Rect const& box) { left=box.left; top=box.top; right=box.right; bottom=box.bottom; };
		void set(double left, double top, double right, double bottom) { left=left; top=top; right=right; bottom=bottom; };

		std::string toString(void) {
			std::stringstream str;
			str << "left: " << left << " top: " << top << " right: " << right << " bottom: " << bottom;
			return str.str();
		};

		BOX *toBox(PIX *pix) {
			BOX *box = new BOX();

			box->x = left * pix->w;
			box->y = top  * pix->h;
			box->w = right * pix->w - box->x;
			box->h = bottom * pix->h - box->y;

			return box;
		}
	};
};

#endif
