APP_NAME= logic_analyzer

CXXFLAGS +=	-Wall
LDLIBS +=	-lusb-1.0
CXX =		g++
LD =		${CXX}

all: ${APP_NAME} logic_analyzer_firmware.bin

logic_analyzer_firmware.bin: ../app_logic_analyzer/bin/app_logic_analyzer.xe
	mkdir -p tempdir
	xobjdump --strip --split --split-dir tempdir $<
	mv tempdir/image_n[01]c0_2.bin $@
	rm -rf tempdir

%.o: %.cpp
	${CXX} ${CXXFLAGS} -c $<

device_if.o: device_if.h
main.o: device_if.h

logic_analyzer: device_if.o device_serial_number.o main.o
	${LD} ${LDFLAGS} -o $@ $^ ${LDLIBS}

clean:
	-rm -rf ${APP_NAME} *.o logic_analyzer_firmware.bin
