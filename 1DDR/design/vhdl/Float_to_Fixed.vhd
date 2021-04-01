-- This code is directly taken from vhlib but async read is implemented
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_misc.ALL;
USE ieee.numeric_std.ALL;

--LIBRARY ieee_proposed;
--USE ieee_proposed.fixed_pkg.ALL;

LIBRARY work;
USE work.Stream_pkg.ALL;
USE work.ParallelPatterns_pkg.ALL;
USE work.Forecast_pkg.ALL;
use work.fixed_generic_pkg_mod.all;
ENTITY Float_to_Fixed IS
  GENERIC (

    FIXED_LEFT_INDEX : INTEGER;
    FIXED_RIGHT_INDEX : INTEGER;
    DATA_WIDTH : NATURAL;
    INPUT_MIN_DEPTH : NATURAL;
    OUTPUT_MIN_DEPTH : NATURAL;
    CONVERTER_TYPE : STRING -- := "flopoco" := "xilinx_ip";

  );
  PORT (
    clk : IN STD_LOGIC;
    reset : IN STD_LOGIC;

    in_valid : IN STD_LOGIC;
    in_dvalid : IN STD_LOGIC := '1';
    in_ready : OUT STD_LOGIC;
    in_last : IN STD_LOGIC;
    in_data : IN STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);

    out_valid : OUT STD_LOGIC;
    out_dvalid : OUT STD_LOGIC := '1';
    out_ready : IN STD_LOGIC;
    out_last : OUT STD_LOGIC;
    out_data : OUT STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0)

  );
END Float_to_Fixed;

ARCHITECTURE Behavioral OF Float_to_Fixed IS
  -- Floating  point IP used by xilinx
  COMPONENT floating_point_0_2
    PORT (
      aclk : IN STD_LOGIC;
      s_axis_a_tvalid : IN STD_LOGIC;
      s_axis_a_tready : OUT STD_LOGIC;
      s_axis_a_tdata : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
      s_axis_a_tuser : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      s_axis_a_tlast : IN STD_LOGIC;
      m_axis_result_tvalid : OUT STD_LOGIC;
      m_axis_result_tready : IN STD_LOGIC;
      m_axis_result_tdata : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
      m_axis_result_tuser : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      m_axis_result_tlast : OUT STD_LOGIC
    );
  END COMPONENT;
  --
  -- Flopoco functions 
  COMPONENT InputIEEE_11_52_to_11_52 IS
    PORT (
      clk, rst : IN STD_LOGIC;
      X : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
      R : OUT STD_LOGIC_VECTOR(11 + 52 + 2 DOWNTO 0));
  END COMPONENT;
  COMPONENT FP2Fix_11_52M_32_31_S_NT_F400_uid2 IS
    PORT (
      clk, rst : IN STD_LOGIC;
      I : IN STD_LOGIC_VECTOR(11 + 52 + 2 DOWNTO 0);
      O : OUT STD_LOGIC_VECTOR(63 DOWNTO 0));
  END COMPONENT;
  --
  SIGNAL conv_data_valid : STD_LOGIC := '0';
  SIGNAL conv_data_ready : STD_LOGIC := '0';
  SIGNAL conv_data_dvalid : STD_LOGIC := '0';
  SIGNAL conv_data_last : STD_LOGIC := '0';
  SIGNAL conv_data : STD_LOGIC_VECTOR(63 DOWNTO 0) := (OTHERS => '0');
  SIGNAL result_data : STD_LOGIC_VECTOR(63 DOWNTO 0) := (OTHERS => '0'); --MUX to the output of converter.
  SIGNAL float_type : STD_LOGIC_VECTOR(1 DOWNTO 0);--MUX to the output of converter.

  SIGNAL ops_valid : STD_LOGIC;
  SIGNAL ops_dvalid : STD_LOGIC;
  SIGNAL ops_ready : STD_LOGIC;
  SIGNAL ops_last : STD_LOGIC;
  SIGNAL ops_data : STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);

  -- Pipeline signals
  SIGNAL data, data_d1, data_d2, data_d3, data_d4, data_d5, data_d6, data_d7 : STD_LOGIC_VECTOR(11 + 52 + 2 DOWNTO 0);
  SIGNAL ready, ready_d1, ready_d2, ready_d3, ready_d4, ready_d5, ready_d6, ready_d7 : STD_LOGIC;
  SIGNAL last, last_d1, last_d2, last_d3, last_d4, last_d5, last_d6, last_d7 : STD_LOGIC;
  SIGNAL dvalid, dvalid_d1, dvalid_d2, dvalid_d3, dvalid_d4, dvalid_d5, dvalid_d6, dvalid_d7 : STD_LOGIC;
  SIGNAL valid, valid_d1, valid_d2, valid_d3, valid_d4, valid_d5, valid_d6, valid_d7 : STD_LOGIC;

  CONSTANT ZERO : STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');

