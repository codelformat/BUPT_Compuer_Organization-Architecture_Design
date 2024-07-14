LIBRARY ieee;
USE ieee.std_logic_1164.all;

entity controller is 
  port(IR: in std_logic_vector(3 downto 0);
	   SW: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
	   W1: IN STD_LOGIC;
	   W2: IN STD_LOGIC;
	   W3: IN STD_LOGIC;
	   T3: IN STD_LOGIC;
	   C: in std_logic;
	   Z: in std_logic;
	   CLR: in std_logic;
	   LIR: out std_logic;
	   PCINC: out std_logic;
	   ARINC: OUT STD_LOGIC;
	   PCADD: OUT STD_LOGIC;
	   M: OUT STD_LOGIC;
	   S: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
	   SEL: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
	   CIN: OUT STD_LOGIC;
	   ABUS: OUT STD_LOGIC;
	   DRW: OUT STD_LOGIC;
	   MEMW: OUT STD_LOGIC;
	   LDZ: OUT STD_LOGIC;
	   LDC: OUT STD_LOGIC;
	   LAR: OUT STD_LOGIC;
	   LONG: OUT STD_LOGIC;
	   SHORT: OUT STD_LOGIC;
	   MBUS: OUT STD_LOGIC;
	   SBUS: OUT STD_LOGIC;
	   LPC: OUT STD_LOGIC;
	   SELCTL: OUT STD_LOGIC;
	   STOP: OUT STD_LOGIC
	   );
END controller;

architecture behaviour of controller is 
  -- Temp Variable Definition
  SIGNAL ST0: std_logic; -- indicate next stage
  SIGNAL SST0: std_logic; -- indicate change of ST0
  begin
  -- Behaviour of Controller
	-- CLR & T3 occurs
	process(CLR, T3) -- A W1/W2/W3 Potential contains T1, T2, T3 three pulses
    begin
		if(T3'EVENT AND T3 ='0' AND SST0='1') THEN -- descending edge of T3(LAST DESCENDING EDGE OF W)
			ST0 <='1'; -- Indicate Stage 2
		END IF;
		
		if(CLR='0') then
			ST0 <='0'; -- Default ST0
		end if;		
    end process;
    
    -- Other signals change
    process(SW, W1, W2, W3, IR, C, Z, ST0)
	begin
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
		
		SST0 <= '0'; -- 04-12
		
		case SW IS
			WHEN "001" => -- Write into Mem
				SBUS <= W1;
				LAR <=(NOT ST0) AND W1;
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
			WHEN "000"=> -- Instruction Fetching
				IF ST0='0' THEN -- Stage 1: Read from user input, write into PC
					SST0 <= W1; -- Indicate ST0='1' next round
					LPC <= W1;
					SHORT <= W1; -- Restart from W1 next round
					SBUS <= W1; -- Read from keyboard
					--STOP <= W1; -- STOP RUNNING
				ELSE -- Stage 2: Read from given addr
					LIR <= W1;
					PCINC <= W1;
					case IR IS
						WHEN "0001"=> -- ADD
							S <= "1001";
							CIN <= W2;
							ABUS <= W2;
							DRW <= W2;
							LDZ <= W2;
							LDC <= W2;
						WHEN "0010"=> -- SUB
							S <= "0110";
							ABUS <= W2;
							DRW <= W2;
							LDZ <= W2;
							LDC <= W2;
						WHEN "0011"=> -- AND
							M <= W2;
							S <= "1011";
							ABUS <= W2;
							DRW <= W2;
							LDZ <= W2;
						WHEN "0100"=> --INC
							S <= "0000";
							ABUS <= W2;
							DRW <= W2;
							LDZ <= W2;
						WHEN "0101"=> -- LD
							M <= W2;
							S <= "1010";
							ABUS <= W2;
							LAR <= W2;
							LONG <= W2;
							DRW <= W3;
							MBUS <= W3;
						WHEN "0110"=> -- ST
							M <= W2;
							S <= "1111";
							ABUS <= W2;
							LAR <= W2;
							LONG <= W2;
							IF W3='1' THEN -- W3 Interval
								S <= "1010";
								M <= W3;
								ABUS <= W3;
								MEMW <= W3;
							END IF;
						WHEN "0111"=> -- JC
							IF C='1' THEN 
								PCADD <= W2;
							END IF;
						WHEN "1000"=> -- JZ
							IF Z='1' THEN
								PCADD <= W2;
							END IF;
						WHEN "1001"=> --JMP
							M <= W2;
							S <= "1111";
							ABUS <= W2;
							LPC <= W2;
						WHEN "1110"=> --STP
							STOP <= W2;
						WHEN OTHERS=>
							NULL;
					END CASE;
				END IF;
			WHEN OTHERS=>
				NULL;
		END CASE;			 
	END PROCESS;
end behaviour;   
	 
	   