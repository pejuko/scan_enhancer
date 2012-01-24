#ifndef _SCAN_FILTER_
#define _SCAN_FILTER_

#include "page.h"

#include <vector>

namespace ScanEnhancer {

class Page;

class FilterParams {
public:
	
};


class Filter {
public:
	virtual FilterParams *new_params(void) = 0;
	virtual void process(Page *page, FilterParams *params) = 0;
};


class FilterQueue {
public:
	~FilterQueue(void);

	void process(Page *page);
	void init_params(Page *page);

	void push_back(Filter *filter);

private:
	std::vector<Filter*> m_filters;
};

}

#endif
