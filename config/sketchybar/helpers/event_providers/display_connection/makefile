LIBS = -framework CoreGraphics

bin/display_connection: display_connection.c display_connection.h ../sketchybar.h | bin
	clang -std=c99 -O3 $< -o $@ $(LIBS)

bin:
	mkdir -p bin
