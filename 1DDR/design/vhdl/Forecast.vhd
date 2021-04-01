-- This source code is initialized by Yuksel Yonsel
-- rev 0.1 
-- Author: Yuksel Yonsel

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_misc.ALL;

--LIBRARY ieee_proposed;
--USE ieee_proposed.fixed_pkg.ALL;

LIBRARY work;
USE work.Forecast_pkg.ALL;
USE work.Stream_pkg.ALL;
USE work.ParallelPatterns_pkg.ALL;
use work.fixed_generic_pkg_mod.all;

ENTITY Forecast IS
  GENERIC (
    INDEX_WIDTH : INTEGER := 32;
    TAG_WIDTH : INTEGER := 1
  );
  PORT (
    kcd_clk : IN STD_LOGIC;
    kcd_reset : IN STD_LOGIC;
    l_quantity_valid : IN STD_LOGIC;
    l_quantity_ready : OUT STD_LOGIC;
    l_quantity_dvalid : IN STD_LOGIC;
    l_quantity_last : IN STD_LOGIC;
    l_quantity : IN STD_LOGIC_VECTOR(1023 DOWNTO 0);
    l_quantity_count : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
    l_extendedprice_valid : IN STD_LOGIC;
    l_extendedprice_ready : OUT STD_LOGIC;
    l_extendedprice_dvalid : IN STD_LOGIC;
    l_extendedprice_last : IN STD_LOGIC;
    l_extendedprice : IN STD_LOGIC_VECTOR(1023 DOWNTO 0);
    l_extendedprice_count : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
    l_discount_valid : IN STD_LOGIC;
    l_discount_ready : OUT STD_LOGIC;
    l_discount_dvalid : IN STD_LOGIC;
    l_discount_last : IN STD_LOGIC;
    l_discount : IN STD_LOGIC_VECTOR(1023 DOWNTO 0);
    l_discount_count : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
    l_shipdate_valid : IN STD_LOGIC;
    l_shipdate_ready : OUT STD_LOGIC;
    l_shipdate_dvalid : IN STD_LOGIC;
    l_shipdate_last : IN STD_LOGIC;
    l_shipdate : IN STD_LOGIC_VECTOR(1023 DOWNTO 0);
    l_shipdate_count : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
    l_quantity_unl_valid : IN STD_LOGIC;
    l_quantity_unl_ready : OUT STD_LOGIC;
    l_quantity_unl_tag : IN STD_LOGIC_VECTOR(TAG_WIDTH - 1 DOWNTO 0);
    l_extendedprice_unl_valid : IN STD_LOGIC;
    l_extendedprice_unl_ready : OUT STD_LOGIC;
    l_extendedprice_unl_tag : IN STD_LOGIC_VECTOR(TAG_WIDTH - 1 DOWNTO 0);
    l_discount_unl_valid : IN STD_LOGIC;
    l_discount_unl_ready : OUT STD_LOGIC;
    l_discount_unl_tag : IN STD_LOGIC_VECTOR(TAG_WIDTH - 1 DOWNTO 0);
    l_shipdate_unl_valid : IN STD_LOGIC;
    l_shipdate_unl_ready : OUT STD_LOGIC;
    l_shipdate_unl_tag : IN STD_LOGIC_VECTOR(TAG_WIDTH - 1 DOWNTO 0);
    l_quantity_cmd_valid : OUT STD_LOGIC;
    l_quantity_cmd_ready : IN STD_LOGIC;
    l_quantity_cmd_firstIdx : OUT STD_LOGIC_VECTOR(INDEX_WIDTH - 1 DOWNTO 0);
    l_quantity_cmd_lastIdx : OUT STD_LOGIC_VECTOR(INDEX_WIDTH - 1 DOWNTO 0);
    l_quantity_cmd_tag : OUT STD_LOGIC_VECTOR(TAG_WIDTH - 1 DOWNTO 0);
    l_extendedprice_cmd_valid : OUT STD_LOGIC;
    l_extendedprice_cmd_ready : IN STD_LOGIC;
    l_extendedprice_cmd_firstIdx : OUT STD_LOGIC_VECTOR(INDEX_WIDTH - 1 DOWNTO 0);
    l_extendedprice_cmd_lastIdx : OUT STD_LOGIC_VECTOR(INDEX_WIDTH - 1 DOWNTO 0);
    l_extendedprice_cmd_tag : OUT STD_LOGIC_VECTOR(TAG_WIDTH - 1 DOWNTO 0);
    l_discount_cmd_valid : OUT STD_LOGIC;
    l_discount_cmd_ready : IN STD_LOGIC;
    l_discount_cmd_firstIdx : OUT STD_LOGIC_VECTOR(INDEX_WIDTH - 1 DOWNTO 0);
    l_discount_cmd_lastIdx : OUT STD_LOGIC_VECTOR(INDEX_WIDTH - 1 DOWNTO 0);
    l_discount_cmd_tag : OUT STD_LOGIC_VECTOR(TAG_WIDTH - 1 DOWNTO 0);
    l_shipdate_cmd_valid : OUT STD_LOGIC;
    l_shipdate_cmd_ready : IN STD_LOGIC;
    l_shipdate_cmd_firstIdx : OUT STD_LOGIC_VECTOR(INDEX_WIDTH - 1 DOWNTO 0);
    l_shipdate_cmd_lastIdx : OUT STD_LOGIC_VECTOR(INDEX_WIDTH - 1 DOWNTO 0);
    l_shipdate_cmd_tag : OUT STD_LOGIC_VECTOR(TAG_WIDTH - 1 DOWNTO 0);
    start : IN STD_LOGIC;
    stop : IN STD_LOGIC;
    reset : IN STD_LOGIC;
    idle : OUT STD_LOGIC;
    busy : OUT STD_LOGIC;
    done : OUT STD_LOGIC;
    result : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
    l_firstidx : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    l_lastidx : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    rhigh : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    rlow : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    status_1 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    status_2 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    r1 : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
    r2 : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
    r3 : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
    r4 : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
    r5 : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
    r6 : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
    r7 : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
    r8 : OUT STD_LOGIC_VECTOR(63 DOWNTO 0)
  );
