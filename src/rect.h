#ifndef _SCAN_RECT_
#define _SCAN_RECT_

namespace ScanEnhancer {
	struct Rect {
		Rect() : left(0.0), top(0.0), right(1.0), bottom(1.0) {}
		Rect(double l, double t, double r, double b) : left(l), top(t), right(r), bottom(b) {}
		double left, top, right, bottom;
	};
};

#endif