BEGIN

  op_in_sync : StreamBuffer
  GENERIC MAP(
    DATA_WIDTH => DATA_WIDTH + 2,
    MIN_DEPTH => INPUT_MIN_DEPTH
  )
  PORT MAP(
    clk => clk,
    reset => reset,

    in_valid => in_valid,
    in_ready => in_ready,
    in_data(65) => in_last,
    in_data(64) => in_dvalid,
    in_data(63 DOWNTO 0) => in_data,

    out_valid => ops_valid,
    out_ready => ops_ready,
    out_data(65) => ops_last,
    out_data(64) => ops_dvalid,
    out_data(63 DOWNTO 0) => ops_data
  );

  out_buf : StreamBuffer
  GENERIC MAP(
    DATA_WIDTH => DATA_WIDTH + 2,
    MIN_DEPTH => OUTPUT_MIN_DEPTH
  )
  PORT MAP(
    clk => clk,
    reset => reset,
    in_valid => conv_data_valid,
    in_ready => conv_data_ready,
    in_data(65) => conv_data_last,
    in_data(64) => conv_data_dvalid,
    in_data(63 DOWNTO 0) => conv_data,

    out_valid => out_valid,
    out_ready => out_ready,
    out_data(65) => out_last,
    out_data(64) => out_dvalid,
    out_data(63 DOWNTO 0) => out_data
  );

  none_converter :
  IF CONVERTER_TYPE = "none" GENERATE
    conv_data <= ops_data;
    conv_data_last <= ops_last;
    conv_data_dvalid <= ops_dvalid;
    conv_data_valid <= ops_valid;
    ops_ready <= conv_data_ready;
  END GENERATE;

  xilinx_converter :
  IF CONVERTER_TYPE = "xilinx" GENERATE
    data_converter : floating_point_0_2
    PORT MAP(
      aclk => clk,
      s_axis_a_tvalid => ops_valid,
      s_axis_a_tready => ops_ready,
      s_axis_a_tdata => ops_data,
      s_axis_a_tuser(0) => ops_dvalid,
      s_axis_a_tlast => ops_last,
      m_axis_result_tvalid => conv_data_valid,
      m_axis_result_tready => conv_data_ready,
      m_axis_result_tdata => conv_data,
      m_axis_result_tuser(0) => conv_data_dvalid,
      m_axis_result_tlast => conv_data_last
    );
  END GENERATE;

  flopoco_converter_big :
  IF CONVERTER_TYPE = "flopoco" GENERATE
    reg_process :
    PROCESS (clk)
    BEGIN
      IF clk'event AND clk = '1' THEN

        ready_d1 <= ready_d2;
        ready_d2 <= ready_d3;
        ready_d3 <= ready_d4;
        ready_d4 <= ready_d5;
        ready_d5 <= ready_d6;
        ready_d6 <= ready_d7;
        ready_d7 <= ready;

        valid_d1 <= valid;
        valid_d2 <= valid_d1;
        valid_d3 <= valid_d2;
        valid_d4 <= valid_d3;
        valid_d5 <= valid_d4;
        valid_d6 <= valid_d5;
        valid_d7 <= valid_d6;

        last_d1 <= last;
        last_d2 <= last_d1;
        last_d3 <= last_d2;
        last_d4 <= last_d3;
        last_d5 <= last_d4;
        last_d6 <= last_d5;
        last_d7 <= last_d6;

        dvalid_d1 <= dvalid;
        dvalid_d2 <= dvalid_d1;
        dvalid_d3 <= dvalid_d2;
        dvalid_d4 <= dvalid_d3;
        dvalid_d5 <= dvalid_d4;
        dvalid_d6 <= dvalid_d5;
        dvalid_d7 <= dvalid_d6;

        data_d1 <= data;
        data_d2 <= data_d1;
        data_d3 <= data_d2;
        data_d4 <= data_d3;
        data_d5 <= data_d4;
        data_d6 <= data_d5;
        data_d7 <= data_d6;
      END IF;
    END PROCESS;
    -- Flopoco has its own type, which is simply IEEE.
    -- Yet, it uses flags for normalization etc. 
    -- First, convert it to flopoco then to fixed point in this 
    -- part. We spend 7 clk cycles: 1 clk cycle for ieee to flopoco and the
    -- rest is for flopoco to fixed point converter.
    -- NT => Non truncated.
    -- [45,-18]
    ops_ready <= ready_d1;
    last <= ops_last;
    dvalid <= ops_dvalid;
    valid <= ops_valid;
    ieee_to_flopoco : InputIEEE_11_52_to_11_52
    PORT MAP(
      clk => clk,
      rst => reset,
      X => ops_data,
      R => data
    );
    flopoco_to_fixed : FP2Fix_11_52M_32_31_S_NT_F400_uid2
    PORT MAP(
      clk => clk,
      rst => reset,
      I => data_d1,
      O => result_data
    );
    conv_data_dvalid <= dvalid_d7;
    conv_data_valid <= valid_d7;
    conv_data_last <= last_d7;
    --float_type <= data_d7(65 DOWNTO 64);
    --conv_data <= ZERO WHEN (float_type = (1 DOWNTO 0 => '0')) ELSE
    --result_data(DATA_WIDTH - 1 DOWNTO DATA_WIDTH - 1 - FIXED_LEFT_INDEX) & "0000" & result_data(DATA_WIDTH - 2 - FIXED_LEFT_INDEX DOWNTO 4);
    --conv_data <= ZERO WHEN (float_type = (1 DOWNTO 0 => '0')) ELSE
    --result_data;
    conv_data <= result_data;
    ready <= conv_data_ready OR (NOT valid_d7);
  END GENERATE;
END Behavioral;