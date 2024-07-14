LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY controller IS
	PORT (
		IR : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
		SW : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
		S : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		SEL : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		W1, W2, W3, T3, C, Z, CLR : IN STD_LOGIC;
		LIR, PCINC, ARINC, PCADD, M, CIN, ABUS, DRW, MEMW, LDZ, LDC, LAR, LONG, SHORT, MBUS, SBUS, LPC, SELCTL, STOP : OUT STD_LOGIC;
	);
END controller;

ARCHITECTURE behaviour OF controller IS
	-- Temp Variable Definition
	SIGNAL ST0 : STD_LOGIC; -- indicate next stage
	SIGNAL SST0 : STD_LOGIC; -- indicate change of ST0
BEGIN
	-- Behaviour of Controller
	-- CLR & T3 occurs
	PROCESS (CLR, T3)
	BEGIN
		IF (T3'EVENT AND T3 = '0' AND SST0 = '1') THEN -- descending edge of T3
			ST0 <= '1'; -- Indicate Stage 2
		END IF;

		IF (CLR = '0') THEN
			ST0 <= '0'; -- Default ST0
		END IF;
	END PROCESS;

	-- Other signals change
	PROCESS (SW, W1, W2, W3, IR, C, Z, ST0)
	BEGIN
		-- Initialize all output signals
		LIR <= '0';
		PCINC <= '0';
		ARINC <= '0';
		PCADD <= '0';
		M <= '0';
		S <= "0000";
		SEL <= "0000";
		CIN <= '0';
		ABUS <= '0';
		DRW <= '0';
		MEMW <= '0';
		LDZ <= '0';
		LDC <= '0';
		LAR <= '0';
		LONG <= '0';
		SHORT <= '0';
		MBUS <= '0';
		LPC <= '0';
		SELCTL <= '0';
		STOP <= '0';

		SST0 <= '0'; -- Default SST0

		CASE SW IS
			WHEN "001" => -- Write into Mem
				SBUS <= W1;
				LAR <= (NOT ST0) AND W1;
				STOP <= W1;
				SST0 <= (NOT ST0) AND W1;
				SHORT <= W1;
				SELCTL <= W1;
				MEMW <= (ST0) AND W1;
				ARINC <= (ST0) AND W1;
			WHEN "010" => -- Read from mem
				SBUS <= (NOT ST0) AND W1;
				LAR <= (NOT ST0) AND W1;
				STOP <= W1;
				SST0 <= (NOT ST0) AND W1;
				SHORT <= W1;
				SELCTL <= W1;
				MBUS <= (ST0) AND W1;
				ARINC <= (ST0) AND W1;
			WHEN "011" => -- Read from reg
				SEL <= "0001";
				SELCTL <= W1;
				STOP <= W1;
			WHEN "100" => -- Write into reg
				SBUS <= W1;
				SEL <= ST0 & W2 & ((NOT ST0) AND W1) & (ST0 AND W2);
				DRW <= W1 OR W2;
				STOP <= W1 OR W2;
				SELCTL <= W1 OR W2;
				SST0 <= (NOT ST0) AND W2;
			WHEN "000" => -- Instruction Fetching
				IF ST0 = '0' THEN -- Stage 1: Read from user input, write into PC
					SST0 <= W1; -- Indicate ST0='1' next round
					LPC <= W1;
					SHORT <= W1; -- Restart from W1 next round
					SBUS <= W1; -- Read from keyboard
					-- STOP <= W1; -- STOP RUNNING
				ELSE -- Stage 2: Read from given addr
					-- USE ONLY LOGIC EXPRESSION
					ABUS <= W1 AND (IR = "");
				END IF;
			WHEN OTHERS =>
				NULL;
		END CASE;
	END PROCESS;
END behaviour;