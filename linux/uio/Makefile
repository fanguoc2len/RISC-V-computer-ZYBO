CC ?= gcc
CPPFLAGS ?= -D_DEFAULT_SOURCE
CFLAGS ?= -O2 -Wall -Wextra -std=c11

TARGET := accel_mmio_demo
SRCS := accel_mmio_demo.c accel_cmdq_host.c
CMDQ_TEST := accel_cmdq_host_test
CMDQ_TEST_SRCS := accel_cmdq_host_test.c accel_cmdq_host.c
EMU_PBM ?= accel_triangle.pbm

.PHONY: all clean emulate emulate-irq check-emulate check-emulate-irq check-cmdq-host

all: $(TARGET) $(CMDQ_TEST)

$(TARGET): $(SRCS)
	$(CC) $(CPPFLAGS) $(CFLAGS) -o $@ $(SRCS)

$(CMDQ_TEST): $(CMDQ_TEST_SRCS)
	$(CC) $(CPPFLAGS) $(CFLAGS) -o $@ $(CMDQ_TEST_SRCS)

emulate: $(TARGET)
	./$(TARGET) --emulate --pbm $(EMU_PBM)

emulate-irq: $(TARGET)
	./$(TARGET) --emulate --irq --pbm $(EMU_PBM)

check-emulate: $(TARGET)
	bash ./check_emulated_demo.sh

check-emulate-irq: $(TARGET)
	bash ./check_emulated_irq_demo.sh

check-cmdq-host: $(CMDQ_TEST)
	./$(CMDQ_TEST)

clean:
	rm -f $(TARGET) $(CMDQ_TEST) *.pbm