END ENTITY;

ARCHITECTURE Implementation OF Forecast IS

  CONSTANT DATA_WIDTH : INTEGER := 64;
  CONSTANT EPC : INTEGER := 16;
  CONSTANT FIXED_LEFT_INDEX : INTEGER := 45;
  CONSTANT FIXED_RIGHT_INDEX : INTEGER := FIXED_LEFT_INDEX - (DATA_WIDTH - 1);

  CONSTANT SYNC_IN_BUFFER_DEPTH : INTEGER := 0;
  CONSTANT SYNC_OUT_BUFFER_DEPTH : INTEGER := 0;

  -- If the input stream size is not divisible by EPC check this:
  SIGNAL pu_mask : STD_LOGIC_VECTOR(EPC - 1 DOWNTO 0);
  -- Enumeration type for our state machine.
  TYPE state_t IS (STATE_IDLE,
    STATE_COMMAND,
    STATE_CALCULATING,
    STATE_UNLOCK,
    STATE_DONE);

  SIGNAL state_slv : STD_LOGIC_VECTOR(2 DOWNTO 0);

  -- Current state register and next state signal.
  SIGNAL state, state_next : state_t;

  -- Buffered inputs
  SIGNAL buf_l_quantity_valid : STD_LOGIC;
  SIGNAL buf_l_quantity_ready : STD_LOGIC;
  SIGNAL buf_l_quantity_dvalid : STD_LOGIC;
  SIGNAL buf_l_quantity_last : STD_LOGIC;
  SIGNAL buf_l_quantity : STD_LOGIC_VECTOR(DATA_WIDTH * EPC - 1 DOWNTO 0);
  SIGNAL buf_l_discount_valid : STD_LOGIC;
  SIGNAL buf_l_discount_ready : STD_LOGIC;
  SIGNAL buf_l_discount_dvalid : STD_LOGIC;
  SIGNAL buf_l_discount_last : STD_LOGIC;
  SIGNAL buf_l_discount : STD_LOGIC_VECTOR(DATA_WIDTH * EPC - 1 DOWNTO 0);
  SIGNAL buf_l_extendedprice_valid : STD_LOGIC;
  SIGNAL buf_l_extendedprice_ready : STD_LOGIC;
  SIGNAL buf_l_extendedprice_dvalid : STD_LOGIC;
  SIGNAL buf_l_extendedprice_last : STD_LOGIC;
  SIGNAL buf_l_extendedprice : STD_LOGIC_VECTOR(DATA_WIDTH * EPC - 1 DOWNTO 0);
  SIGNAL buf_l_shipdate_valid : STD_LOGIC;
  SIGNAL buf_l_shipdate_ready : STD_LOGIC;
  SIGNAL buf_l_shipdate_dvalid : STD_LOGIC;
  SIGNAL buf_l_shipdate_last : STD_LOGIC;
  SIGNAL buf_l_shipdate : STD_LOGIC_VECTOR(DATA_WIDTH * EPC - 1 DOWNTO 0);

  -- Buffered and decoded inputs
  SIGNAL dec_l_quantity_valid : STD_LOGIC_VECTOR(EPC - 1 DOWNTO 0);
  SIGNAL dec_l_quantity_ready : STD_LOGIC_VECTOR(EPC - 1 DOWNTO 0);
  SIGNAL dec_l_quantity_dvalid : STD_LOGIC_VECTOR(EPC - 1 DOWNTO 0);
  SIGNAL dec_l_quantity_last : STD_LOGIC_VECTOR(EPC - 1 DOWNTO 0);
  SIGNAL dec_l_quantity : STD_LOGIC_VECTOR(DATA_WIDTH * EPC - 1 DOWNTO 0);

  SIGNAL dec_l_discount_valid : STD_LOGIC_VECTOR(EPC - 1 DOWNTO 0);
  SIGNAL dec_l_discount_ready : STD_LOGIC_VECTOR(EPC - 1 DOWNTO 0);
  SIGNAL dec_l_discount_dvalid : STD_LOGIC_VECTOR(EPC - 1 DOWNTO 0);
  SIGNAL dec_l_discount_last : STD_LOGIC_VECTOR(EPC - 1 DOWNTO 0);
  SIGNAL dec_l_discount : STD_LOGIC_VECTOR(DATA_WIDTH * EPC - 1 DOWNTO 0);

  SIGNAL dec_l_extendedprice_valid : STD_LOGIC_VECTOR(EPC - 1 DOWNTO 0);
  SIGNAL dec_l_extendedprice_ready : STD_LOGIC_VECTOR(EPC - 1 DOWNTO 0);
  SIGNAL dec_l_extendedprice_dvalid : STD_LOGIC_VECTOR(EPC - 1 DOWNTO 0);
  SIGNAL dec_l_extendedprice_last : STD_LOGIC_VECTOR(EPC - 1 DOWNTO 0);
  SIGNAL dec_l_extendedprice : STD_LOGIC_VECTOR(DATA_WIDTH * EPC - 1 DOWNTO 0);
  SIGNAL dec_l_shipdate_valid : STD_LOGIC_VECTOR(EPC - 1 DOWNTO 0);
  SIGNAL dec_l_shipdate_ready : STD_LOGIC_VECTOR(EPC - 1 DOWNTO 0);
  SIGNAL dec_l_shipdate_dvalid : STD_LOGIC_VECTOR(EPC - 1 DOWNTO 0);
  SIGNAL dec_l_shipdate_last : STD_LOGIC_VECTOR(EPC - 1 DOWNTO 0);
  SIGNAL dec_l_shipdate : STD_LOGIC_VECTOR(DATA_WIDTH * EPC - 1 DOWNTO 0);

  --Stage valid ready signals
  SIGNAL quantity_valid : STD_LOGIC_VECTOR(EPC - 1 DOWNTO 0);
  SIGNAL quantity_ready : STD_LOGIC_VECTOR(EPC - 1 DOWNTO 0);
  SIGNAL quantity_dvalid : STD_LOGIC_VECTOR(EPC - 1 DOWNTO 0);
  SIGNAL quantity_last : STD_LOGIC_VECTOR(EPC - 1 DOWNTO 0);

  SIGNAL extendedprice_valid : STD_LOGIC_VECTOR(EPC - 1 DOWNTO 0);
  SIGNAL extendedprice_ready : STD_LOGIC_VECTOR(EPC - 1 DOWNTO 0);
  SIGNAL extendedprice_dvalid : STD_LOGIC_VECTOR(EPC - 1 DOWNTO 0);
  SIGNAL extendedprice_last : STD_LOGIC_VECTOR(EPC - 1 DOWNTO 0);

  SIGNAL discount_valid : STD_LOGIC_VECTOR(EPC - 1 DOWNTO 0);
  SIGNAL discount_ready : STD_LOGIC_VECTOR(EPC - 1 DOWNTO 0);
  SIGNAL discount_dvalid : STD_LOGIC_VECTOR(EPC - 1 DOWNTO 0);
  SIGNAL discount_last : STD_LOGIC_VECTOR(EPC - 1 DOWNTO 0);

  SIGNAL shipdate_valid : STD_LOGIC_VECTOR(EPC - 1 DOWNTO 0);
  SIGNAL shipdate_ready : STD_LOGIC_VECTOR(EPC - 1 DOWNTO 0);
  SIGNAL shipdate_dvalid : STD_LOGIC_VECTOR(EPC - 1 DOWNTO 0);
  SIGNAL shipdate_last : STD_LOGIC_VECTOR(EPC - 1 DOWNTO 0);

  -- Sum output stream.
  SIGNAL sum_out_valid_stages : STD_LOGIC_VECTOR(EPC - 1 DOWNTO 0);
  SIGNAL sum_out_ready_stages : STD_LOGIC_VECTOR(EPC - 1 DOWNTO 0);
  SIGNAL sum_out_data_stages : STD_LOGIC_VECTOR(DATA_WIDTH * EPC - 1 DOWNTO 0);

  SIGNAL total_sum_out_valid : STD_LOGIC;
  SIGNAL total_sum_out_ready : STD_LOGIC;

  SIGNAL result_out_valid : STD_LOGIC;
  SIGNAL result_out_ready : STD_LOGIC;

  SIGNAL temp_inp_1 : sfixed(FIXED_LEFT_INDEX DOWNTO FIXED_RIGHT_INDEX);
  SIGNAL temp_inp_2 : sfixed(FIXED_LEFT_INDEX DOWNTO FIXED_RIGHT_INDEX);
  SIGNAL temp_inp_3 : sfixed(FIXED_LEFT_INDEX DOWNTO FIXED_RIGHT_INDEX);
  SIGNAL temp_inp_4 : sfixed(FIXED_LEFT_INDEX DOWNTO FIXED_RIGHT_INDEX);
  SIGNAL temp_inp_5 : sfixed(FIXED_LEFT_INDEX DOWNTO FIXED_RIGHT_INDEX);
  SIGNAL temp_inp_6 : sfixed(FIXED_LEFT_INDEX DOWNTO FIXED_RIGHT_INDEX);
  SIGNAL temp_inp_7 : sfixed(FIXED_LEFT_INDEX DOWNTO FIXED_RIGHT_INDEX);
  SIGNAL temp_inp_8 : sfixed(FIXED_LEFT_INDEX DOWNTO FIXED_RIGHT_INDEX);
  SIGNAL temp_inp_9 : sfixed(FIXED_LEFT_INDEX DOWNTO FIXED_RIGHT_INDEX);
  SIGNAL temp_inp_10 : sfixed(FIXED_LEFT_INDEX DOWNTO FIXED_RIGHT_INDEX);
  SIGNAL temp_inp_11 : sfixed(FIXED_LEFT_INDEX DOWNTO FIXED_RIGHT_INDEX);
  SIGNAL temp_inp_12 : sfixed(FIXED_LEFT_INDEX DOWNTO FIXED_RIGHT_INDEX);
  SIGNAL temp_inp_13 : sfixed(FIXED_LEFT_INDEX DOWNTO FIXED_RIGHT_INDEX);
  SIGNAL temp_inp_14 : sfixed(FIXED_LEFT_INDEX DOWNTO FIXED_RIGHT_INDEX);
  SIGNAL temp_inp_15 : sfixed(FIXED_LEFT_INDEX DOWNTO FIXED_RIGHT_INDEX);
  SIGNAL temp_inp_16 : sfixed(FIXED_LEFT_INDEX DOWNTO FIXED_RIGHT_INDEX);

  CONSTANT ONES : STD_LOGIC_VECTOR(EPC - 1 DOWNTO 0) := (OTHERS => '1');

