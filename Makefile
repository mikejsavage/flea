CC = gcc
CFLAGS = -O2 -shared -fPIC -std=gnu99
LDFLAGS = -levent
WARNINGS = -Wall -Wextra -Werror

all: libflea

libflea: src/main.c
	${CC} -o src/$@.so $^ ${CFLAGS} ${LDFLAGS} ${WARNINGS}
