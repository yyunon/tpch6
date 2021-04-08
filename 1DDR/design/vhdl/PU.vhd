-- This source illustrates processing unit for each end-to-end query.
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_misc.ALL;
USE ieee.numeric_std.ALL;

LIBRARY work;
USE work.Stream_pkg.ALL;
USE work.ParallelPatterns_pkg.ALL;
USE work.Forecast_pkg.ALL;

ENTITY PU IS
  GENERIC (
    FIXED_LEFT_INDEX : INTEGER;
    FIXED_RIGHT_INDEX : INTEGER;
    DATA_WIDTH : NATURAL;
    INDEX_WIDTH : INTEGER;
    CONVERTERS : STRING := "";
    ILA : STRING := ""

  );
  PORT (
    clk : IN STD_LOGIC;
    reset : IN STD_LOGIC;

    l_quantity_valid : IN STD_LOGIC;
    l_quantity_ready : OUT STD_LOGIC;
    l_quantity_dvalid : IN STD_LOGIC;
    l_quantity_last : IN STD_LOGIC;
    l_quantity : IN STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);

    l_extendedprice_valid : IN STD_LOGIC;
    l_extendedprice_ready : OUT STD_LOGIC;
    l_extendedprice_dvalid : IN STD_LOGIC;
    l_extendedprice_last : IN STD_LOGIC;
    l_extendedprice : IN STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);

    l_discount_valid : IN STD_LOGIC;
    l_discount_ready : OUT STD_LOGIC;
    l_discount_dvalid : IN STD_LOGIC;
    l_discount_last : IN STD_LOGIC;
    l_discount : IN STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);

    l_shipdate_valid : IN STD_LOGIC;
    l_shipdate_ready : OUT STD_LOGIC;
    l_shipdate_dvalid : IN STD_LOGIC;
    l_shipdate_last : IN STD_LOGIC;
    l_shipdate : IN STD_LOGIC_VECTOR(DATA_WIDTH/2 - 1 DOWNTO 0); --32 bits 

    sum_out_valid : OUT STD_LOGIC;
    sum_out_ready : IN STD_LOGIC;
    sum_out_data : OUT STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0)
  );
END PU;

