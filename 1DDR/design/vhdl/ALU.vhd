-- This code is directly taken from vhlib but async read is implemented
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_misc.ALL;
USE ieee.numeric_std.ALL;

LIBRARY ieee_proposed;
USE ieee_proposed.fixed_pkg.ALL;

LIBRARY work;
USE work.Stream_pkg.ALL;
USE work.ParallelPatterns_pkg.ALL;
USE work.Forecast_pkg.ALL;

--use work.fixed_generic_pkg_mod.all;
-- In the first prototype generate different hws for each op.
ENTITY FILTER IS
  GENERIC (

    -- Width of a data word.
    FIXED_LEFT_INDEX : INTEGER;
    FIXED_RIGHT_INDEX : INTEGER;
    DATA_WIDTH : NATURAL;
    INPUT_MIN_DEPTH : INTEGER;
    OUTPUT_MIN_DEPTH : INTEGER;

    FILTERTYPE : STRING := ""

  );
  PORT (
    clk : IN STD_LOGIC;
    reset : IN STD_LOGIC;

    in_valid : IN STD_LOGIC;
    in_dvalid : IN STD_LOGIC := '1';
    in_ready : OUT STD_LOGIC;
    in_last : IN STD_LOGIC;
    in_data : IN STD_LOGIC_VECTOR(63 DOWNTO 0);

    out_valid : OUT STD_LOGIC;
    out_ready : IN STD_LOGIC;
    out_data : OUT STD_LOGIC

  );
END FILTER;

ARCHITECTURE Behavioral OF FILTER IS

  SIGNAL temp_buffer : sfixed(FIXED_LEFT_INDEX DOWNTO FIXED_RIGHT_INDEX);
  SIGNAL temp_buffer_int : INTEGER;
  SIGNAL ops_valid : STD_LOGIC;
  SIGNAL ops_ready : STD_LOGIC;
  SIGNAL ops_last : STD_LOGIC;
  SIGNAL ops_data : STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);

  SIGNAL result : STD_LOGIC := '0';

  SIGNAL ops_ready_s : STD_LOGIC;

  SIGNAL out_ready_s : STD_LOGIC;
  SIGNAL out_valid_s : STD_LOGIC;
  SIGNAL out_data_s : STD_LOGIC;

