SRC_DIR := ./src
BUILD_DIR := ./build

all clean:
	$(MAKE) -C $(SRC_DIR) $(MAKECMDGOALS)

clean: local_clean

local_clean:
	rm -rf $(BUILD_DIR)

.PHONY: all clean local_clean