BEGIN

  --  +---------------------+  +---------------------+  +---------------------+  +---------------------+ 
  --|                     |  |                     |  |                     |  |                     | 
  --|      extendedprice  |  |      discount       |  |     shipdate        |  |          quantity   | 
  --|         512         |  |        512          |  |        512          |  |           512       | 
  --|                     |  |                     |  |                     |  |                     | 
  --+---------------------+  +---------------------+  +---------------------+  +---------------------+ 
  --           |                        |                        |                        |            
  --           |                        |                        |                        |            
  --           |                        |                        |                        |            
  --           |                        |                        |                        |            
  --           |                        |                        |                        |            
  --           |                        |                        |                        |            
  --           |                        |                        |                        |            
  --           |                        |                        |                        |            
  --           |                        |                        |                        |            
  -- +-------------------------++-----------------------++-----------------------++-----------------------+
  -- | Sync. all the streams   || Sync. all the streams || Sync. all the streams || Sync. all the streams |
  -- +-------------------------++-----------------------++-----------------------++-----------------------+
  --            |                        |                       |                       |             
  --            |                        |                       |                       |             
  --            |64x4                    |64x4                   | 64x4                  | 64x4        
  --            |                        |                       |                       |             
  --            |                        +                       +                       |             
  --            |                          |    |     |      |                           |             
  --            +------                    |    |     |      |                    -------+             
  --                                     +---+ +---+ +|--+ +---+                                       
  --                                     |   | |   | |   | |   |                                       
  --                                     |   | |   | |   | |   |                                       
  --                                     |PU | |PU | |PU | |PU |                                       
  --                                     |   | |   | |   | |   |                                       
  --                                     |   | |   | |   | |   |                                       
  --                                     |   | |   | |   | |   |                                       
  --                                     +---+ +---+ +---+ +---+                                       
  -- Input buffers to synchronizers.
  discount_buffer : StreamBuffer
  GENERIC MAP(
    DATA_WIDTH => 64 * EPC + 2,
    MIN_DEPTH => SYNC_IN_BUFFER_DEPTH -- plus last and dvalid : Maybe later count 
  )
  PORT MAP(
    clk => kcd_clk,
    reset => kcd_reset OR reset,
    in_valid => l_discount_valid,
    in_ready => l_discount_ready,
    in_data(DATA_WIDTH * EPC + 1) => l_discount_last,
    in_data(DATA_WIDTH * EPC) => l_discount_dvalid,
    in_data(DATA_WIDTH * EPC - 1 DOWNTO 0) => l_discount,
    out_valid => buf_l_discount_valid,
    out_ready => buf_l_discount_ready,
    out_data(DATA_WIDTH * EPC + 1) => buf_l_discount_last,
    out_data(DATA_WIDTH * EPC) => buf_l_discount_dvalid,
    out_data(DATA_WIDTH * EPC - 1 DOWNTO 0) => buf_l_discount

  );

  quantity_buffer : StreamBuffer
  GENERIC MAP(
    DATA_WIDTH => 64 * EPC + 2,
    MIN_DEPTH => SYNC_IN_BUFFER_DEPTH -- plus last and dvalid : Maybe later count 
  )
  PORT MAP(
    clk => kcd_clk,
    reset => kcd_reset OR reset,
    in_valid => l_quantity_valid,
    in_ready => l_quantity_ready,
    in_data(DATA_WIDTH * EPC + 1) => l_quantity_last,
    in_data(DATA_WIDTH * EPC) => l_quantity_dvalid,
    in_data(DATA_WIDTH * EPC - 1 DOWNTO 0) => l_quantity,
    out_valid => buf_l_quantity_valid,
    out_ready => buf_l_quantity_ready,
    out_data(DATA_WIDTH * EPC + 1) => buf_l_quantity_last,
    out_data(DATA_WIDTH * EPC) => buf_l_quantity_dvalid,
    out_data(DATA_WIDTH * EPC - 1 DOWNTO 0) => buf_l_quantity

  );
  extendedprice_buffer : StreamBuffer
  GENERIC MAP(
    DATA_WIDTH => 64 * EPC + 2,
    MIN_DEPTH => SYNC_IN_BUFFER_DEPTH -- plus last and dvalid : Maybe later count 
  )
  PORT MAP(
    clk => kcd_clk,
    reset => kcd_reset OR reset,
    in_valid => l_extendedprice_valid,
    in_ready => l_extendedprice_ready,
    in_data(DATA_WIDTH * EPC + 1) => l_extendedprice_last,
    in_data(DATA_WIDTH * EPC) => l_extendedprice_dvalid,
    in_data(DATA_WIDTH * EPC - 1 DOWNTO 0) => l_extendedprice,
    out_valid => buf_l_extendedprice_valid,
    out_ready => buf_l_extendedprice_ready,
    out_data(DATA_WIDTH * EPC + 1) => buf_l_extendedprice_last,
    out_data(DATA_WIDTH * EPC) => buf_l_extendedprice_dvalid,
    out_data(DATA_WIDTH * EPC - 1 DOWNTO 0) => buf_l_extendedprice

  );

  shipdate_buffer : StreamBuffer
  GENERIC MAP(
    DATA_WIDTH => 64 * EPC + 2,
    MIN_DEPTH => SYNC_IN_BUFFER_DEPTH -- plus last and dvalid : Maybe later count 
  )
  PORT MAP(
    clk => kcd_clk,
    reset => kcd_reset OR reset,
    in_valid => l_shipdate_valid,
    in_ready => l_shipdate_ready,
    in_data(DATA_WIDTH * EPC + 1) => l_shipdate_last,
    in_data(DATA_WIDTH * EPC) => l_shipdate_dvalid,
    in_data(DATA_WIDTH * EPC - 1 DOWNTO 0) => l_shipdate,
    out_valid => buf_l_shipdate_valid,
    out_ready => buf_l_shipdate_ready,
    out_data(DATA_WIDTH * EPC + 1) => buf_l_shipdate_last,
    out_data(DATA_WIDTH * EPC) => buf_l_shipdate_dvalid,
    out_data(DATA_WIDTH * EPC - 1 DOWNTO 0) => buf_l_shipdate

  );

  -- Sync. is not necessary for single epc.
  single_epc :
  IF EPC = 1 GENERATE
    quantity_valid(0) <= buf_l_quantity_valid;
    quantity_ready(0) <= buf_l_quantity_ready;

    discount_valid(0) <= buf_l_discount_valid;
    discount_ready(0) <= buf_l_discount_ready;

    extendedprice_valid(0) <= buf_l_extendedprice_valid;
    extendedprice_ready(0) <= buf_l_extendedprice_ready;

    shipdate_valid(0) <= buf_l_shipdate_valid;
    shipdate_ready(0) <= buf_l_shipdate_ready;

  END GENERATE;

  gen_sync_multi_epc :
  IF EPC > 1 GENERATE
    quantity_sync : StreamSync
    GENERIC MAP(
      NUM_INPUTS => 1,
      NUM_OUTPUTS => EPC
    )
    PORT MAP(
      clk => kcd_clk,
      reset => kcd_reset OR reset,

      in_valid(0) => buf_l_quantity_valid,
      in_ready(0) => buf_l_quantity_ready,
      out_valid => quantity_valid,
      out_ready => quantity_ready
    );

    discount_sync : StreamSync
    GENERIC MAP(
      NUM_INPUTS => 1,
      NUM_OUTPUTS => EPC
    )
    PORT MAP(
      clk => kcd_clk,
      reset => kcd_reset OR reset,

      in_valid(0) => buf_l_discount_valid,
      in_ready(0) => buf_l_discount_ready,
      out_valid => discount_valid,
      out_ready => discount_ready
    );

    shipdate_sync : StreamSync
    GENERIC MAP(
      NUM_INPUTS => 1,
      NUM_OUTPUTS => EPC
    )
    PORT MAP(
      clk => kcd_clk,
      reset => kcd_reset OR reset,

      in_valid(0) => buf_l_shipdate_valid,
      in_ready(0) => buf_l_shipdate_ready,
      out_valid => shipdate_valid,
      out_ready => shipdate_ready
    );

    extendedprice_sync : StreamSync
    GENERIC MAP(
      NUM_INPUTS => 1,
      NUM_OUTPUTS => EPC
    )
    PORT MAP(
      clk => kcd_clk,
      reset => kcd_reset OR reset,

      in_valid(0) => buf_l_extendedprice_valid,
      in_ready(0) => buf_l_extendedprice_ready,
      out_valid => extendedprice_valid,
      out_ready => extendedprice_ready
    );
  END GENERATE;

  assign_last_valid_signals :
  FOR I IN 0 TO EPC - 1 GENERATE

    discount_dvalid(I) <= buf_l_discount_dvalid;
    extendedprice_dvalid(I) <= buf_l_extendedprice_dvalid;
    shipdate_dvalid(I) <= buf_l_shipdate_dvalid;
    quantity_dvalid(I) <= buf_l_quantity_dvalid;

    discount_last(I) <= buf_l_discount_last;
    extendedprice_last(I) <= buf_l_extendedprice_last;
    shipdate_last(I) <= buf_l_shipdate_last;
    quantity_last(I) <= buf_l_quantity_last;
  END GENERATE;

  input_buffer_to_pu :
  FOR I IN 0 TO EPC - 1 GENERATE
    -- Output buf.
    --------------------------------------------------------------------
    discount_buffer_pu_0 : StreamBuffer
    GENERIC MAP(
      DATA_WIDTH => 64 + 2,
      MIN_DEPTH => SYNC_OUT_BUFFER_DEPTH -- plus last and dvalid : Maybe later count 
    )
    PORT MAP(
      clk => kcd_clk,
      reset => kcd_reset OR reset,
      in_valid => discount_valid(I),
      in_ready => discount_ready(I),
      in_data(DATA_WIDTH + 1) => discount_last(I),
      in_data(DATA_WIDTH) => discount_dvalid(I),
      in_data(DATA_WIDTH - 1 DOWNTO 0) => buf_l_discount((I + 1) * 64 - 1 DOWNTO I * 64),
      out_valid => dec_l_discount_valid(I),
      out_ready => dec_l_discount_ready(I),
      out_data(DATA_WIDTH + 1) => dec_l_discount_last(I),
      out_data(DATA_WIDTH) => dec_l_discount_dvalid(I),
      out_data(DATA_WIDTH - 1 DOWNTO 0) => dec_l_discount((I + 1) * 64 - 1 DOWNTO I * 64)
    );
    quantity_buffer_pu_0 : StreamBuffer
    GENERIC MAP(
      DATA_WIDTH => 64 + 2,
      MIN_DEPTH => SYNC_OUT_BUFFER_DEPTH -- plus last and dvalid : Maybe later count 
    )
    PORT MAP(
      clk => kcd_clk,
      reset => kcd_reset OR reset,
      in_valid => quantity_valid(I),
      in_ready => quantity_ready(I),
      in_data(DATA_WIDTH + 1) => quantity_last(I),
      in_data(DATA_WIDTH) => quantity_dvalid(I),
      in_data(DATA_WIDTH - 1 DOWNTO 0) => buf_l_quantity((I + 1) * 64 - 1 DOWNTO I * 64),
      out_valid => dec_l_quantity_valid(I),
      out_ready => dec_l_quantity_ready(I),
      out_data(DATA_WIDTH + 1) => dec_l_quantity_last(I),
      out_data(DATA_WIDTH) => dec_l_quantity_dvalid(I),
      out_data(DATA_WIDTH - 1 DOWNTO 0) => dec_l_quantity((I + 1) * 64 - 1 DOWNTO I * 64)
    );
    extendedprice_buffer_pu_0 : StreamBuffer
    GENERIC MAP(
      DATA_WIDTH => 64 + 2,
      MIN_DEPTH => SYNC_OUT_BUFFER_DEPTH -- plus last and dvalid : Maybe later count 
    )
    PORT MAP(
      clk => kcd_clk,
      reset => kcd_reset OR reset,
      in_valid => extendedprice_valid(I),
      in_ready => extendedprice_ready(I),
      in_data(DATA_WIDTH + 1) => extendedprice_last(I),
      in_data(DATA_WIDTH) => extendedprice_dvalid(I),
      in_data(DATA_WIDTH - 1 DOWNTO 0) => buf_l_extendedprice((I + 1) * 64 - 1 DOWNTO I * 64),
      out_valid => dec_l_extendedprice_valid(I),
      out_ready => dec_l_extendedprice_ready(I),
      out_data(DATA_WIDTH + 1) => dec_l_extendedprice_last(I),
      out_data(DATA_WIDTH) => dec_l_extendedprice_dvalid(I),
      out_data(DATA_WIDTH - 1 DOWNTO 0) => dec_l_extendedprice((I + 1) * 64 - 1 DOWNTO I * 64)
    );
    shipdate_buffer_pu_0 : StreamBuffer
    GENERIC MAP(
      DATA_WIDTH => 64 + 2,
      MIN_DEPTH => SYNC_OUT_BUFFER_DEPTH -- plus last and dvalid : Maybe later count 
    )
    PORT MAP(
      clk => kcd_clk,
      reset => kcd_reset OR reset,
      in_valid => shipdate_valid(I),
      in_ready => shipdate_ready(I),
      in_data(DATA_WIDTH + 1) => shipdate_last(I),
      in_data(DATA_WIDTH) => shipdate_dvalid(I),
      in_data(DATA_WIDTH - 1 DOWNTO 0) => buf_l_shipdate((I + 1) * 64 - 1 DOWNTO I * 64),
      out_valid => dec_l_shipdate_valid(I),
      out_ready => dec_l_shipdate_ready(I),
      out_data(DATA_WIDTH + 1) => dec_l_shipdate_last(I),
      out_data(DATA_WIDTH) => dec_l_shipdate_dvalid(I),
      out_data(DATA_WIDTH - 1 DOWNTO 0) => dec_l_shipdate((I + 1) * 64 - 1 DOWNTO I * 64)
    );
  END GENERATE;

  parallel_pu_gen :
  FOR I IN 0 TO EPC - 1 GENERATE
    processing_unit_0 : PU
    GENERIC MAP(
      FIXED_LEFT_INDEX => FIXED_LEFT_INDEX,
      FIXED_RIGHT_INDEX => FIXED_RIGHT_INDEX,
      DATA_WIDTH => 64,
      INDEX_WIDTH => INDEX_WIDTH,
      CONVERTERS => "FLOAT_TO_FIXED", -- TODO: Implement this
      ILA => ""
    )
    PORT MAP(
      clk => kcd_clk,
      reset => kcd_reset OR reset,

      l_quantity_valid => dec_l_quantity_valid(I),
      l_quantity_ready => dec_l_quantity_ready(I),
      l_quantity_dvalid => dec_l_quantity_dvalid(I),
      l_quantity_last => dec_l_quantity_last(I),
      l_quantity => dec_l_quantity((I + 1) * 64 - 1 DOWNTO I * 64),

      l_extendedprice_valid => dec_l_extendedprice_valid(I),
      l_extendedprice_ready => dec_l_extendedprice_ready(I),
      l_extendedprice_dvalid => dec_l_extendedprice_dvalid(I),
      l_extendedprice_last => dec_l_extendedprice_last(I),
      l_extendedprice => dec_l_extendedprice((I + 1) * 64 - 1 DOWNTO I * 64),

      l_discount_valid => dec_l_discount_valid(I),
      l_discount_ready => dec_l_discount_ready(I),
      l_discount_dvalid => dec_l_discount_dvalid(I),
      l_discount_last => dec_l_discount_last(I),
      l_discount => dec_l_discount((I + 1) * 64 - 1 DOWNTO I * 64),

      l_shipdate_valid => dec_l_shipdate_valid(I),
      l_shipdate_ready => dec_l_shipdate_ready(I),
      l_shipdate_dvalid => dec_l_shipdate_dvalid(I),
      l_shipdate_last => dec_l_shipdate_last(I),
      l_shipdate => dec_l_shipdate((I + 1) * 64 - 1 DOWNTO I * 64),

      sum_out_valid => sum_out_valid_stages(I),
      sum_out_ready => sum_out_ready_stages(I),
      sum_out_data => sum_out_data_stages((I + 1) * 64 - 1 DOWNTO I * 64)
    );
    -------------------------------------------------------------------------------
  END GENERATE;

  temp_inp_1 <= to_sfixed(sum_out_data_stages(DATA_WIDTH - 1 DOWNTO 0), FIXED_LEFT_INDEX, FIXED_RIGHT_INDEX);
  temp_inp_2 <= to_sfixed(sum_out_data_stages(2 * DATA_WIDTH - 1 DOWNTO DATA_WIDTH), FIXED_LEFT_INDEX, FIXED_RIGHT_INDEX);
  temp_inp_3 <= to_sfixed(sum_out_data_stages(3 * DATA_WIDTH - 1 DOWNTO 2 * DATA_WIDTH), FIXED_LEFT_INDEX, FIXED_RIGHT_INDEX);
  temp_inp_4 <= to_sfixed(sum_out_data_stages(4 * DATA_WIDTH - 1 DOWNTO 3 * DATA_WIDTH), FIXED_LEFT_INDEX, FIXED_RIGHT_INDEX);
  temp_inp_5 <= to_sfixed(sum_out_data_stages(5 * DATA_WIDTH - 1 DOWNTO 4 * DATA_WIDTH), FIXED_LEFT_INDEX, FIXED_RIGHT_INDEX);
  temp_inp_6 <= to_sfixed(sum_out_data_stages(6 * DATA_WIDTH - 1 DOWNTO 5 * DATA_WIDTH), FIXED_LEFT_INDEX, FIXED_RIGHT_INDEX);
  temp_inp_7 <= to_sfixed(sum_out_data_stages(7 * DATA_WIDTH - 1 DOWNTO 6 * DATA_WIDTH), FIXED_LEFT_INDEX, FIXED_RIGHT_INDEX);
  temp_inp_8 <= to_sfixed(sum_out_data_stages(8 * DATA_WIDTH - 1 DOWNTO 7 * DATA_WIDTH), FIXED_LEFT_INDEX, FIXED_RIGHT_INDEX);
  temp_inp_9 <= to_sfixed(sum_out_data_stages(9 * DATA_WIDTH - 1 DOWNTO 8 * DATA_WIDTH), FIXED_LEFT_INDEX, FIXED_RIGHT_INDEX);
  temp_inp_10 <= to_sfixed(sum_out_data_stages(10 * DATA_WIDTH - 1 DOWNTO 9 * DATA_WIDTH), FIXED_LEFT_INDEX, FIXED_RIGHT_INDEX);
  temp_inp_11 <= to_sfixed(sum_out_data_stages(11 * DATA_WIDTH - 1 DOWNTO 10 * DATA_WIDTH), FIXED_LEFT_INDEX, FIXED_RIGHT_INDEX);
  temp_inp_12 <= to_sfixed(sum_out_data_stages(12 * DATA_WIDTH - 1 DOWNTO 11 * DATA_WIDTH), FIXED_LEFT_INDEX, FIXED_RIGHT_INDEX);
  temp_inp_13 <= to_sfixed(sum_out_data_stages(13 * DATA_WIDTH - 1 DOWNTO 12 * DATA_WIDTH), FIXED_LEFT_INDEX, FIXED_RIGHT_INDEX);
  temp_inp_14 <= to_sfixed(sum_out_data_stages(14 * DATA_WIDTH - 1 DOWNTO 13 * DATA_WIDTH), FIXED_LEFT_INDEX, FIXED_RIGHT_INDEX);
  temp_inp_15 <= to_sfixed(sum_out_data_stages(15 * DATA_WIDTH - 1 DOWNTO 14 * DATA_WIDTH), FIXED_LEFT_INDEX, FIXED_RIGHT_INDEX);
  temp_inp_16 <= to_sfixed(sum_out_data_stages(16 * DATA_WIDTH - 1 DOWNTO 15 * DATA_WIDTH), FIXED_LEFT_INDEX, FIXED_RIGHT_INDEX);

  WITH state SELECT state_slv <=
    "000" WHEN STATE_COMMAND,
    "011" WHEN STATE_CALCULATING,
    "100" WHEN STATE_UNLOCK,
    "101" WHEN OTHERS;

  combinatorial_proc : PROCESS (
    l_firstIdx,
    l_lastIdx,
    l_quantity_cmd_ready,
    l_quantity_unl_valid,
    l_discount_cmd_ready,
    l_discount_unl_valid,
    l_shipdate_cmd_ready,
    l_shipdate_unl_valid,
    l_extendedprice_cmd_ready,
    l_extendedprice_unl_valid,

    sum_out_valid_stages,

    state,
    start,
    reset,
    kcd_reset
    ) IS
  BEGIN

    l_quantity_cmd_valid <= '0';
    l_quantity_cmd_firstIdx <= (OTHERS => '0');
    l_quantity_cmd_lastIdx <= (OTHERS => '0');
    l_quantity_cmd_tag <= (OTHERS => '0');

    l_quantity_unl_ready <= '0'; -- Do not accept "unlocks".

    l_discount_cmd_valid <= '0';
    l_discount_cmd_firstIdx <= (OTHERS => '0');
    l_discount_cmd_lastIdx <= (OTHERS => '0');
    l_discount_cmd_tag <= (OTHERS => '0');

    l_discount_unl_ready <= '0'; -- Do not accept "unlocks".

    l_shipdate_cmd_valid <= '0';
    l_shipdate_cmd_firstIdx <= (OTHERS => '0');
    l_shipdate_cmd_lastIdx <= (OTHERS => '0');
    l_shipdate_cmd_tag <= (OTHERS => '0');

    l_shipdate_unl_ready <= '0'; -- Do not accept "unlocks".

    l_extendedprice_cmd_valid <= '0';
    l_extendedprice_cmd_firstIdx <= (OTHERS => '0');
    l_extendedprice_cmd_lastIdx <= (OTHERS => '0');
    l_extendedprice_cmd_tag <= (OTHERS => '0');

    l_extendedprice_unl_ready <= '0'; -- Do not accept "unlocks".
    state_next <= state; -- Retain current state.

    sum_out_ready_stages <= (OTHERS => '0');

    CASE state IS
      WHEN STATE_IDLE =>
        -- Idle: We just wait for the start bit to come up.
        done <= '0';
        busy <= '0';
        idle <= '1';

        -- Wait for the start signal (typically controlled by the host-side 
        -- software).
        IF start = '1' THEN
          state_next <= STATE_COMMAND;
        END IF;

      WHEN STATE_COMMAND =>
        -- Command: we send a command to the generated interface.
        done <= '0';
        busy <= '1';
        idle <= '0';
        l_quantity_cmd_valid <= '1';
        l_quantity_cmd_firstIdx <= l_firstIdx;
        l_quantity_cmd_lastIdx <= l_lastIdx;
        l_quantity_cmd_tag <= (OTHERS => '0');

        l_extendedprice_cmd_valid <= '1';
        l_extendedprice_cmd_firstIdx <= l_firstIdx;
        l_extendedprice_cmd_lastIdx <= l_lastIdx;
        l_extendedprice_cmd_tag <= (OTHERS => '0');

        l_shipdate_cmd_valid <= '1';
        l_shipdate_cmd_firstIdx <= l_firstIdx;
        l_shipdate_cmd_lastIdx <= l_lastIdx;
        l_shipdate_cmd_tag <= (OTHERS => '0');

        l_discount_cmd_valid <= '1';
        l_discount_cmd_firstIdx <= l_firstIdx;
        l_discount_cmd_lastIdx <= l_lastIdx;
        l_discount_cmd_tag <= (OTHERS => '0');

        IF l_quantity_cmd_ready = '1' AND l_extendedprice_cmd_ready = '1' AND l_shipdate_cmd_ready = '1' AND l_discount_cmd_ready = '1' THEN
          state_next <= STATE_CALCULATING;
        END IF;

      WHEN STATE_CALCULATING =>
        -- Calculating: we stream in and accumulate the numbers one by one. PROBE Phase is here!
        done <= '0';
        busy <= '1';
        idle <= '0';

        sum_out_ready_stages <= (OTHERS => '1');

        IF sum_out_valid_stages = ONES THEN
          state_next <= STATE_UNLOCK;
        END IF;

      WHEN STATE_UNLOCK =>
        -- Unlock: the generated interface delivered all items in the stream.
        -- The unlock stream is supplied to make sure all bus transfers of the
        -- corresponding command are completed.
        done <= '1';
        busy <= '0';
        idle <= '1';

        -- Ready to handshake the unlock stream:
        l_quantity_unl_ready <= '1';
        l_discount_unl_ready <= '1';
        l_shipdate_unl_ready <= '1';
        l_extendedprice_unl_ready <= '1';
        -- Handshake when it is valid and go to the done state.
        -- if s_store_sk_unl_valid = '1' then
        IF l_discount_unl_valid = '1' AND l_quantity_unl_valid = '1' AND l_shipdate_unl_valid = '1' AND l_extendedprice_unl_valid = '1' THEN
          state_next <= STATE_DONE;
        END IF;

      WHEN STATE_DONE =>
        -- Done: the kernel is done with its job.
        done <= '1';
        busy <= '0';
        idle <= '1';

        -- Wait for the reset signal (typically controlled by the host-side 
        -- software), so we can go to idle again. This reset is not to be
        -- confused with the system-wide reset that travels into the kernel
        -- alongside the clock (kcd_reset).        
    END CASE;
  END PROCESS;

  -- Sequential part:
  sequential_proc : PROCESS (kcd_clk)
    VARIABLE result_out_data : STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
    VARIABLE temp_acc : sfixed(FIXED_LEFT_INDEX + (EPC - 1) DOWNTO FIXED_RIGHT_INDEX);
  BEGIN
    -- On the rising edge of the kernel clock:
    IF rising_edge(kcd_clk) THEN
      -- Register the next state.
      state <= state_next;
      status_1 <= (31 DOWNTO EPC => '0') & sum_out_valid_stages;
      result_out_data := (OTHERS => '0');
      temp_acc := (OTHERS => '0');

      IF sum_out_valid_stages = ONES THEN
        temp_acc := temp_inp_1 + temp_inp_2 + temp_inp_3 + temp_inp_4 + temp_inp_5 + temp_inp_6 + temp_inp_7 + temp_inp_8 + temp_inp_9 + temp_inp_10 + temp_inp_11 + temp_inp_12 + temp_inp_13 + temp_inp_14 + temp_inp_15 + temp_inp_16;
        result_out_data := to_slv(resize(arg => temp_acc, left_index => FIXED_LEFT_INDEX, right_index => FIXED_RIGHT_INDEX, round_style => fixed_round_style, overflow_style => fixed_overflow_style));
        result <= result_out_data;
        rhigh <= result_out_data(63 DOWNTO 32);
        rlow <= result_out_data(31 DOWNTO 0);
      END IF;
      IF (sum_out_valid_stages(0) = '0') THEN
        r1 <= to_slv(resize(arg => temp_inp_1, left_index => FIXED_LEFT_INDEX, right_index => FIXED_RIGHT_INDEX, round_style => fixed_round_style, overflow_style => fixed_overflow_style));
      END IF;
      IF (sum_out_valid_stages(1) = '0') THEN
        r2 <= to_slv(resize(arg => temp_inp_2, left_index => FIXED_LEFT_INDEX, right_index => FIXED_RIGHT_INDEX, round_style => fixed_round_style, overflow_style => fixed_overflow_style));
      END IF;
      IF (sum_out_valid_stages(2) = '0') THEN
        r3 <= to_slv(resize(arg => temp_inp_3, left_index => FIXED_LEFT_INDEX, right_index => FIXED_RIGHT_INDEX, round_style => fixed_round_style, overflow_style => fixed_overflow_style));
      END IF;
      IF (sum_out_valid_stages(3) = '0') THEN
        r4 <= to_slv(resize(arg => temp_inp_4, left_index => FIXED_LEFT_INDEX, right_index => FIXED_RIGHT_INDEX, round_style => fixed_round_style, overflow_style => fixed_overflow_style));
      END IF;
      IF (sum_out_valid_stages(4) = '0') THEN
        r5 <= to_slv(resize(arg => temp_inp_5, left_index => FIXED_LEFT_INDEX, right_index => FIXED_RIGHT_INDEX, round_style => fixed_round_style, overflow_style => fixed_overflow_style));
      END IF;
      IF (sum_out_valid_stages(5) = '0') THEN
        r6 <= to_slv(resize(arg => temp_inp_6, left_index => FIXED_LEFT_INDEX, right_index => FIXED_RIGHT_INDEX, round_style => fixed_round_style, overflow_style => fixed_overflow_style));
      END IF;
      IF (sum_out_valid_stages(6) = '0') THEN
        r7 <= to_slv(resize(arg => temp_inp_7, left_index => FIXED_LEFT_INDEX, right_index => FIXED_RIGHT_INDEX, round_style => fixed_round_style, overflow_style => fixed_overflow_style));
      END IF;
      IF (sum_out_valid_stages(7) = '0') THEN
        r8 <= to_slv(resize(arg => temp_inp_8, left_index => FIXED_LEFT_INDEX, right_index => FIXED_RIGHT_INDEX, round_style => fixed_round_style, overflow_style => fixed_overflow_style));
      END IF;

      IF kcd_reset = '1' OR reset = '1' THEN
        state <= STATE_IDLE;
        status_1 <= (OTHERS => '0');
        status_2 <= (OTHERS => '0');
        result <= (OTHERS => '0');
        rhigh <= (OTHERS => '0');
        rlow <= (OTHERS => '0');
        r1 <= (OTHERS => '0');
        r2 <= (OTHERS => '0');
        r3 <= (OTHERS => '0');
        r4 <= (OTHERS => '0');
        r5 <= (OTHERS => '0');
        r6 <= (OTHERS => '0');
        r7 <= (OTHERS => '0');
        r8 <= (OTHERS => '0');
      END IF;
    END IF;
  END PROCESS;

END ARCHITECTURE;