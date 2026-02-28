CXX=g++
CXXFLAGS=-O2
NAME=release-test

build:
	$(CXX) $(CXXFLAGS) src/main.cpp -o release-test -lfmt

install:
	mkdir -p $(DESTDIR)/usr/bin
	cp release-test $(DESTDIR)/usr/bin/
