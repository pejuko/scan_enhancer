ENHANCER_FLAGS=-g
ENHANCER_SRC=main.cpp file.cpp image.cpp enhancer.cpp page.cpp filter.cpp
ENHANCER_HEADERS=file.h image.h enhancer.h page.h filter.h filters/*
ENHANCER_LIBS=-llept

all: ${ENHANDER_SRC} ${ENHANCER_HEADERS}
	g++ -o scan_enhancer ${ENHANCER_FLAGS} ${ENHANCER_SRC} ${ENHANCER_LIBS}
