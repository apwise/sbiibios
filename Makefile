SRC_DIR := ./src
MATCH_DIR := ./match
SYSTEM_DIR := $(MATCH_DIR)/system
SYSGEN_DIR := $(MATCH_DIR)/sysgen
BOOTROM_DIR := $(MATCH_DIR)/bootrom
DOCS_DIR := ./docs
BUILD_DIR := ./build

all clean:
	$(MAKE) -C $(SRC_DIR) $(MAKECMDGOALS)
	$(MAKE) -C $(SYSTEM_DIR) $(MAKECMDGOALS)
	$(MAKE) -C $(SYSGEN_DIR) $(MAKECMDGOALS)
	$(MAKE) -C $(BOOTROM_DIR) $(MAKECMDGOALS)
	$(MAKE) -C $(DOCS_DIR) $(MAKECMDGOALS)

clean: local_clean

local_clean:
	rm -rf $(BUILD_DIR)
	rm -rf *~

.PHONY: all clean local_clean