ARCHITECTURE Behavioral OF PU IS
  -- Constants
  -- Filter out buffers, goes in after sync.
  CONSTANT FILTER_OUT_DEPTH : INTEGER := 0;

  -- Merger inout buffers 
  CONSTANT MERGER_IN_DEPTH : INTEGER := 8;
  CONSTANT MERGER_OUT_DEPTH : INTEGER := 0;

  -- Converter inout buffers 
  CONSTANT EXTENDEDPRICE_CONVERTER_IN_DEPTH : INTEGER := 2;
  CONSTANT EXTENDEDPRICE_CONVERTER_OUT_DEPTH : INTEGER := 2;
  CONSTANT DISCOUNT_CONVERTER_IN_DEPTH : INTEGER := 2;
  CONSTANT DISCOUNT_CONVERTER_OUT_DEPTH : INTEGER := 2;
  CONSTANT QUANTITY_CONVERTER_IN_DEPTH : INTEGER := 2;
  CONSTANT QUANTITY_CONVERTER_OUT_DEPTH : INTEGER := 2;

  -- Filter in out buffers2
  CONSTANT BETWEEN_FILTER_IN_DEPTH : INTEGER := 0;
  CONSTANT BETWEEN_FILTER_OUT_DEPTH : INTEGER := 2;
  CONSTANT LESSTHAN_FILTER_IN_DEPTH : INTEGER := 0;
  CONSTANT LESSTHAN_FILTER_OUT_DEPTH : INTEGER := 2;
  CONSTANT COMPARE_FILTER_IN_DEPTH : INTEGER := 2; --DATE
  CONSTANT COMPARE_FILTER_OUT_DEPTH : INTEGER := 2; --DATE

  -- Outputs of converters
  SIGNAL conv_l_discount_valid : STD_LOGIC := '0';
  SIGNAL conv_l_discount_ready : STD_LOGIC := '0';
  SIGNAL conv_l_discount_dvalid : STD_LOGIC := '0';
  SIGNAL conv_l_discount_last : STD_LOGIC := '0';
  SIGNAL conv_l_discount : STD_LOGIC_VECTOR(63 DOWNTO 0) := (OTHERS => '0');

  SIGNAL conv_l_extendedprice_valid : STD_LOGIC := '0';
  SIGNAL conv_l_extendedprice_ready : STD_LOGIC := '0';
  SIGNAL conv_l_extendedprice_dvalid : STD_LOGIC := '0';
  SIGNAL conv_l_extendedprice_last : STD_LOGIC := '0';
  SIGNAL conv_l_extendedprice : STD_LOGIC_VECTOR(63 DOWNTO 0) := (OTHERS => '0');

  SIGNAL conv_l_quantity_valid : STD_LOGIC := '0';
  SIGNAL conv_l_quantity_ready : STD_LOGIC := '0';
  SIGNAL conv_l_quantity_dvalid : STD_LOGIC := '0';
  SIGNAL conv_l_quantity_last : STD_LOGIC := '0';
  SIGNAL conv_l_quantity : STD_LOGIC_VECTOR(63 DOWNTO 0) := (OTHERS => '0');

  SIGNAL dly_l_shipdate_valid : STD_LOGIC := '0';
  SIGNAL dly_l_shipdate_ready : STD_LOGIC := '0';
  SIGNAL dly_l_shipdate_dvalid : STD_LOGIC := '0';
  SIGNAL dly_l_shipdate_last : STD_LOGIC := '0';
  SIGNAL dly_l_shipdate : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
  --
  -- Discount synchronize signals
  SIGNAL between_in_valid : STD_LOGIC := '0';
  SIGNAL between_in_ready : STD_LOGIC := '0';

  SIGNAL merge_discount_in_valid : STD_LOGIC := '0';
  SIGNAL merge_discount_in_ready : STD_LOGIC := '0';
  --
  -- Sync inputs 
  SIGNAL sync_1_in_valid : STD_LOGIC := '0';
  SIGNAL sync_1_in_ready : STD_LOGIC := '0';
  SIGNAL sync_2_in_valid : STD_LOGIC := '0';
  SIGNAL sync_2_in_ready : STD_LOGIC := '0';
  SIGNAL sync_3_in_valid : STD_LOGIC := '0';
  SIGNAL sync_3_in_ready : STD_LOGIC := '0';
  --
  -- Sync inputs 
  SIGNAL sync_1_valid : STD_LOGIC := '0';
  SIGNAL sync_1_ready : STD_LOGIC := '0';
  SIGNAL sync_1_data : STD_LOGIC;
  SIGNAL sync_2_valid : STD_LOGIC := '0';
  SIGNAL sync_2_ready : STD_LOGIC := '0';
  SIGNAL sync_2_data : STD_LOGIC;
  SIGNAL sync_3_valid : STD_LOGIC := '0';
  SIGNAL sync_3_ready : STD_LOGIC := '0';
  SIGNAL sync_3_data : STD_LOGIC;
  --
  -- Multiplied vals
  SIGNAL reduce_in_ready : STD_LOGIC := '0';
  SIGNAL reduce_in_valid : STD_LOGIC := '0';
  SIGNAL reduce_in_last : STD_LOGIC;
  SIGNAL reduce_in_dvalid : STD_LOGIC;
  SIGNAL reduce_in_data : STD_LOGIC_VECTOR(63 DOWNTO 0);
  --
  -- Output of filter stage
  SIGNAL filter_out_valid : STD_LOGIC := '0';
  SIGNAL filter_out_ready : STD_LOGIC := '0';
  SIGNAL filter_out_last : STD_LOGIC;
  SIGNAL filter_out_strb : STD_LOGIC;
  -- signal filter_out_strb        : std_logic;
  -- Output of filter stage buffer
  SIGNAL buf_filter_out_valid : STD_LOGIC := '0';
  SIGNAL buf_filter_out_ready : STD_LOGIC := '0';
  SIGNAL buf_filter_out_last : STD_LOGIC;
  SIGNAL buf_filter_out_strb : STD_LOGIC;
  -- signal filter_out_strb        : std_logic;
  --
  CONSTANT ZERO : STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');
  COMPONENT ila_1
    PORT (
      clk : IN STD_LOGIC;
      probe0 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      probe1 : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
      probe2 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
      probe3 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      probe4 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      probe5 : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
      probe6 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      probe7 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      probe8 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      probe9 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      probe10 : IN STD_LOGIC_VECTOR(511 DOWNTO 0);
      probe11 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      probe12 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      probe13 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
      probe14 : IN STD_LOGIC_VECTOR(511 DOWNTO 0);
      probe15 : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
      probe16 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      probe17 : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      probe18 : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      probe19 : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
      probe20 : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
      probe21 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
      probe22 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      probe23 : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      probe24 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
      probe25 : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
      probe26 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      probe27 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
      probe28 : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      probe29 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
      probe30 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      probe31 : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      probe32 : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      probe33 : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      probe34 : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      probe35 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      probe36 : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      probe37 : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      probe38 : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
      probe39 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      probe40 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      probe41 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      probe42 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      probe43 : IN STD_LOGIC_VECTOR(0 DOWNTO 0)
    );
  END COMPONENT;
