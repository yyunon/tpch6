----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06/12/2020 02:15:37 PM
-- Design Name: 
-- Module Name: SumOp - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

LIBRARY work;
USE work.Stream_pkg.ALL;
USE work.Forecast_pkg.ALL;
--use work.fixed_generic_pkg_mod.all;

LIBRARY ieee_proposed;
USE ieee_proposed.fixed_pkg.ALL;
ENTITY SumOp IS
  GENERIC (

    -- Width of the stream data vector.
    FIXED_LEFT_INDEX : INTEGER;
    FIXED_RIGHT_INDEX : INTEGER;
    DATA_WIDTH : NATURAL;
    DATA_TYPE : STRING := ""

  );
  PORT (

    -- Rising-edge sensitive clock.
    clk : IN STD_LOGIC;

    -- Active-high synchronous reset.
    reset : IN STD_LOGIC;

    --OP1 Input stream.
    op1_valid : IN STD_LOGIC;
    op1_dvalid : IN STD_LOGIC := '1';
    op1_ready : OUT STD_LOGIC;
    op1_data : IN STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);

    --OP2 Input stream.
    op2_valid : IN STD_LOGIC;
    op2_dvalid : IN STD_LOGIC := '1';
    op2_ready : OUT STD_LOGIC;
    op2_data : IN STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);

    -- Output stream.
    out_valid : OUT STD_LOGIC;
    out_ready : IN STD_LOGIC;
    out_data : OUT STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
    out_dvalid : OUT STD_LOGIC
  );
END SumOp;

ARCHITECTURE Behavioral OF SumOp IS

  --subtype float64 is float(11 downto -52);
  SIGNAL temp_buffer : sfixed(FIXED_LEFT_INDEX DOWNTO FIXED_RIGHT_INDEX);
  SIGNAL ops_valid : STD_LOGIC;
  SIGNAL ops_ready : STD_LOGIC;

  SIGNAL result : STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);

BEGIN
  -- Synchronize the operand streams.
  op_in_sync : StreamSync
  GENERIC MAP(
    NUM_INPUTS => 2,
    NUM_OUTPUTS => 1
  )
  PORT MAP(
    clk => clk,
    reset => reset,

    in_valid(0) => op1_valid,
    in_valid(1) => op2_valid,
    in_ready(0) => op1_ready,
    in_ready(1) => op2_ready,

    out_valid(0) => ops_valid,
    out_ready(0) => ops_ready
  );

  float_comb_process :
  IF DATA_TYPE = "FLOAT64" GENERATE
    PROCESS (op1_data, op2_data) IS
      VARIABLE temp_buffer_1 : sfixed(FIXED_LEFT_INDEX DOWNTO FIXED_RIGHT_INDEX);
      VARIABLE temp_buffer_2 : sfixed(FIXED_LEFT_INDEX DOWNTO FIXED_RIGHT_INDEX);
      VARIABLE temp_res : sfixed(FIXED_LEFT_INDEX + 1 DOWNTO FIXED_RIGHT_INDEX);
    BEGIN
      temp_buffer_1 := to_sfixed(op1_data, temp_buffer_1'high, temp_buffer_1'low);
      temp_buffer_2 := to_sfixed(op2_data, temp_buffer_2'high, temp_buffer_2'low);
      temp_res := temp_buffer_1 + temp_buffer_2;
      temp_buffer <= resize(arg => temp_res, left_index => FIXED_LEFT_INDEX, right_index => FIXED_RIGHT_INDEX, round_style => fixed_round_style, overflow_style => fixed_overflow_style);
    END PROCESS;
    PROCESS (temp_buffer) IS
    BEGIN
      result <= to_slv(temp_buffer);
    END PROCESS;
  END GENERATE;

  int_comb_process :
  IF DATA_TYPE = "INT64" GENERATE
    PROCESS (op1_data, op2_data) IS
    BEGIN
      result <= STD_LOGIC_VECTOR(signed(op1_data) + signed(op2_data));
    END PROCESS;
  END GENERATE;

  out_data <= STD_LOGIC_VECTOR(result);
  out_valid <= ops_valid;
  out_dvalid <= op1_dvalid AND op2_dvalid;
  ops_ready <= out_ready;

END Behavioral;