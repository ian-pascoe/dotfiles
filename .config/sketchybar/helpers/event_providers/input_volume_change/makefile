LIBS = -framework CoreAudio -framework AudioToolbox

bin/input_volume_change: input_volume_change.c input_volume.h ../sketchybar.h | bin
	clang -std=c99 -O3 $< -o $@ $(LIBS)

bin:
	mkdir -p bin
