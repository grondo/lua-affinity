LUA_VER    ?= $(shell lua -e 'print (_VERSION:match("Lua (.+)"))')
LIBDIR     ?= /usr/local/lib
LUA_OBJDIR ?= $(LIBDIR)/lua/$(LUA_VER)
PREFIX     ?= /usr/local

LUA_PKG_NAME := $(shell \
	   pkg-config --exists lua$(LUA_VER) && echo lua$(LUA_VER) \
	|| pkg-config --exists lua && echo lua)

ifeq ($(LUA_PKG_NAME),)
	$(error "No Lua pkg-config file found!")
endif

override CFLAGS+=  -Wall -ggdb $(shell pkg-config --cflags $(LUA_PKG_NAME))
override LDFLAGS+= $(shell pkg-config --libs $(LUA_PKG_NAME))

.SUFFIXES: .c .o .so

.c.o:
	$(CC) $(CFLAGS) -o $@ -fPIC -c $<

affinity.so: lua-affinity.o cpuset-str.o
	$(CC) -shared -o $*.so $^ $(LDFLAGS)

check: affinity.so
	@tests/test.lua

check-coverage:
	make clean
	make CFLAGS="-fprofile-arcs -ftest-coverage" LDFLAGS="-lgcov"
	make check
	gcov lua-affinity.c
	gcov cpuset-str.c

clean:
	rm -f *.so *.o *.gcov *.gcda *.gcno *.core

install:
	install -D -m0644 affinity.so $(DESTDIR)$(LUA_OBJDIR)/affinity.so
