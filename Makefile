GPR      := dream_rsi.gpr
MAIN     := tests
OBJ_DIR  := obj
BIN_DIR  := bin

.PHONY: all test clean

all: $(BIN_DIR)/$(MAIN)

$(BIN_DIR)/$(MAIN): *.ads *.adb $(GPR)
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	gprbuild -p -P $(GPR)

test: all
	@echo "Running tests..."
	@$(BIN_DIR)/$(MAIN)

clean:
	gprclean -P $(GPR) || true
	rm -rf $(OBJ_DIR) $(BIN_DIR) $(MAIN)
