-- This code is directly taken from vhlib but async read is implemented
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_misc.ALL;
USE ieee.numeric_std.ALL;

LIBRARY work;
USE work.Stream_pkg.ALL;
USE work.ParallelPatterns_pkg.ALL;
USE work.Forecast_pkg.ALL;
ENTITY Float_to_Fixed IS
  GENERIC (

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
  -- Enumeration type for our state machine.
  -- There is this hw delay of 7 for flopoco
  -- and 9/2 for xilinx floating ip.

  -- Floating  point IP used by xilinx
  COMPONENT floating_point_0
    PORT (
      aclk : IN STD_LOGIC;
      s_axis_a_tvalid : IN STD_LOGIC;
      --s_axis_a_tready : OUT STD_LOGIC;
      s_axis_a_tdata : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
      s_axis_a_tuser : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
      s_axis_a_tlast : IN STD_LOGIC;
      m_axis_result_tvalid : OUT STD_LOGIC;
      --m_axis_result_tready : IN STD_LOGIC;
      m_axis_result_tdata : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
      m_axis_result_tuser : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
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
  COMPONENT FP2Fix_11_52M_18_45_S_T_F400_uid2 IS
    PORT (
      clk : IN STD_LOGIC;
      I : IN STD_LOGIC_VECTOR(11 + 52 + 2 DOWNTO 0);
      O : OUT STD_LOGIC_VECTOR(63 DOWNTO 0));
  END COMPONENT;
  --
  SIGNAL conv_data_valid_s : STD_LOGIC;
  SIGNAL conv_data_valid : STD_LOGIC;
  SIGNAL conv_data_ready : STD_LOGIC;
  SIGNAL conv_data_dum : STD_LOGIC;
  SIGNAL conv_data_dvalid : STD_LOGIC;
  SIGNAL conv_data_last : STD_LOGIC;
  SIGNAL conv_data : STD_LOGIC_VECTOR(63 DOWNTO 0) := (OTHERS => '0');
  SIGNAL conv_data_open : STD_LOGIC_VECTOR(63 DOWNTO 0) := (OTHERS => '0');

  SIGNAL ops_valid : STD_LOGIC;
  SIGNAL ops_dvalid : STD_LOGIC;
  SIGNAL ops_ready : STD_LOGIC;
  SIGNAL ops_last : STD_LOGIC;
  SIGNAL ops_data : STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);

  SIGNAL flopoco_data : STD_LOGIC_VECTOR(DATA_WIDTH + 1 DOWNTO 0);
  SIGNAL flopoco_input : STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);

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

  none_converter :
  IF CONVERTER_TYPE = "none" GENERATE
    conv_data <= ops_data;
    conv_data_last <= ops_last;
    conv_data_dvalid <= ops_dvalid;
    conv_data_valid <= ops_valid;
    ops_ready <= conv_data_ready;
  END GENERATE;

  xilinx_converter :
  IF CONVERTER_TYPE = "xilinx_ip" GENERATE
    data_converter : floating_point_0
    PORT MAP(
      aclk => clk,
      s_axis_a_tvalid => ops_valid,
      --s_axis_a_tready => ops_ready,
      s_axis_a_tdata => ops_data,
      s_axis_a_tuser(1) => '0',
      s_axis_a_tuser(0) => ops_dvalid,
      s_axis_a_tlast => ops_last,
      m_axis_result_tvalid => conv_data_valid,
      --m_axis_result_tready => conv_data_ready,
      m_axis_result_tdata => conv_data,
      m_axis_result_tuser(1) => conv_data_dum,
      m_axis_result_tuser(0) => conv_data_dvalid,
      m_axis_result_tlast => conv_data_last
    );
    ops_ready <= conv_data_ready OR (NOT conv_data_valid);
  END GENERATE;

  flopoco_converter :
  IF CONVERTER_TYPE = "flopoco_big_numbers" GENERATE
    -- Flopoco has its own type, which is simply IEEE.
    -- Yet, it uses flags for normalization etc. 
    -- First, convert it to flopoco then to fixed point in this 
    -- part. 
    -- NT => Non truncated.
    -- [45,-18]
    ieee_to_flopoco : InputIEEE_11_52_to_11_52
    PORT MAP(
      clk => clk,
      rst => reset,
      X => ops_data,
      R => flopoco_data
    );

    flopoco_to_fixed : FP2Fix_11_52M_18_45_S_T_F400_uid2
    PORT MAP(
      clk => clk,
      I => flopoco_data,
      O => conv_data
    );
  END GENERATE;

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
END Behavioral;