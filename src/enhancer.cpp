#include "file.h"

#include "filter.h"
#include "filters/deskew.h"
#include "filters/normalize.h"
#include "filters/binarize.h"
#include "filters/dewarp.h"
#include "filters/equalize.h"
#include "filters/contrast.h"
#include "filters/content.h"
#include "filters/output.h"

#include "enhancer.h"

#include <iostream>
#include <sstream>
#include <string>

namespace ScanEnhancer {

Enhancer::Enhancer(ImageFiles *files)
	: p_files(files)
{
	p_images = new Images();
	m_filterQueue.push_back(new FilterNormalize());
//	m_filterQueue.push_back(new FilterContrast());
//	m_filterQueue.push_back(new FilterEqualize());
	m_filterQueue.push_back(new FilterDeskew());
	m_filterQueue.push_back(new FilterBinarize());
//	m_filterQueue.push_back(new FilterDewarp());
	m_filterQueue.push_back(new FilterContent());
	m_filterQueue.push_back(new FilterOutput());
}

Enhancer::~Enhancer(void)
{
	for (int i=0; i<p_images->size(); i++) delete p_images->at(i);
	delete p_images;
}

void Enhancer::analyze(void)
{
	for (int i=0; i<p_files->size(); i++) {
		Images *images = p_files->at(i)->load_images();
		for (int idx=0; idx<images->size(); idx++) {
			Image *img = images->at(idx);
			//img->gen_preview();
			//img->gen_thumbnail();
			img->analyse(&m_filterQueue);
			//img->free_pix();
			p_images->push_back(img);
		}
		delete images;
		std::cout << i << std::endl;
	}
}

void Enhancer::export_result(void)
{
	for (int i=0; i<p_images->size(); i++) {
		std::stringstream prefix;
		prefix << "page_";
		prefix.fill('0');
		prefix.width(4);
		prefix << std::internal << i+1;
		p_images->at(i)->export_result(prefix.str());
	}
}

}
