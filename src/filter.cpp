#include "filter.h"
#include "page.h"

#include <vector>

namespace ScanEnhancer {

FilterQueue::~FilterQueue(void)
{
	for (int i=0; i<m_filters.size(); i++) {
		delete m_filters[i];
	}
	m_filters.clear();
}

void FilterQueue::process(Page *page)
{
	for (int i=0; i<m_filters.size(); i++) {
		m_filters[i]->process(page, page->params[i]);
	}
}

void FilterQueue::init_params(Page *page)
{
	page->clear_params();
	for (int i=0; i<m_filters.size(); i++) {
		page->params.push_back(m_filters[i]->new_params());
	}
}

void FilterQueue::push_back(Filter *filter)
{
	m_filters.push_back(filter);
}

}
