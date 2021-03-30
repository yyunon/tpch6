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

LIBRARY ieee_proposed;
USE ieee_proposed.fixed_pkg.ALL;

LIBRARY work;
USE work.Stream_pkg.ALL;
USE work.ParallelPatterns_pkg.ALL;
USE work.Forecast_pkg.ALL;
--use work.fixed_generic_pkg_mod.all;
ENTITY MergeOp IS
  GENERIC (

    -- Width of the stream data vector.
    FIXED_LEFT_INDEX : INTEGER;
    FIXED_RIGHT_INDEX : INTEGER;
    DATA_WIDTH : NATURAL;
    INPUT_MIN_DEPTH : NATURAL;
    OUTPUT_MIN_DEPTH : NATURAL;
    DATA_TYPE : STRING := ""

  );
  PORT (

    -- Rising-edge sensitive clock.
    clk : IN STD_LOGIC;

    -- Active-high synchronous reset.
    reset : IN STD_LOGIC;

    --OP1 Input stream.
    op1_valid : IN STD_LOGIC;
    op1_last : IN STD_LOGIC;
    op1_dvalid : IN STD_LOGIC := '1';
    op1_data : IN STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
    op1_ready : OUT STD_LOGIC;

    --OP2 Input stream.
    op2_valid : IN STD_LOGIC;
    op2_last : IN STD_LOGIC;
    op2_dvalid : IN STD_LOGIC := '1';
    op2_ready : OUT STD_LOGIC;
    op2_data : IN STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);

    -- Output stream.
    out_valid : OUT STD_LOGIC;
    out_last : OUT STD_LOGIC;
    out_ready : IN STD_LOGIC;
    out_data : OUT STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
    out_dvalid : OUT STD_LOGIC
  );
END MergeOp;

ARCHITECTURE Behavioral OF MergeOp IS

  SIGNAL out_s_valid : STD_LOGIC;
  SIGNAL out_s_ready : STD_LOGIC;

  SIGNAL buf_op1_valid : STD_LOGIC;
  SIGNAL buf_op1_dvalid : STD_LOGIC;
  SIGNAL buf_op1_last : STD_LOGIC := '0';
  SIGNAL buf_op1_ready : STD_LOGIC;
  SIGNAL buf_op1_data : STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);

  SIGNAL buf_op2_valid : STD_LOGIC;
  SIGNAL buf_op2_dvalid : STD_LOGIC;
  SIGNAL buf_op2_last : STD_LOGIC := '0';
  SIGNAL buf_op2_ready : STD_LOGIC;
  SIGNAL buf_op2_data : STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);

  SIGNAL ops_valid : STD_LOGIC;
  SIGNAL ops_dvalid : STD_LOGIC;
  SIGNAL ops_last : STD_LOGIC := '0';
  SIGNAL ops_ready : STD_LOGIC;
  SIGNAL ops_data : STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);

BEGIN

  op1_buf : StreamBuffer
  GENERIC MAP(
    DATA_WIDTH => DATA_WIDTH + 2,
    MIN_DEPTH => INPUT_MIN_DEPTH
  )
  PORT MAP(
    clk => clk,
    reset => reset,
    in_valid => op1_valid,
    in_ready => op1_ready,
    in_data(65) => op1_last,
    in_data(64) => op1_dvalid,
    in_data(63 DOWNTO 0) => op1_data,
    out_valid => buf_op1_valid,
    out_ready => buf_op1_ready,
    out_data(65) => buf_op1_last,
    out_data(64) => buf_op1_dvalid,
    out_data(63 DOWNTO 0) => buf_op1_data
  );

  op2_buf : StreamBuffer
  GENERIC MAP(
    DATA_WIDTH => DATA_WIDTH + 2,
    MIN_DEPTH => INPUT_MIN_DEPTH
  )
  PORT MAP(
    clk => clk,
    reset => reset,
    in_valid => op2_valid,
    in_ready => op2_ready,
    in_data(65) => op2_last,
    in_data(64) => op2_dvalid,
    in_data(63 DOWNTO 0) => op2_data,
    out_valid => buf_op2_valid,
    out_ready => buf_op2_ready,
    out_data(65) => buf_op2_last,
    out_data(64) => buf_op2_dvalid,
    out_data(63 DOWNTO 0) => buf_op2_data
  );

  out_buf : StreamBuffer
  GENERIC MAP(
    DATA_WIDTH => DATA_WIDTH + 2,
    MIN_DEPTH => INPUT_MIN_DEPTH
  )
  PORT MAP(
    clk => clk,
    reset => reset,
    in_valid => out_s_valid,
    in_ready => out_s_ready,
    in_data(65) => ops_last,
    in_data(64) => ops_dvalid,
    in_data(63 DOWNTO 0) => ops_data,
    out_valid => out_valid,
    out_ready => out_ready,
    out_data(65) => out_last,
    out_data(64) => out_dvalid,
    out_data(63 DOWNTO 0) => out_data
  );
  discount_sync : StreamSync
  GENERIC MAP(
    NUM_INPUTS => 2,
    NUM_OUTPUTS => 1
  )
  PORT MAP(
    clk => clk,
    reset => reset,

    in_valid(0) => buf_op1_valid,
    in_valid(1) => buf_op2_valid,
    in_ready(0) => buf_op1_ready,
    in_ready(1) => buf_op2_ready,
    out_valid(0) => ops_valid,
    out_ready(0) => ops_ready
  );

  mult_process :
  PROCESS (buf_op1_data, buf_op2_data, ops_valid, out_s_ready) IS
    VARIABLE temp_buffer_1 : sfixed(FIXED_LEFT_INDEX DOWNTO FIXED_RIGHT_INDEX);
    VARIABLE temp_buffer_2 : sfixed(FIXED_LEFT_INDEX DOWNTO FIXED_RIGHT_INDEX);
    VARIABLE temp_res : sfixed(2 * FIXED_LEFT_INDEX + 1 DOWNTO 2 * FIXED_RIGHT_INDEX);
  BEGIN
    out_s_valid <= '0';
    ops_ready <= '0';
    ops_dvalid <= '0';
    --ops_last_s <= '0';
    IF ops_valid = '1' AND out_s_ready = '1' THEN
      ops_dvalid <= buf_op1_dvalid AND buf_op2_dvalid;
      out_s_valid <= '1';
      ops_ready <= '1';
      temp_buffer_1 := to_sfixed(buf_op1_data, temp_buffer_1'high, temp_buffer_1'low);
      temp_buffer_2 := to_sfixed(buf_op2_data, temp_buffer_2'high, temp_buffer_2'low);
      temp_res := temp_buffer_1 * temp_buffer_2;
      ops_data <= to_slv(resize(arg => temp_res, left_index => FIXED_LEFT_INDEX, right_index => FIXED_RIGHT_INDEX, round_style => fixed_round_style, overflow_style => fixed_overflow_style));
    END IF;
  END PROCESS;
  ops_last <= buf_op1_last AND buf_op2_last;

END Behavioral;