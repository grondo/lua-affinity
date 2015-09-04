LUA_VER    ?= $(shell lua -e 'print (_VERSION:match("Lua (.+)"))')
LIBDIR     ?= /usr/local/lib
LUA_OBJDIR ?= $(LIBDIR)/lua/$(LUA_VER)
PREFIX     ?= /usr/local

override CFLAGS+=  -Wall -ggdb $(shell pkg-config --cflags lua$(LUA_VER))
override LDFLAGS+= $(shell pkg-config --libs lua$(LUA_VER))

.SUFFIXES: .c .o .so

.c.o:
	$(CC) $(CFLAGS) -o $@ -fPIC -c $<

affinity.so: lua-affinity.o cpuset-str.o
	$(CC) -shared -o $*.so $^ $(LDFLAGS)

check: affinity.so
	@(cd tests && LUA_CPATH=../?.so ./lunit tests.lua)

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