BEGIN

  -- Synchronize the operand stream
  filter_in_buffer : StreamBuffer
  GENERIC MAP(
    DATA_WIDTH => DATA_WIDTH + 1,
    MIN_DEPTH => INPUT_MIN_DEPTH
  )
  PORT MAP(
    clk => clk,
    reset => reset,

    in_valid => in_valid,
    in_ready => in_ready,
    in_data(64) => in_last,
    in_data(63 DOWNTO 0) => in_data,

    out_valid => ops_valid,
    out_ready => ops_ready,
    out_data(64) => ops_last,
    out_data(63 DOWNTO 0) => ops_data
  );

  -- Synchronize the operand stream
  filter_out_buffer : StreamBuffer
  GENERIC MAP(
    DATA_WIDTH => 1,
    MIN_DEPTH => OUTPUT_MIN_DEPTH
  )
  PORT MAP(
    clk => clk,
    reset => reset,

    in_valid => out_valid_s,
    in_ready => out_ready_s,
    in_data(0) => out_data_s,

    out_valid => out_valid,
    out_ready => out_ready,
    out_data(0) => out_data
  );

  ops_ready <= out_ready_s AND ops_ready_s;
  out_data_s <= result;

  quantity_proc :
  IF FILTERTYPE = "LESSTHAN" GENERATE
    --process(ops_data) is 
    --  --variable temp_float_1 : float64; -- float(11 downto -52);
    --  variable temp_buffer_1: sfixed(FIXED_LEFT_INDEX downto FIXED_RIGHT_INDEX);
    --begin
    --  temp_buffer <=to_sfixed(ops_data,FIXED_LEFT_INDEX, FIXED_RIGHT_INDEX) ;
    --  --temp_buffer <= temp_buffer_1;
    --end process;
    PROCESS (ops_data, ops_valid, out_ready_s) IS
      -- Comparison constants
      CONSTANT QUANTITY_CONST : sfixed(FIXED_LEFT_INDEX DOWNTO FIXED_RIGHT_INDEX) := to_sfixed(24.0, FIXED_LEFT_INDEX, FIXED_RIGHT_INDEX);
    BEGIN
      out_valid_s <= '0';
      ops_ready_s <= '0';
      result <= '0';
      IF ops_valid = '1' AND out_ready_s = '1' THEN
        ops_ready_s <= '1';
        out_valid_s <= '1';
        IF to_sfixed(ops_data, FIXED_LEFT_INDEX, FIXED_RIGHT_INDEX) < QUANTITY_CONST THEN
          result <= '1';
        END IF;
      END IF;
    END PROCESS;
  END GENERATE;

  discount_proc :
  IF FILTERTYPE = "BETWEEN" GENERATE
    --process(ops_data) is 
    --  --variable temp_float_1 : float64; -- float(11 downto -52);
    --  variable temp_buffer_1: sfixed(FIXED_LEFT_INDEX downto FIXED_RIGHT_INDEX);
    --begin
    --  temp_buffer <= to_sfixed(ops_data,temp_buffer_1'high,temp_buffer_1'low);
    --  --temp_buffer <= temp_buffer_1;
    --end process;
    PROCESS (ops_data, ops_valid, out_ready_s) IS

      CONSTANT DISCOUNT_CONST_DOWN : sfixed(FIXED_LEFT_INDEX DOWNTO FIXED_RIGHT_INDEX) := to_sfixed(0.05000000, FIXED_LEFT_INDEX, FIXED_RIGHT_INDEX);
      CONSTANT DISCOUNT_CONST_UP : sfixed(FIXED_LEFT_INDEX DOWNTO FIXED_RIGHT_INDEX) := to_sfixed(0.07000000, FIXED_LEFT_INDEX, FIXED_RIGHT_INDEX);

    BEGIN
      out_valid_s <= '0';
      ops_ready_s <= '0';
      result <= '0';
      IF ops_valid = '1' AND out_ready_s = '1' THEN
        ops_ready_s <= '1';
        out_valid_s <= '1';
        IF (to_sfixed(ops_data, FIXED_LEFT_INDEX, FIXED_RIGHT_INDEX) <= DISCOUNT_CONST_UP) AND (to_sfixed(ops_data, FIXED_LEFT_INDEX, FIXED_RIGHT_INDEX) >= DISCOUNT_CONST_DOWN) THEN
          result <= '1';
        END IF;
      END IF;
    END PROCESS;
  END GENERATE;

  shipdate_proc :
  IF FILTERTYPE = "DATE" GENERATE
    --process(ops_data) is 
    --  --variable temp_float_1 : float64; -- float(11 downto -52);
    --  variable temp_buffer_1: sfixed(FIXED_LEFT_INDEX downto FIXED_RIGHT_INDEX);
    --begin
    --  temp_buffer_int <= to_integer(unsigned(ops_data));
    --end process;
    PROCESS (ops_data, ops_valid, out_ready_s) IS
      CONSTANT DATE_LOW : INTEGER := 8766;
      CONSTANT DATE_HIGH : INTEGER := 9131;
    BEGIN
      out_valid_s <= '0';
      ops_ready_s <= '0';
      result <= '0';
      IF ops_valid = '1' AND out_ready_s = '1' THEN
        ops_ready_s <= '1';
        out_valid_s <= '1';
        IF (to_integer(unsigned(ops_data)) >= DATE_LOW) AND (to_integer(unsigned(ops_data)) < DATE_HIGH) THEN
          result <= '1';
        END IF;
      END IF;
    END PROCESS;
  END GENERATE;

END Behavioral;