BEGIN
  --Integrated Logic Analyzers (ILA): This module works 
  --for only one of the instances. 
  logic_analyzer_gen :
  IF ILA = "TRUE" GENERATE
    --CL_ILA_0 : ila_1
    --PORT MAP (
    --      clk                   => clk,
    --      probe0(0)             => sum_out_valid,
    --      probe1                => sum_out_data,
    --      probe2                => (others => '0'),
    --      probe3(0)             => buf_filter_out_strb,
    --      probe4(0)             => reduce_in_valid,
    --      probe5                => reduce_in_data,
    --      probe6(0)             => l_discount_ready,
    --      probe7(0)             => l_extendedprice_ready,
    --      probe8(0)             => l_quantity_ready,
    --      probe9(0)             => l_shipdate_ready,
    --      probe10(511 downto 0) => (511 downto 256 => '0') & l_discount & l_extendedprice & l_quantity & l_shipdate,
    --      probe11(0)            => sync_1_data,
    --      probe12(0)            => sync_2_data,
    --      probe13               => (others => '0'),
    --      probe14               => (511 downto 192 => '0') & conv_l_discount & conv_l_extendedprice & conv_l_quantity,
    --      probe15               => (others => '0'),
    --      probe16(0)            => sync_3_data,
    --      probe17               => (others => '0'),
    --      probe18               => (others => '0'),
    --      probe19               => (others => '0'),
    --      probe20               => (others => '0'),
    --      probe21               => (others => '0'),
    --      probe22(0)            => buf_filter_out_ready,
    --      probe23               => (others => '0'),
    --      probe24               => (others => '0'),
    --      probe25               => (others => '0'),
    --      probe26(0)            => buf_filter_out_valid,
    --      probe27               => (others => '0'),
    --      probe28               => (others => '0'),
    --      probe29               => '0' & l_discount_last,
    --      probe30(0)            => l_extendedprice_last,
    --      probe31               => ZERO(3 downto 1) & l_quantity_last,
    --      probe32               => ZERO(3 downto 1)& l_shipdate_last,
    --      probe33               => ZERO(3 downto 1)& l_discount_valid,
    --      probe34               => ZERO(3 downto 1)& l_extendedprice_valid,
    --      probe35(0)            => l_quantity_valid,
    --      probe36               => ZERO(3 downto 1) & l_shipdate_valid,
    --      probe37               => (others => '0'),
    --      probe38               => (others => '0'),
    --      probe39               => (others => '0'),
    --      probe40               => (others => '0'),
    --      probe41               => (others => '0'),
    --      probe42               => (others => '0'),
    --      probe43(0)            => reduce_in_valid
    --);
  END GENERATE;

  -- CONVERTERS
  discount_converter : Float_to_Fixed
  GENERIC MAP(
    FIXED_LEFT_INDEX => FIXED_LEFT_INDEX,
    FIXED_RIGHT_INDEX => FIXED_RIGHT_INDEX,
    DATA_WIDTH => DATA_WIDTH,
    INPUT_MIN_DEPTH => DISCOUNT_CONVERTER_IN_DEPTH,
    OUTPUT_MIN_DEPTH => DISCOUNT_CONVERTER_OUT_DEPTH,
    CONVERTER_TYPE => "xilinx"

  )
  PORT MAP(
    clk => clk,
    reset => reset,

    in_valid => l_discount_valid,
    in_dvalid => l_discount_dvalid,
    in_ready => l_discount_ready,
    in_last => l_discount_last,
    in_data => l_discount,

    out_valid => conv_l_discount_valid,
    out_dvalid => conv_l_discount_dvalid,
    out_ready => conv_l_discount_ready,
    out_last => conv_l_discount_last,
    out_data => conv_l_discount
  );
  quantity_converter : Float_to_Fixed
  GENERIC MAP(
    FIXED_LEFT_INDEX => FIXED_LEFT_INDEX,
    FIXED_RIGHT_INDEX => FIXED_RIGHT_INDEX,
    DATA_WIDTH => DATA_WIDTH,
    INPUT_MIN_DEPTH => QUANTITY_CONVERTER_IN_DEPTH,
    OUTPUT_MIN_DEPTH => QUANTITY_CONVERTER_OUT_DEPTH,
    CONVERTER_TYPE => "xilinx"

  )
  PORT MAP(
    clk => clk,
    reset => reset,

    in_valid => l_quantity_valid,
    in_dvalid => l_quantity_dvalid,
    in_ready => l_quantity_ready,
    in_last => l_quantity_last,
    in_data => l_quantity,

    out_valid => conv_l_quantity_valid,
    out_dvalid => conv_l_quantity_dvalid,
    out_ready => conv_l_quantity_ready,
    out_last => conv_l_quantity_last,
    out_data => conv_l_quantity
  );
  extendedprice_converter : Float_to_Fixed
  GENERIC MAP(
    FIXED_LEFT_INDEX => FIXED_LEFT_INDEX,
    FIXED_RIGHT_INDEX => FIXED_RIGHT_INDEX,
    DATA_WIDTH => DATA_WIDTH,
    INPUT_MIN_DEPTH => EXTENDEDPRICE_CONVERTER_IN_DEPTH,
    OUTPUT_MIN_DEPTH => EXTENDEDPRICE_CONVERTER_OUT_DEPTH,
    CONVERTER_TYPE => "xilinx"

  )
  PORT MAP(
    clk => clk,
    reset => reset,

    in_valid => l_extendedprice_valid,
    in_dvalid => l_extendedprice_dvalid,
    in_ready => l_extendedprice_ready,
    in_last => l_extendedprice_last,
    in_data => l_extendedprice,

    out_valid => conv_l_extendedprice_valid,
    out_dvalid => conv_l_extendedprice_dvalid,
    out_ready => conv_l_extendedprice_ready,
    out_last => conv_l_extendedprice_last,
    out_data => conv_l_extendedprice
  );

  dly_shipdate : StreamSliceArray
  GENERIC MAP(
    DATA_WIDTH => DATA_WIDTH/2 + 2,
    DEPTH => 9
  )
  PORT MAP(
    clk => clk,
    reset => reset,

    in_valid => l_shipdate_valid,
    in_ready => l_shipdate_ready,
    in_data(DATA_WIDTH /2 + 1) => l_shipdate_last,
    in_data(DATA_WIDTH /2) => l_shipdate_dvalid,
    in_data(DATA_WIDTH /2 - 1 DOWNTO 0) => l_shipdate,

    out_valid => dly_l_shipdate_valid,
    out_ready => dly_l_shipdate_ready,
    out_data(DATA_WIDTH/2 + 1) => dly_l_shipdate_last,
    out_data(DATA_WIDTH/2) => dly_l_shipdate_dvalid,
    out_data(DATA_WIDTH/2 - 1 DOWNTO 0) => dly_l_shipdate

  );

  discount_sync : StreamSync
  GENERIC MAP(
    NUM_INPUTS => 1,
    NUM_OUTPUTS => 2
  )
  PORT MAP(
    clk => clk,
    reset => reset,

    in_valid(0) => conv_l_discount_valid,
    in_ready(0) => conv_l_discount_ready,
    out_valid(0) => between_in_valid,
    out_valid(1) => merge_discount_in_valid,
    out_ready(0) => between_in_ready,
    out_ready(1) => merge_discount_in_ready
  );

  filter_in_sync : StreamSync
  GENERIC MAP(
    NUM_INPUTS => 3,
    NUM_OUTPUTS => 3
  )
  PORT MAP(
    clk => clk,
    reset => reset,

    in_valid(0) => conv_l_quantity_valid,
    in_valid(1) => dly_l_shipdate_valid,
    in_valid(2) => between_in_valid,
    in_ready(0) => conv_l_quantity_ready,
    in_ready(1) => dly_l_shipdate_ready,
    in_ready(2) => between_in_ready,

    out_valid(0) => sync_1_in_valid,
    out_valid(1) => sync_2_in_valid,
    out_valid(2) => sync_3_in_valid,
    out_ready(0) => sync_1_in_ready,
    out_ready(1) => sync_2_in_ready,
    out_ready(2) => sync_3_in_ready
  );

  -- FILTERS
  -- There exists input and output buffer for each filtering operation. 
  -- Right now it supports non-configurable primitive comparisons
  -- TODO: Make it reconfigurable
  lessthan : FILTER
  GENERIC MAP(
    FIXED_LEFT_INDEX => FIXED_LEFT_INDEX,
    FIXED_RIGHT_INDEX => FIXED_RIGHT_INDEX,
    DATA_WIDTH => DATA_WIDTH,
    INPUT_MIN_DEPTH => LESSTHAN_FILTER_IN_DEPTH,
    OUTPUT_MIN_DEPTH => LESSTHAN_FILTER_OUT_DEPTH,
    FILTERTYPE => "LESSTHAN"
  )
  PORT MAP(
    clk => clk,
    reset => reset,

    in_valid => sync_1_in_valid,
    in_dvalid => conv_l_quantity_dvalid,
    in_ready => sync_1_in_ready,
    in_last => conv_l_quantity_last,
    in_data => conv_l_quantity,

    out_valid => sync_1_valid,
    out_ready => sync_1_ready,
    out_data => sync_1_data
  );
  between : FILTER
  GENERIC MAP(
    FIXED_LEFT_INDEX => FIXED_LEFT_INDEX,
    FIXED_RIGHT_INDEX => FIXED_RIGHT_INDEX,
    DATA_WIDTH => DATA_WIDTH,
    INPUT_MIN_DEPTH => BETWEEN_FILTER_IN_DEPTH,
    OUTPUT_MIN_DEPTH => BETWEEN_FILTER_OUT_DEPTH,
    FILTERTYPE => "BETWEEN"
  )
  PORT MAP(
    clk => clk,
    reset => reset,

    in_valid => sync_2_in_valid,
    in_dvalid => conv_l_discount_dvalid,
    in_ready => sync_2_in_ready,
    in_last => conv_l_discount_last,
    in_data => conv_l_discount,

    out_valid => sync_2_valid,
    out_ready => sync_2_ready,
    out_data => sync_2_data
  );
  compare : FILTER
  GENERIC MAP(
    FIXED_LEFT_INDEX => FIXED_LEFT_INDEX,
    FIXED_RIGHT_INDEX => FIXED_RIGHT_INDEX,
    INPUT_MIN_DEPTH => COMPARE_FILTER_IN_DEPTH,
    OUTPUT_MIN_DEPTH => COMPARE_FILTER_OUT_DEPTH,
    DATA_WIDTH => DATA_WIDTH/2,
    FILTERTYPE => "DATE"
  )
  PORT MAP(
    clk => clk,
    reset => reset,

    in_valid => sync_3_in_valid,
    in_dvalid => dly_l_shipdate_dvalid,
    in_ready => sync_3_in_ready,
    in_last => dly_l_shipdate_last,
    in_data => dly_l_shipdate,

    out_valid => sync_3_valid,
    out_ready => sync_3_ready,
    out_data => sync_3_data
  );

  ---------
  -- This module merges the predicate stream with another stream
  -- The MIN_DEPTH is specified for both input and output buffer. There exists
  -- a StreamSync operation for op1 and op2 inside this module.
  merge_predicate : MergeOp
  GENERIC MAP(
    FIXED_LEFT_INDEX => FIXED_LEFT_INDEX,
    FIXED_RIGHT_INDEX => FIXED_RIGHT_INDEX,
    DATA_WIDTH => 64,
    INPUT_MIN_DEPTH => MERGER_IN_DEPTH, -- For output buffer.
    OUTPUT_MIN_DEPTH => MERGER_OUT_DEPTH, -- For output buffer.
    OPERATOR => "MULT_FIXED"
  )
  PORT MAP(
    clk => clk,
    reset => reset,

    op1_valid => merge_discount_in_valid,
    op1_last => conv_l_discount_last,
    op1_ready => merge_discount_in_ready,
    op1_dvalid => conv_l_discount_dvalid,
    op1_data => conv_l_discount,

    op2_valid => conv_l_extendedprice_valid,
    op2_last => conv_l_extendedprice_last,
    op2_ready => conv_l_extendedprice_ready,
    op2_dvalid => conv_l_extendedprice_dvalid,
    op2_data => conv_l_extendedprice,

    out_valid => reduce_in_valid,
    out_last => reduce_in_last,
    out_ready => reduce_in_ready,
    out_data => reduce_in_data,
    out_dvalid => reduce_in_dvalid
  );
  filter_out_sync : StreamSync
  GENERIC MAP(
    NUM_INPUTS => 4,
    NUM_OUTPUTS => 1
  )
  PORT MAP(
    clk => clk,
    reset => reset,

    in_valid(0) => sync_1_valid,
    in_valid(1) => sync_2_valid,
    in_valid(2) => sync_3_valid,
    in_valid(3) => reduce_in_valid,
    in_ready(0) => sync_1_ready,
    in_ready(1) => sync_2_ready,
    in_ready(2) => sync_3_ready,
    in_ready(3) => reduce_in_ready,
    out_valid(0) => filter_out_valid,
    out_ready(0) => filter_out_ready
  );

  filter_out_buf : StreamBuffer
  GENERIC MAP(
    DATA_WIDTH => 2,
    MIN_DEPTH => FILTER_OUT_DEPTH
  )
  PORT MAP(
    clk => clk,
    reset => reset,
    in_valid => filter_out_valid,
    in_ready => filter_out_ready,
    in_data(1) => sync_1_data AND sync_2_data AND sync_3_data,
    in_data(0) => reduce_in_last,
    out_valid => buf_filter_out_valid,
    out_ready => buf_filter_out_ready,
    out_data(1) => buf_filter_out_strb,
    out_data(0) => buf_filter_out_last
  );

  reduce_stage : ReduceStage
  GENERIC MAP(
    FIXED_LEFT_INDEX => FIXED_LEFT_INDEX,
    FIXED_RIGHT_INDEX => FIXED_RIGHT_INDEX,
    INDEX_WIDTH => INDEX_WIDTH - 1
  )
  PORT MAP(
    clk => clk,
    reset => reset,
    in_valid => buf_filter_out_valid,
    in_ready => buf_filter_out_ready,
    in_dvalid => buf_filter_out_strb,
    in_last => buf_filter_out_last,
    in_data => reduce_in_data,
    out_valid => sum_out_valid,
    out_ready => sum_out_ready,
    out_data => sum_out_data
  );

END Behavioral;