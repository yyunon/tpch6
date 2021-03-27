-- This source code is initialized by Yuksel Yonsel
-- rev 0.1 
-- Author: Yuksel Yonsel

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

--library ieee_proposed;
--use ieee_proposed.fixed_pkg.all;

library work;
use work.Forecast_pkg.all;
use work.Stream_pkg.all;
use work.ParallelPatterns_pkg.all;
use work.fixed_generic_pkg_mod.all;

entity Forecast is
  generic (
    INDEX_WIDTH                     : integer := 32;
    TAG_WIDTH                       : integer := 1
  );
  port (
    kcd_clk                      : in  std_logic;
    kcd_reset                    : in  std_logic;
    l_quantity_valid             : in  std_logic;
    l_quantity_ready             : out std_logic;
    l_quantity_dvalid            : in  std_logic;
    l_quantity_last              : in  std_logic;
    l_quantity                   : in  std_logic_vector(511 downto 0);
    l_quantity_count             : in  std_logic_vector(3 downto 0);
    l_extendedprice_valid        : in  std_logic;
    l_extendedprice_ready        : out std_logic;
    l_extendedprice_dvalid       : in  std_logic;
    l_extendedprice_last         : in  std_logic;
    l_extendedprice              : in  std_logic_vector(511 downto 0);
    l_extendedprice_count        : in  std_logic_vector(3 downto 0);
    l_discount_valid             : in  std_logic;
    l_discount_ready             : out std_logic;
    l_discount_dvalid            : in  std_logic;
    l_discount_last              : in  std_logic;
    l_discount                   : in  std_logic_vector(511 downto 0);
    l_discount_count             : in  std_logic_vector(3 downto 0);
    l_shipdate_valid             : in  std_logic;
    l_shipdate_ready             : out std_logic;
    l_shipdate_dvalid            : in  std_logic;
    l_shipdate_last              : in  std_logic;
    l_shipdate                   : in  std_logic_vector(511 downto 0);
    l_shipdate_count             : in  std_logic_vector(3 downto 0);
    l_quantity_unl_valid         : in  std_logic;
    l_quantity_unl_ready         : out std_logic;
    l_quantity_unl_tag           : in  std_logic_vector(TAG_WIDTH-1 downto 0);
    l_extendedprice_unl_valid    : in  std_logic;
    l_extendedprice_unl_ready    : out std_logic;
    l_extendedprice_unl_tag      : in  std_logic_vector(TAG_WIDTH-1 downto 0);
    l_discount_unl_valid         : in  std_logic;
    l_discount_unl_ready         : out std_logic;
    l_discount_unl_tag           : in  std_logic_vector(TAG_WIDTH-1 downto 0);
    l_shipdate_unl_valid         : in  std_logic;
    l_shipdate_unl_ready         : out std_logic;
    l_shipdate_unl_tag           : in  std_logic_vector(TAG_WIDTH-1 downto 0);
    l_quantity_cmd_valid         : out std_logic;
    l_quantity_cmd_ready         : in  std_logic;
    l_quantity_cmd_firstIdx      : out std_logic_vector(INDEX_WIDTH-1 downto 0);
    l_quantity_cmd_lastIdx       : out std_logic_vector(INDEX_WIDTH-1 downto 0);
    l_quantity_cmd_tag           : out std_logic_vector(TAG_WIDTH-1 downto 0);
    l_extendedprice_cmd_valid    : out std_logic;
    l_extendedprice_cmd_ready    : in  std_logic;
    l_extendedprice_cmd_firstIdx : out std_logic_vector(INDEX_WIDTH-1 downto 0);
    l_extendedprice_cmd_lastIdx  : out std_logic_vector(INDEX_WIDTH-1 downto 0);
    l_extendedprice_cmd_tag      : out std_logic_vector(TAG_WIDTH-1 downto 0);
    l_discount_cmd_valid         : out std_logic;
    l_discount_cmd_ready         : in  std_logic;
    l_discount_cmd_firstIdx      : out std_logic_vector(INDEX_WIDTH-1 downto 0);
    l_discount_cmd_lastIdx       : out std_logic_vector(INDEX_WIDTH-1 downto 0);
    l_discount_cmd_tag           : out std_logic_vector(TAG_WIDTH-1 downto 0);
    l_shipdate_cmd_valid         : out std_logic;
    l_shipdate_cmd_ready         : in  std_logic;
    l_shipdate_cmd_firstIdx      : out std_logic_vector(INDEX_WIDTH-1 downto 0);
    l_shipdate_cmd_lastIdx       : out std_logic_vector(INDEX_WIDTH-1 downto 0);
    l_shipdate_cmd_tag           : out std_logic_vector(TAG_WIDTH-1 downto 0);
    start                        : in  std_logic;
    stop                         : in  std_logic;
    reset                        : in  std_logic;
    idle                         : out std_logic;
    busy                         : out std_logic;
    done                         : out std_logic;
    result                       : out std_logic_vector(63 downto 0);
    l_firstidx                   : in  std_logic_vector(31 downto 0);
    l_lastidx                    : in  std_logic_vector(31 downto 0);
    status_1                     : out std_logic_vector(31 downto 0);
    status_2                     : out std_logic_vector(31 downto 0);
    rhigh                        : out std_logic_vector(31 downto 0);
    rlow                         : out std_logic_vector(31 downto 0);
    r1                           : out std_logic_vector(63 downto 0);
    r2                           : out std_logic_vector(63 downto 0);
    r3                           : out std_logic_vector(63 downto 0);
    r4                           : out std_logic_vector(63 downto 0);
    r5                           : out std_logic_vector(63 downto 0);
    r6                           : out std_logic_vector(63 downto 0);
    r7                           : out std_logic_vector(63 downto 0);
    r8                           : out std_logic_vector(63 downto 0)

);
end entity;

architecture Implementation of Forecast is 

  constant DATA_WIDTH               : integer := 64;
  constant EPC                      : integer := 8;
  constant FIXED_LEFT_INDEX         : integer := 45;
  constant FIXED_RIGHT_INDEX        : integer := FIXED_LEFT_INDEX - (DATA_WIDTH-1);
 
  constant SYNC_IN_BUFFER_DEPTH     : integer := 2;
  constant SYNC_OUT_BUFFER_DEPTH    : integer := 2;

  -- If the input stream size is not divisible by EPC check this:
  signal   pu_mask                  : std_logic_vector(EPC - 1 downto 0);
  -- Enumeration type for our state machine.
  type state_t is (STATE_IDLE, 
                   STATE_COMMAND, 
                   STATE_CALCULATING, 
                   STATE_UNLOCK, 
                   STATE_DONE);
                   
  signal state_slv                  : std_logic_vector(2 downto 0);


  
  -- Current state register and next state signal.
  signal state, state_next          : state_t;

  -- Buffered inputs
  signal buf_l_quantity_valid       : std_logic;
  signal buf_l_quantity_ready       : std_logic;
  signal buf_l_quantity_dvalid      : std_logic;
  signal buf_l_quantity_last        : std_logic;
  signal buf_l_quantity             : std_logic_vector(DATA_WIDTH * EPC - 1 downto 0);
  signal buf_l_quantity_0           : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal buf_l_quantity_1           : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal buf_l_quantity_2           : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal buf_l_quantity_3           : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal buf_l_quantity_4           : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal buf_l_quantity_5           : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal buf_l_quantity_6           : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal buf_l_quantity_7           : std_logic_vector(DATA_WIDTH - 1 downto 0);

  signal buf_l_discount_valid       : std_logic;
  signal buf_l_discount_ready       : std_logic;
  signal buf_l_discount_dvalid      : std_logic;
  signal buf_l_discount_last        : std_logic;
  signal buf_l_discount             : std_logic_vector(DATA_WIDTH * EPC -1 downto 0);
  signal buf_l_discount_0           : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal buf_l_discount_1           : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal buf_l_discount_2           : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal buf_l_discount_3           : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal buf_l_discount_4           : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal buf_l_discount_5           : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal buf_l_discount_6           : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal buf_l_discount_7           : std_logic_vector(DATA_WIDTH - 1 downto 0);

  signal buf_l_extendedprice_valid  : std_logic;
  signal buf_l_extendedprice_ready  : std_logic;
  signal buf_l_extendedprice_dvalid : std_logic;
  signal buf_l_extendedprice_last   : std_logic;
  signal buf_l_extendedprice        : std_logic_vector(DATA_WIDTH * EPC - 1 downto 0);
  signal buf_l_extendedprice_0           : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal buf_l_extendedprice_1           : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal buf_l_extendedprice_2           : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal buf_l_extendedprice_3           : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal buf_l_extendedprice_4           : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal buf_l_extendedprice_5           : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal buf_l_extendedprice_6           : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal buf_l_extendedprice_7           : std_logic_vector(DATA_WIDTH - 1 downto 0);

  signal buf_l_shipdate_valid       : std_logic;
  signal buf_l_shipdate_ready       : std_logic;
  signal buf_l_shipdate_dvalid      : std_logic;
  signal buf_l_shipdate_last        : std_logic;
  signal buf_l_shipdate             : std_logic_vector(DATA_WIDTH * EPC - 1 downto 0);
  signal buf_l_shipdate_0           : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal buf_l_shipdate_1           : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal buf_l_shipdate_2           : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal buf_l_shipdate_3           : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal buf_l_shipdate_4           : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal buf_l_shipdate_5           : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal buf_l_shipdate_6           : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal buf_l_shipdate_7           : std_logic_vector(DATA_WIDTH - 1 downto 0);

  -- Buffered and decoded inputs
  signal dec_l_quantity_valid       : std_logic_vector(EPC-1 downto 0);
  signal dec_l_quantity_ready       : std_logic_vector(EPC-1 downto 0);
  signal dec_l_quantity_dvalid      : std_logic;
  signal dec_l_quantity_last        : std_logic;
  signal dec_l_quantity             : std_logic_vector(DATA_WIDTH * EPC - 1 downto 0);

  signal dec_l_quantity_dvalid_0        : std_logic;
  signal dec_l_quantity_dvalid_1        : std_logic;
  signal dec_l_quantity_dvalid_2        : std_logic;
  signal dec_l_quantity_dvalid_3        : std_logic;
  signal dec_l_quantity_dvalid_4        : std_logic;
  signal dec_l_quantity_dvalid_5        : std_logic;
  signal dec_l_quantity_dvalid_6        : std_logic;
  signal dec_l_quantity_dvalid_7        : std_logic;

  signal dec_l_quantity_last_0        : std_logic;
  signal dec_l_quantity_last_1        : std_logic;
  signal dec_l_quantity_last_2        : std_logic;
  signal dec_l_quantity_last_3        : std_logic;
  signal dec_l_quantity_last_4        : std_logic;
  signal dec_l_quantity_last_5        : std_logic;
  signal dec_l_quantity_last_6        : std_logic;
  signal dec_l_quantity_last_7        : std_logic;

  signal dec_l_quantity_0             : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal dec_l_quantity_1             : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal dec_l_quantity_2            : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal dec_l_quantity_3             : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal dec_l_quantity_4             : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal dec_l_quantity_5             : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal dec_l_quantity_6             : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal dec_l_quantity_7             : std_logic_vector(DATA_WIDTH - 1 downto 0);

  signal dec_l_discount_valid       : std_logic_vector(EPC-1 downto 0);
  signal dec_l_discount_ready       : std_logic_vector(EPC-1 downto 0);
  signal dec_l_discount_dvalid      : std_logic;
  signal dec_l_discount_last        : std_logic;
  signal dec_l_discount             : std_logic_vector(DATA_WIDTH * EPC - 1 downto 0);

  signal dec_l_discount_dvalid_0        : std_logic;
  signal dec_l_discount_dvalid_1        : std_logic;
  signal dec_l_discount_dvalid_2        : std_logic;
  signal dec_l_discount_dvalid_3        : std_logic;
  signal dec_l_discount_dvalid_4        : std_logic;
  signal dec_l_discount_dvalid_5        : std_logic;
  signal dec_l_discount_dvalid_6        : std_logic;
  signal dec_l_discount_dvalid_7        : std_logic;

  signal dec_l_discount_last_0        : std_logic;
  signal dec_l_discount_last_1        : std_logic;
  signal dec_l_discount_last_2        : std_logic;
  signal dec_l_discount_last_3        : std_logic;
  signal dec_l_discount_last_4        : std_logic;
  signal dec_l_discount_last_5        : std_logic;
  signal dec_l_discount_last_6        : std_logic;
  signal dec_l_discount_last_7        : std_logic;

  signal dec_l_discount_0             : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal dec_l_discount_1             : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal dec_l_discount_2            : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal dec_l_discount_3             : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal dec_l_discount_4             : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal dec_l_discount_5             : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal dec_l_discount_6             : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal dec_l_discount_7             : std_logic_vector(DATA_WIDTH - 1 downto 0);

  signal dec_l_extendedprice_valid  : std_logic_vector(EPC-1 downto 0);
  signal dec_l_extendedprice_ready  : std_logic_vector(EPC-1 downto 0);
  signal dec_l_extendedprice_dvalid : std_logic;
  signal dec_l_extendedprice_last   : std_logic;
  signal dec_l_extendedprice        : std_logic_vector(DATA_WIDTH * EPC - 1 downto 0);


  signal dec_l_extendedprice_dvalid_0        : std_logic;
  signal dec_l_extendedprice_dvalid_1        : std_logic;
  signal dec_l_extendedprice_dvalid_2        : std_logic;
  signal dec_l_extendedprice_dvalid_3        : std_logic;
  signal dec_l_extendedprice_dvalid_4        : std_logic;
  signal dec_l_extendedprice_dvalid_5        : std_logic;
  signal dec_l_extendedprice_dvalid_6        : std_logic;
  signal dec_l_extendedprice_dvalid_7        : std_logic;

  signal dec_l_extendedprice_last_0        : std_logic;
  signal dec_l_extendedprice_last_1        : std_logic;
  signal dec_l_extendedprice_last_2        : std_logic;
  signal dec_l_extendedprice_last_3        : std_logic;
  signal dec_l_extendedprice_last_4        : std_logic;
  signal dec_l_extendedprice_last_5        : std_logic;
  signal dec_l_extendedprice_last_6        : std_logic;
  signal dec_l_extendedprice_last_7        : std_logic;

  signal dec_l_extendedprice_0             : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal dec_l_extendedprice_1             : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal dec_l_extendedprice_2            : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal dec_l_extendedprice_3             : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal dec_l_extendedprice_4             : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal dec_l_extendedprice_5             : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal dec_l_extendedprice_6             : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal dec_l_extendedprice_7             : std_logic_vector(DATA_WIDTH - 1 downto 0);

  signal dec_l_shipdate_valid       : std_logic_vector(EPC-1 downto 0);
  signal dec_l_shipdate_ready       : std_logic_vector(EPC-1 downto 0);
  signal dec_l_shipdate_dvalid      : std_logic;
  signal dec_l_shipdate_last        : std_logic;
  signal dec_l_shipdate             : std_logic_vector(DATA_WIDTH * EPC - 1 downto 0);

  signal dec_l_shipdate_dvalid_0        : std_logic;
  signal dec_l_shipdate_dvalid_1        : std_logic;
  signal dec_l_shipdate_dvalid_2        : std_logic;
  signal dec_l_shipdate_dvalid_3        : std_logic;
  signal dec_l_shipdate_dvalid_4        : std_logic;
  signal dec_l_shipdate_dvalid_5        : std_logic;
  signal dec_l_shipdate_dvalid_6        : std_logic;
  signal dec_l_shipdate_dvalid_7        : std_logic;

  signal dec_l_shipdate_last_0        : std_logic;
  signal dec_l_shipdate_last_1        : std_logic;
  signal dec_l_shipdate_last_2        : std_logic;
  signal dec_l_shipdate_last_3        : std_logic;
  signal dec_l_shipdate_last_4        : std_logic;
  signal dec_l_shipdate_last_5        : std_logic;
  signal dec_l_shipdate_last_6        : std_logic;
  signal dec_l_shipdate_last_7        : std_logic;

  signal dec_l_shipdate_0             : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal dec_l_shipdate_1             : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal dec_l_shipdate_2            : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal dec_l_shipdate_3             : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal dec_l_shipdate_4             : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal dec_l_shipdate_5             : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal dec_l_shipdate_6             : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal dec_l_shipdate_7             : std_logic_vector(DATA_WIDTH - 1 downto 0);

  --Stage valid ready signals
  signal quantity_valid             : std_logic_vector(EPC-1 downto 0);
  signal quantity_ready             : std_logic_vector(EPC-1 downto 0);

  signal extendedprice_valid        : std_logic_vector(EPC-1 downto 0);
  signal extendedprice_ready        : std_logic_vector(EPC-1 downto 0);

  signal discount_valid             : std_logic_vector(EPC-1 downto 0);
  signal discount_ready             : std_logic_vector(EPC-1 downto 0);

  signal shipdate_valid             : std_logic_vector(EPC-1 downto 0);
  signal shipdate_ready             : std_logic_vector(EPC-1 downto 0);

  -- Sum output stream.
  signal sum_out_valid_stages       : std_logic_vector(EPC-1 downto 0);
  signal sum_out_ready_stages       : std_logic_vector(EPC-1 downto 0);
  signal sum_out_data_stages        : std_logic_vector(DATA_WIDTH*EPC -1 downto 0);

  signal total_sum_out_valid        : std_logic;
  signal total_sum_out_ready        : std_logic;

  signal result_out_valid           : std_logic;
  signal result_out_ready           : std_logic;
  signal temp_inp_1                 : sfixed(FIXED_LEFT_INDEX downto FIXED_RIGHT_INDEX);
  signal temp_inp_2                 : sfixed(FIXED_LEFT_INDEX downto FIXED_RIGHT_INDEX);
  signal temp_inp_3                 : sfixed(FIXED_LEFT_INDEX downto FIXED_RIGHT_INDEX);
  signal temp_inp_4                 : sfixed(FIXED_LEFT_INDEX downto FIXED_RIGHT_INDEX);
  signal temp_inp_5                 : sfixed(FIXED_LEFT_INDEX downto FIXED_RIGHT_INDEX);
  signal temp_inp_6                 : sfixed(FIXED_LEFT_INDEX downto FIXED_RIGHT_INDEX);
  signal temp_inp_7                 : sfixed(FIXED_LEFT_INDEX downto FIXED_RIGHT_INDEX);
  signal temp_inp_8                 : sfixed(FIXED_LEFT_INDEX downto FIXED_RIGHT_INDEX);

  constant ONES                     : std_logic_vector(EPC - 1 downto 0) := (others => '1');

begin

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
  discount_buffer: StreamBuffer
    generic map (
     DATA_WIDTH                      => 64 * EPC + 2,
     MIN_DEPTH                       => SYNC_IN_BUFFER_DEPTH -- plus last and dvalid : Maybe later count 
    )
    port map (
      clk                            => kcd_clk,
      reset                          => kcd_reset or reset,
      in_valid                       => l_discount_valid,
      in_ready                       => l_discount_ready,
      in_data(DATA_WIDTH * EPC + 1)  => l_discount_last,
      in_data(DATA_WIDTH * EPC)      => l_discount_dvalid,
      in_data(DATA_WIDTH * EPC - 1 downto 0)=> l_discount,
      out_valid                      => buf_l_discount_valid,
      out_ready                      => buf_l_discount_ready,
      out_data(DATA_WIDTH * EPC + 1) => buf_l_discount_last,
      out_data(DATA_WIDTH * EPC)     => buf_l_discount_dvalid,
      out_data(DATA_WIDTH * EPC - 1 downto 0)=> buf_l_discount

    );

  quantity_buffer: StreamBuffer
    generic map (
     DATA_WIDTH                      => 64 * EPC + 2,
     MIN_DEPTH                       => SYNC_IN_BUFFER_DEPTH -- plus last and dvalid : Maybe later count 
    )
    port map (
      clk                            => kcd_clk,
      reset                          => kcd_reset or reset,
      in_valid                       => l_quantity_valid,
      in_ready                       => l_quantity_ready,
      in_data(DATA_WIDTH * EPC + 1)  => l_quantity_last,
      in_data(DATA_WIDTH * EPC)      => l_quantity_dvalid,
      in_data(DATA_WIDTH * EPC - 1 downto 0)=> l_quantity,
      out_valid                      => buf_l_quantity_valid,
      out_ready                      => buf_l_quantity_ready,
      out_data(DATA_WIDTH * EPC + 1) => buf_l_quantity_last,
      out_data(DATA_WIDTH * EPC)     => buf_l_quantity_dvalid,
      out_data(DATA_WIDTH * EPC - 1 downto 0)=> buf_l_quantity

    );
  extendedprice_buffer: StreamBuffer
    generic map (
     DATA_WIDTH                      => 64 * EPC + 2,
     MIN_DEPTH                       => SYNC_IN_BUFFER_DEPTH -- plus last and dvalid : Maybe later count 
    )
    port map (
      clk                            => kcd_clk,
      reset                          => kcd_reset or reset,
      in_valid                       => l_extendedprice_valid,
      in_ready                       => l_extendedprice_ready,
      in_data(DATA_WIDTH * EPC + 1)  => l_extendedprice_last,
      in_data(DATA_WIDTH * EPC)      => l_extendedprice_dvalid,
      in_data(DATA_WIDTH * EPC - 1 downto 0)=> l_extendedprice,
      out_valid                      => buf_l_extendedprice_valid,
      out_ready                      => buf_l_extendedprice_ready,
      out_data(DATA_WIDTH * EPC + 1) => buf_l_extendedprice_last,
      out_data(DATA_WIDTH * EPC)     => buf_l_extendedprice_dvalid,
      out_data(DATA_WIDTH * EPC - 1 downto 0)=> buf_l_extendedprice

    );

  shipdate_buffer: StreamBuffer
    generic map (
     DATA_WIDTH                      => 64 * EPC + 2,
     MIN_DEPTH                       => SYNC_IN_BUFFER_DEPTH -- plus last and dvalid : Maybe later count 
    )
    port map (
      clk                            => kcd_clk,
      reset                          => kcd_reset or reset,
      in_valid                       => l_shipdate_valid,
      in_ready                       => l_shipdate_ready,
      in_data(DATA_WIDTH * EPC + 1)  => l_shipdate_last,
      in_data(DATA_WIDTH * EPC)      => l_shipdate_dvalid,
      in_data(DATA_WIDTH * EPC - 1 downto 0)=> l_shipdate,
      out_valid                      => buf_l_shipdate_valid,
      out_ready                      => buf_l_shipdate_ready,
      out_data(DATA_WIDTH * EPC + 1) => buf_l_shipdate_last,
      out_data(DATA_WIDTH * EPC)     => buf_l_shipdate_dvalid,
      out_data(DATA_WIDTH * EPC - 1 downto 0)=> buf_l_shipdate

    );

  quantity_sync: StreamSync
    generic map (
      NUM_INPUTS                     => 1,
      NUM_OUTPUTS                    => EPC
    )
    port map (
      clk                            => kcd_clk,
      reset                          => kcd_reset or reset,

      in_valid(0)                    => buf_l_quantity_valid,
      in_ready(0)                    => buf_l_quantity_ready,


      out_valid                      => quantity_valid,
      out_ready                      => quantity_ready
    );

  discount_sync: StreamSync
    generic map (
      NUM_INPUTS                     => 1,
      NUM_OUTPUTS                    => EPC
    )
    port map (
      clk                            => kcd_clk,
      reset                          => kcd_reset or reset,

      in_valid(0)                    => buf_l_discount_valid,
      in_ready(0)                    => buf_l_discount_ready,


      out_valid                      => discount_valid,
      out_ready                      => discount_ready
    );

  shipdate_sync: StreamSync
    generic map (
      NUM_INPUTS                     => 1,
      NUM_OUTPUTS                    => EPC
    )
    port map (
      clk                            => kcd_clk,
      reset                          => kcd_reset or reset,

      in_valid(0)                    => buf_l_shipdate_valid,
      in_ready(0)                    => buf_l_shipdate_ready,


      out_valid                      => shipdate_valid,
      out_ready                      => shipdate_ready
    );

  extendedprice_sync: StreamSync     
    generic map (
      NUM_INPUTS                     => 1,
      NUM_OUTPUTS                    => EPC
    )
    port map (
      clk                            => kcd_clk,
      reset                          => kcd_reset or reset,

      in_valid(0)                    => buf_l_extendedprice_valid,
      in_ready(0)                    => buf_l_extendedprice_ready,


      out_valid                      => extendedprice_valid,
      out_ready                      => extendedprice_ready
    );
  -- parse each channel to corresponding PU input.
  buf_l_quantity_0 <= buf_l_quantity((0+1)* 64 - 1 downto 0 * 64);
  buf_l_quantity_1 <= buf_l_quantity((1+1)* 64 - 1 downto 1 * 64);
  buf_l_quantity_2 <= buf_l_quantity((2+1)* 64 - 1 downto 2 * 64);
  buf_l_quantity_3 <= buf_l_quantity((3+1)* 64 - 1 downto 3 * 64);
  buf_l_quantity_4 <= buf_l_quantity((4+1)* 64 - 1 downto 4 * 64);
  buf_l_quantity_5 <= buf_l_quantity((5+1)* 64 - 1 downto 5 * 64);
  buf_l_quantity_6 <= buf_l_quantity((6+1)* 64 - 1 downto 6 * 64);
  buf_l_quantity_7 <= buf_l_quantity((7+1)* 64 - 1 downto 7 * 64);
    
  buf_l_discount_0 <= buf_l_discount((0+1)* 64 - 1 downto 0 * 64);
  buf_l_discount_1 <= buf_l_discount((1+1)* 64 - 1 downto 1 * 64);
  buf_l_discount_2 <= buf_l_discount((2+1)* 64 - 1 downto 2 * 64);
  buf_l_discount_3 <= buf_l_discount((3+1)* 64 - 1 downto 3 * 64);
  buf_l_discount_4 <= buf_l_discount((4+1)* 64 - 1 downto 4 * 64);
  buf_l_discount_5 <= buf_l_discount((5+1)* 64 - 1 downto 5 * 64);
  buf_l_discount_6 <= buf_l_discount((6+1)* 64 - 1 downto 6 * 64);
  buf_l_discount_7 <= buf_l_discount((7+1)* 64 - 1 downto 7 * 64);
    
  buf_l_extendedprice_0 <= buf_l_extendedprice((0+1)* 64 - 1 downto 0 * 64);
  buf_l_extendedprice_1 <= buf_l_extendedprice((1+1)* 64 - 1 downto 1 * 64);
  buf_l_extendedprice_2 <= buf_l_extendedprice((2+1)* 64 - 1 downto 2 * 64);
  buf_l_extendedprice_3 <= buf_l_extendedprice((3+1)* 64 - 1 downto 3 * 64);
  buf_l_extendedprice_4 <= buf_l_extendedprice((4+1)* 64 - 1 downto 4 * 64);
  buf_l_extendedprice_5 <= buf_l_extendedprice((5+1)* 64 - 1 downto 5 * 64);
  buf_l_extendedprice_6 <= buf_l_extendedprice((6+1)* 64 - 1 downto 6 * 64);
  buf_l_extendedprice_7 <= buf_l_extendedprice((7+1)* 64 - 1 downto 7 * 64);
    
  buf_l_shipdate_0 <= buf_l_shipdate((0+1)* 64 - 1 downto 0 * 64);
  buf_l_shipdate_1 <= buf_l_shipdate((1+1)* 64 - 1 downto 1 * 64);
  buf_l_shipdate_2 <= buf_l_shipdate((2+1)* 64 - 1 downto 2 * 64);
  buf_l_shipdate_3 <= buf_l_shipdate((3+1)* 64 - 1 downto 3 * 64);
  buf_l_shipdate_4 <= buf_l_shipdate((4+1)* 64 - 1 downto 4 * 64);
  buf_l_shipdate_5 <= buf_l_shipdate((5+1)* 64 - 1 downto 5 * 64);
  buf_l_shipdate_6 <= buf_l_shipdate((6+1)* 64 - 1 downto 6 * 64);
  buf_l_shipdate_7 <= buf_l_shipdate((7+1)* 64 - 1 downto 7 * 64);


-- Output buf.
--------------------------------------------------------------------
  discount_buffer_pu_0: StreamBuffer
    generic map (
    DATA_WIDTH                      => 64 + 2,
    MIN_DEPTH                       => SYNC_OUT_BUFFER_DEPTH -- plus last and dvalid : Maybe later count 
    )
    port map (
      clk                              => kcd_clk,
      reset                            => kcd_reset or reset,
      in_valid                         => discount_valid(0),
      in_ready                         => discount_ready(0),
      in_data(DATA_WIDTH + 1)          => buf_l_discount_last,
      in_data(DATA_WIDTH)              => buf_l_discount_dvalid,
      in_data(DATA_WIDTH - 1 downto 0) => buf_l_discount_0,
      out_valid                        => dec_l_discount_valid(0),
      out_ready                        => dec_l_discount_ready(0),
      out_data(DATA_WIDTH + 1)         => dec_l_discount_last_0,
      out_data(DATA_WIDTH)             => dec_l_discount_dvalid_0,
      out_data(DATA_WIDTH - 1 downto 0)=> dec_l_discount_0
    );
  quantity_buffer_pu_0: StreamBuffer
    generic map (
    DATA_WIDTH                      => 64 + 2,
    MIN_DEPTH                       => SYNC_OUT_BUFFER_DEPTH -- plus last and dvalid : Maybe later count 
    )
    port map (
      clk                              => kcd_clk,
      reset                            => kcd_reset or reset,
      in_valid                         => quantity_valid(0),
      in_ready                         => quantity_ready(0),
      in_data(DATA_WIDTH + 1)          => buf_l_quantity_last,
      in_data(DATA_WIDTH)              => buf_l_quantity_dvalid,
      in_data(DATA_WIDTH - 1 downto 0) => buf_l_quantity_0,
      out_valid                        => dec_l_quantity_valid(0),
      out_ready                        => dec_l_quantity_ready(0),
      out_data(DATA_WIDTH + 1)         => dec_l_quantity_last_0,
      out_data(DATA_WIDTH)             => dec_l_quantity_dvalid_0,
      out_data(DATA_WIDTH - 1 downto 0)=> dec_l_quantity_0
    );
  extendedprice_buffer_pu_0: StreamBuffer
    generic map (
    DATA_WIDTH                      => 64 + 2,
    MIN_DEPTH                       => SYNC_OUT_BUFFER_DEPTH -- plus last and dvalid : Maybe later count 
    )
    port map (
      clk                              => kcd_clk,
      reset                            => kcd_reset or reset,
      in_valid                         => extendedprice_valid(0),
      in_ready                         => extendedprice_ready(0),
      in_data(DATA_WIDTH + 1)          => buf_l_extendedprice_last,
      in_data(DATA_WIDTH)              => buf_l_extendedprice_dvalid,
      in_data(DATA_WIDTH - 1 downto 0) => buf_l_extendedprice_0,
      out_valid                        => dec_l_extendedprice_valid(0),
      out_ready                        => dec_l_extendedprice_ready(0),
      out_data(DATA_WIDTH + 1)         => dec_l_extendedprice_last_0,
      out_data(DATA_WIDTH)             => dec_l_extendedprice_dvalid_0,
      out_data(DATA_WIDTH - 1 downto 0)=> dec_l_extendedprice_0
    );
  shipdate_buffer_pu_0: StreamBuffer
    generic map (
    DATA_WIDTH                      => 64 + 2,
    MIN_DEPTH                       => SYNC_OUT_BUFFER_DEPTH -- plus last and dvalid : Maybe later count 
    )
    port map (
      clk                              => kcd_clk,
      reset                            => kcd_reset or reset,
      in_valid                         => shipdate_valid(0),
      in_ready                         => shipdate_ready(0),
      in_data(DATA_WIDTH + 1)          => buf_l_shipdate_last,
      in_data(DATA_WIDTH)              => buf_l_shipdate_dvalid,
      in_data(DATA_WIDTH - 1 downto 0) => buf_l_shipdate_0,
      out_valid                        => dec_l_shipdate_valid(0),
      out_ready                        => dec_l_shipdate_ready(0),
      out_data(DATA_WIDTH + 1)         => dec_l_shipdate_last_0,
      out_data(DATA_WIDTH)             => dec_l_shipdate_dvalid_0,
      out_data(DATA_WIDTH - 1 downto 0)=> dec_l_shipdate_0
    );
  processing_unit_0: PU
    generic map (
      FIXED_LEFT_INDEX             => FIXED_LEFT_INDEX,
      FIXED_RIGHT_INDEX            => FIXED_RIGHT_INDEX,
      DATA_WIDTH                   => 64,
      INDEX_WIDTH                  => INDEX_WIDTH,
      CONVERTERS                   => "FLOAT_TO_FIXED", -- TODO: Implement this
      ILA                          => "TRUE"
    )
    port map (
      clk                          => kcd_clk,
      reset                        => kcd_reset or reset,
      
      l_quantity_valid             => dec_l_quantity_valid(0), 
      l_quantity_ready             => dec_l_quantity_ready(0),
      l_quantity_dvalid            => dec_l_quantity_dvalid,
      l_quantity_last              => dec_l_quantity_last,
      l_quantity                   => dec_l_quantity_0,

      l_extendedprice_valid        => dec_l_extendedprice_valid(0), 
      l_extendedprice_ready        => dec_l_extendedprice_ready(0),
      l_extendedprice_dvalid       => dec_l_extendedprice_dvalid_0,
      l_extendedprice_last         => dec_l_extendedprice_last_0,
      l_extendedprice              => dec_l_extendedprice_0,

      l_discount_valid             => dec_l_discount_valid(0), 
      l_discount_ready             => dec_l_discount_ready(0),
      l_discount_dvalid            => dec_l_discount_dvalid_0,
      l_discount_last              => dec_l_discount_last_0,
      l_discount                   => dec_l_discount_0,

      l_shipdate_valid             => dec_l_shipdate_valid(0), 
      l_shipdate_ready             => dec_l_shipdate_ready(0),
      l_shipdate_dvalid            => dec_l_shipdate_dvalid_0,
      l_shipdate_last              => dec_l_shipdate_last_0,
      l_shipdate                   => dec_l_shipdate_0,

      sum_out_valid                => sum_out_valid_stages(0),
      sum_out_ready                => sum_out_ready_stages(0),
      sum_out_data                 => sum_out_data_stages((0+1)* 64 - 1 downto 0 * 64)
    );
-------------------------------------------------------------------------------

-- Output buf.
--------------------------------------------------------------------
  discount_buffer_pu_1: StreamBuffer
    generic map (
    DATA_WIDTH                      => 64 + 2,
    MIN_DEPTH                       => SYNC_OUT_BUFFER_DEPTH -- plus last and dvalid : Maybe later count 
    )
    port map (
      clk                              => kcd_clk,
      reset                            => kcd_reset or reset,
      in_valid                         => discount_valid(1),
      in_ready                         => discount_ready(1),
      in_data(DATA_WIDTH + 1)          => buf_l_discount_last,
      in_data(DATA_WIDTH)              => buf_l_discount_dvalid,
      in_data(DATA_WIDTH - 1 downto 0) => buf_l_discount_1,
      out_valid                        => dec_l_discount_valid(1),
      out_ready                        => dec_l_discount_ready(1),
      out_data(DATA_WIDTH + 1)         => dec_l_discount_last_1,
      out_data(DATA_WIDTH)             => dec_l_discount_dvalid_1,
      out_data(DATA_WIDTH - 1 downto 0)=> dec_l_discount_1
    );
  quantity_buffer_pu_1: StreamBuffer
    generic map (
    DATA_WIDTH                      => 64 + 2,
    MIN_DEPTH                       => SYNC_OUT_BUFFER_DEPTH -- plus last and dvalid : Maybe later count 
    )
    port map (
      clk                              => kcd_clk,
      reset                            => kcd_reset or reset,
      in_valid                         => quantity_valid(1),
      in_ready                         => quantity_ready(1),
      in_data(DATA_WIDTH + 1)          => buf_l_quantity_last,
      in_data(DATA_WIDTH)              => buf_l_quantity_dvalid,
      in_data(DATA_WIDTH - 1 downto 0) => buf_l_quantity_1,
      out_valid                        => dec_l_quantity_valid(1),
      out_ready                        => dec_l_quantity_ready(1),
      out_data(DATA_WIDTH + 1)         => dec_l_quantity_last_1,
      out_data(DATA_WIDTH)             => dec_l_quantity_dvalid_1,
      out_data(DATA_WIDTH - 1 downto 0)=> dec_l_quantity_1
    );
  extendedprice_buffer_pu_1: StreamBuffer
    generic map (
    DATA_WIDTH                      => 64 + 2,
    MIN_DEPTH                       => SYNC_OUT_BUFFER_DEPTH -- plus last and dvalid : Maybe later count 
    )
    port map (
      clk                              => kcd_clk,
      reset                            => kcd_reset or reset,
      in_valid                         => extendedprice_valid(1),
      in_ready                         => extendedprice_ready(1),
      in_data(DATA_WIDTH + 1)          => buf_l_extendedprice_last,
      in_data(DATA_WIDTH)              => buf_l_extendedprice_dvalid,
      in_data(DATA_WIDTH - 1 downto 0) => buf_l_extendedprice_1,
      out_valid                        => dec_l_extendedprice_valid(1),
      out_ready                        => dec_l_extendedprice_ready(1),
      out_data(DATA_WIDTH + 1)         => dec_l_extendedprice_last_1,
      out_data(DATA_WIDTH)             => dec_l_extendedprice_dvalid_1,
      out_data(DATA_WIDTH - 1 downto 0)=> dec_l_extendedprice_1
    );
  shipdate_buffer_pu_1: StreamBuffer
    generic map (
    DATA_WIDTH                      => 64 + 2,
    MIN_DEPTH                       => SYNC_OUT_BUFFER_DEPTH -- plus last and dvalid : Maybe later count 
    )
    port map (
      clk                              => kcd_clk,
      reset                            => kcd_reset or reset,
      in_valid                         => shipdate_valid(1),
      in_ready                         => shipdate_ready(1),
      in_data(DATA_WIDTH + 1)          => buf_l_shipdate_last,
      in_data(DATA_WIDTH)              => buf_l_shipdate_dvalid,
      in_data(DATA_WIDTH - 1 downto 0) => buf_l_shipdate_1,
      out_valid                        => dec_l_shipdate_valid(1),
      out_ready                        => dec_l_shipdate_ready(1),
      out_data(DATA_WIDTH + 1)         => dec_l_shipdate_last_1,
      out_data(DATA_WIDTH)             => dec_l_shipdate_dvalid_1,
      out_data(DATA_WIDTH - 1 downto 0)=> dec_l_shipdate_1
    );
  processing_unit_1: PU
    generic map (
      FIXED_LEFT_INDEX             => FIXED_LEFT_INDEX,
      FIXED_RIGHT_INDEX            => FIXED_RIGHT_INDEX,
      DATA_WIDTH                   => 64,
      INDEX_WIDTH                  => INDEX_WIDTH,
      CONVERTERS                   => "FLOAT_TO_FIXED", -- TODO: Implement this
      ILA                          => ""
    )
    port map (
      clk                          => kcd_clk,
      reset                        => kcd_reset or reset,
      
      l_quantity_valid             => dec_l_quantity_valid(1), 
      l_quantity_ready             => dec_l_quantity_ready(1),
      l_quantity_dvalid            => dec_l_quantity_dvalid_1,
      l_quantity_last              => dec_l_quantity_last_1,
      l_quantity                   => dec_l_quantity_1,

      l_extendedprice_valid        => dec_l_extendedprice_valid(1), 
      l_extendedprice_ready        => dec_l_extendedprice_ready(1),
      l_extendedprice_dvalid       => dec_l_extendedprice_dvalid_1,
      l_extendedprice_last         => dec_l_extendedprice_last_1,
      l_extendedprice              => dec_l_extendedprice_1,

      l_discount_valid             => dec_l_discount_valid(1), 
      l_discount_ready             => dec_l_discount_ready(1),
      l_discount_dvalid            => dec_l_discount_dvalid_1,
      l_discount_last              => dec_l_discount_last_1,
      l_discount                   => dec_l_discount_1,

      l_shipdate_valid             => dec_l_shipdate_valid(1), 
      l_shipdate_ready             => dec_l_shipdate_ready(1),
      l_shipdate_dvalid            => dec_l_shipdate_dvalid_1,
      l_shipdate_last              => dec_l_shipdate_last_1,
      l_shipdate                   => dec_l_shipdate_1,

      sum_out_valid                => sum_out_valid_stages(1),
      sum_out_ready                => sum_out_ready_stages(1),
      sum_out_data                 => sum_out_data_stages((1+1)* 64 - 1 downto 1 * 64)
    );
-------------------------------------------------------------------------------

-- Output buf.
--------------------------------------------------------------------
  discount_buffer_pu_2: StreamBuffer
    generic map (
    DATA_WIDTH                      => 64 + 2,
    MIN_DEPTH                       => SYNC_OUT_BUFFER_DEPTH -- plus last and dvalid : Maybe later count 
    )
    port map (
      clk                              => kcd_clk,
      reset                            => kcd_reset or reset,
      in_valid                         => discount_valid(2),
      in_ready                         => discount_ready(2),
      in_data(DATA_WIDTH + 1)          => buf_l_discount_last,
      in_data(DATA_WIDTH)              => buf_l_discount_dvalid,
      in_data(DATA_WIDTH - 1 downto 0) => buf_l_discount_2,
      out_valid                        => dec_l_discount_valid(2),
      out_ready                        => dec_l_discount_ready(2),
      out_data(DATA_WIDTH + 1)         => dec_l_discount_last_2,
      out_data(DATA_WIDTH)             => dec_l_discount_dvalid_2,
      out_data(DATA_WIDTH - 1 downto 0)=> dec_l_discount_2
    );
  quantity_buffer_pu_2: StreamBuffer
    generic map (
    DATA_WIDTH                      => 64 + 2,
    MIN_DEPTH                       => SYNC_OUT_BUFFER_DEPTH -- plus last and dvalid : Maybe later count 
    )
    port map (
      clk                              => kcd_clk,
      reset                            => kcd_reset or reset,
      in_valid                         => quantity_valid(2),
      in_ready                         => quantity_ready(2),
      in_data(DATA_WIDTH + 1)          => buf_l_quantity_last,
      in_data(DATA_WIDTH)              => buf_l_quantity_dvalid,
      in_data(DATA_WIDTH - 1 downto 0) => buf_l_quantity_2,
      out_valid                        => dec_l_quantity_valid(2),
      out_ready                        => dec_l_quantity_ready(2),
      out_data(DATA_WIDTH + 1)         => dec_l_quantity_last_2,
      out_data(DATA_WIDTH)             => dec_l_quantity_dvalid_2,
      out_data(DATA_WIDTH - 1 downto 0)=> dec_l_quantity_2
    );
  extendedprice_buffer_pu_2: StreamBuffer
    generic map (
    DATA_WIDTH                      => 64 + 2,
    MIN_DEPTH                       => SYNC_OUT_BUFFER_DEPTH -- plus last and dvalid : Maybe later count 
    )
    port map (
      clk                              => kcd_clk,
      reset                            => kcd_reset or reset,
      in_valid                         => extendedprice_valid(2),
      in_ready                         => extendedprice_ready(2),
      in_data(DATA_WIDTH + 1)          => buf_l_extendedprice_last,
      in_data(DATA_WIDTH)              => buf_l_extendedprice_dvalid,
      in_data(DATA_WIDTH - 1 downto 0) => buf_l_extendedprice_2,
      out_valid                        => dec_l_extendedprice_valid(2),
      out_ready                        => dec_l_extendedprice_ready(2),
      out_data(DATA_WIDTH + 1)         => dec_l_extendedprice_last_2,
      out_data(DATA_WIDTH)             => dec_l_extendedprice_dvalid_2,
      out_data(DATA_WIDTH - 1 downto 0)=> dec_l_extendedprice_2
    );
  shipdate_buffer_pu_2: StreamBuffer
    generic map (
    DATA_WIDTH                      => 64 + 2,
    MIN_DEPTH                       => SYNC_OUT_BUFFER_DEPTH -- plus last and dvalid : Maybe later count 
    )
    port map (
      clk                              => kcd_clk,
      reset                            => kcd_reset or reset,
      in_valid                         => shipdate_valid(2),
      in_ready                         => shipdate_ready(2),
      in_data(DATA_WIDTH + 1)          => buf_l_shipdate_last,
      in_data(DATA_WIDTH)              => buf_l_shipdate_dvalid,
      in_data(DATA_WIDTH - 1 downto 0) => buf_l_shipdate_2,
      out_valid                        => dec_l_shipdate_valid(2),
      out_ready                        => dec_l_shipdate_ready(2),
      out_data(DATA_WIDTH + 1)         => dec_l_shipdate_last_2,
      out_data(DATA_WIDTH)             => dec_l_shipdate_dvalid_2,
      out_data(DATA_WIDTH - 1 downto 0)=> dec_l_shipdate_2
    );
  processing_unit_2: PU
    generic map (
      FIXED_LEFT_INDEX             => FIXED_LEFT_INDEX,
      FIXED_RIGHT_INDEX            => FIXED_RIGHT_INDEX,
      DATA_WIDTH                   => 64,
      INDEX_WIDTH                  => INDEX_WIDTH,
      CONVERTERS                   => "FLOAT_TO_FIXED", -- TODO: Implement this
      ILA                          => ""
    )
    port map (
      clk                          => kcd_clk,
      reset                        => kcd_reset or reset,
      
      l_quantity_valid             => dec_l_quantity_valid(2), 
      l_quantity_ready             => dec_l_quantity_ready(2),
      l_quantity_dvalid            => dec_l_quantity_dvalid_2,
      l_quantity_last              => dec_l_quantity_last_2,
      l_quantity                   => dec_l_quantity_2,

      l_extendedprice_valid        => dec_l_extendedprice_valid(2), 
      l_extendedprice_ready        => dec_l_extendedprice_ready(2),
      l_extendedprice_dvalid       => dec_l_extendedprice_dvalid_2,
      l_extendedprice_last         => dec_l_extendedprice_last_2,
      l_extendedprice              => dec_l_extendedprice_2,

      l_discount_valid             => dec_l_discount_valid(2), 
      l_discount_ready             => dec_l_discount_ready(2),
      l_discount_dvalid            => dec_l_discount_dvalid_2,
      l_discount_last              => dec_l_discount_last_2,
      l_discount                   => dec_l_discount_2,

      l_shipdate_valid             => dec_l_shipdate_valid(2), 
      l_shipdate_ready             => dec_l_shipdate_ready(2),
      l_shipdate_dvalid            => dec_l_shipdate_dvalid_2,
      l_shipdate_last              => dec_l_shipdate_last_2,
      l_shipdate                   => dec_l_shipdate_2,

      sum_out_valid                => sum_out_valid_stages(2),
      sum_out_ready                => sum_out_ready_stages(2),
      sum_out_data                 => sum_out_data_stages((2+1)* 64 - 1 downto 2 * 64)
    );
-------------------------------------------------------------------------------

-- Output buf.
--------------------------------------------------------------------
  discount_buffer_pu_3: StreamBuffer
    generic map (
    DATA_WIDTH                      => 64 + 2,
    MIN_DEPTH                       => SYNC_OUT_BUFFER_DEPTH -- plus last and dvalid : Maybe later count 
    )
    port map (
      clk                              => kcd_clk,
      reset                            => kcd_reset or reset,
      in_valid                         => discount_valid(3),
      in_ready                         => discount_ready(3),
      in_data(DATA_WIDTH + 1)          => buf_l_discount_last,
      in_data(DATA_WIDTH)              => buf_l_discount_dvalid,
      in_data(DATA_WIDTH - 1 downto 0) => buf_l_discount_3,
      out_valid                        => dec_l_discount_valid(3),
      out_ready                        => dec_l_discount_ready(3),
      out_data(DATA_WIDTH + 1)         => dec_l_discount_last_3,
      out_data(DATA_WIDTH)             => dec_l_discount_dvalid_3,
      out_data(DATA_WIDTH - 1 downto 0)=> dec_l_discount_3
    );
  quantity_buffer_pu_3: StreamBuffer
    generic map (
    DATA_WIDTH                      => 64 + 2,
    MIN_DEPTH                       => SYNC_OUT_BUFFER_DEPTH -- plus last and dvalid : Maybe later count 
    )
    port map (
      clk                              => kcd_clk,
      reset                            => kcd_reset or reset,
      in_valid                         => quantity_valid(3),
      in_ready                         => quantity_ready(3),
      in_data(DATA_WIDTH + 1)          => buf_l_quantity_last,
      in_data(DATA_WIDTH)              => buf_l_quantity_dvalid,
      in_data(DATA_WIDTH - 1 downto 0) => buf_l_quantity_3,
      out_valid                        => dec_l_quantity_valid(3),
      out_ready                        => dec_l_quantity_ready(3),
      out_data(DATA_WIDTH + 1)         => dec_l_quantity_last_3,
      out_data(DATA_WIDTH)             => dec_l_quantity_dvalid_3,
      out_data(DATA_WIDTH - 1 downto 0)=> dec_l_quantity_3
    );
  extendedprice_buffer_pu_3: StreamBuffer
    generic map (
    DATA_WIDTH                      => 64 + 2,
    MIN_DEPTH                       => SYNC_OUT_BUFFER_DEPTH -- plus last and dvalid : Maybe later count 
    )
    port map (
      clk                              => kcd_clk,
      reset                            => kcd_reset or reset,
      in_valid                         => extendedprice_valid(3),
      in_ready                         => extendedprice_ready(3),
      in_data(DATA_WIDTH + 1)          => buf_l_extendedprice_last,
      in_data(DATA_WIDTH)              => buf_l_extendedprice_dvalid,
      in_data(DATA_WIDTH - 1 downto 0) => buf_l_extendedprice_3,
      out_valid                        => dec_l_extendedprice_valid(3),
      out_ready                        => dec_l_extendedprice_ready(3),
      out_data(DATA_WIDTH + 1)         => dec_l_extendedprice_last_3,
      out_data(DATA_WIDTH)             => dec_l_extendedprice_dvalid_3,
      out_data(DATA_WIDTH - 1 downto 0)=> dec_l_extendedprice_3
    );
  shipdate_buffer_pu_3: StreamBuffer
    generic map (
    DATA_WIDTH                      => 64 + 2,
    MIN_DEPTH                       => SYNC_OUT_BUFFER_DEPTH -- plus last and dvalid : Maybe later count 
    )
    port map (
      clk                              => kcd_clk,
      reset                            => kcd_reset or reset,
      in_valid                         => shipdate_valid(3),
      in_ready                         => shipdate_ready(3),
      in_data(DATA_WIDTH + 1)          => buf_l_shipdate_last,
      in_data(DATA_WIDTH)              => buf_l_shipdate_dvalid,
      in_data(DATA_WIDTH - 1 downto 0) => buf_l_shipdate_3,
      out_valid                        => dec_l_shipdate_valid(3),
      out_ready                        => dec_l_shipdate_ready(3),
      out_data(DATA_WIDTH + 1)         => dec_l_shipdate_last_3,
      out_data(DATA_WIDTH)             => dec_l_shipdate_dvalid_3,
      out_data(DATA_WIDTH - 1 downto 0)=> dec_l_shipdate_3
    );
  processing_unit_3: PU
    generic map (
      FIXED_LEFT_INDEX             => FIXED_LEFT_INDEX,
      FIXED_RIGHT_INDEX            => FIXED_RIGHT_INDEX,
      DATA_WIDTH                   => 64,
      INDEX_WIDTH                  => INDEX_WIDTH,
      CONVERTERS                   => "FLOAT_TO_FIXED", -- TODO: Implement this
      ILA                          => ""
    )
    port map (
      clk                          => kcd_clk,
      reset                        => kcd_reset or reset,
      
      l_quantity_valid             => dec_l_quantity_valid(3), 
      l_quantity_ready             => dec_l_quantity_ready(3),
      l_quantity_dvalid            => dec_l_quantity_dvalid_3,
      l_quantity_last              => dec_l_quantity_last_3,
      l_quantity                   => dec_l_quantity_3,

      l_extendedprice_valid        => dec_l_extendedprice_valid(3), 
      l_extendedprice_ready        => dec_l_extendedprice_ready(3),
      l_extendedprice_dvalid       => dec_l_extendedprice_dvalid_3,
      l_extendedprice_last         => dec_l_extendedprice_last_3,
      l_extendedprice              => dec_l_extendedprice_3,

      l_discount_valid             => dec_l_discount_valid(3), 
      l_discount_ready             => dec_l_discount_ready(3),
      l_discount_dvalid            => dec_l_discount_dvalid_3,
      l_discount_last              => dec_l_discount_last_3,
      l_discount                   => dec_l_discount_3,

      l_shipdate_valid             => dec_l_shipdate_valid(3), 
      l_shipdate_ready             => dec_l_shipdate_ready(3),
      l_shipdate_dvalid            => dec_l_shipdate_dvalid_3,
      l_shipdate_last              => dec_l_shipdate_last_3,
      l_shipdate                   => dec_l_shipdate_3,

      sum_out_valid                => sum_out_valid_stages(3),
      sum_out_ready                => sum_out_ready_stages(3),
      sum_out_data                 => sum_out_data_stages((3+1)* 64 - 1 downto 3 * 64)
    );
-------------------------------------------------------------------------------

-- Output buf.
--------------------------------------------------------------------
  discount_buffer_pu_4: StreamBuffer
    generic map (
    DATA_WIDTH                      => 64 + 2,
    MIN_DEPTH                       => SYNC_OUT_BUFFER_DEPTH -- plus last and dvalid : Maybe later count 
    )
    port map (
      clk                              => kcd_clk,
      reset                            => kcd_reset or reset,
      in_valid                         => discount_valid(4),
      in_ready                         => discount_ready(4),
      in_data(DATA_WIDTH + 1)          => buf_l_discount_last,
      in_data(DATA_WIDTH)              => buf_l_discount_dvalid,
      in_data(DATA_WIDTH - 1 downto 0) => buf_l_discount_4,
      out_valid                        => dec_l_discount_valid(4),
      out_ready                        => dec_l_discount_ready(4),
      out_data(DATA_WIDTH + 1)         => dec_l_discount_last_4,
      out_data(DATA_WIDTH)             => dec_l_discount_dvalid_4,
      out_data(DATA_WIDTH - 1 downto 0)=> dec_l_discount_4
    );
  quantity_buffer_pu_4: StreamBuffer
    generic map (
    DATA_WIDTH                      => 64 + 2,
    MIN_DEPTH                       => SYNC_OUT_BUFFER_DEPTH -- plus last and dvalid : Maybe later count 
    )
    port map (
      clk                              => kcd_clk,
      reset                            => kcd_reset or reset,
      in_valid                         => quantity_valid(4),
      in_ready                         => quantity_ready(4),
      in_data(DATA_WIDTH + 1)          => buf_l_quantity_last,
      in_data(DATA_WIDTH)              => buf_l_quantity_dvalid,
      in_data(DATA_WIDTH - 1 downto 0) => buf_l_quantity_4,
      out_valid                        => dec_l_quantity_valid(4),
      out_ready                        => dec_l_quantity_ready(4),
      out_data(DATA_WIDTH + 1)         => dec_l_quantity_last_4,
      out_data(DATA_WIDTH)             => dec_l_quantity_dvalid_4,
      out_data(DATA_WIDTH - 1 downto 0)=> dec_l_quantity_4
    );
  extendedprice_buffer_pu_4: StreamBuffer
    generic map (
    DATA_WIDTH                      => 64 + 2,
    MIN_DEPTH                       => SYNC_OUT_BUFFER_DEPTH -- plus last and dvalid : Maybe later count 
    )
    port map (
      clk                              => kcd_clk,
      reset                            => kcd_reset or reset,
      in_valid                         => extendedprice_valid(4),
      in_ready                         => extendedprice_ready(4),
      in_data(DATA_WIDTH + 1)          => buf_l_extendedprice_last,
      in_data(DATA_WIDTH)              => buf_l_extendedprice_dvalid,
      in_data(DATA_WIDTH - 1 downto 0) => buf_l_extendedprice_4,
      out_valid                        => dec_l_extendedprice_valid(4),
      out_ready                        => dec_l_extendedprice_ready(4),
      out_data(DATA_WIDTH + 1)         => dec_l_extendedprice_last_4,
      out_data(DATA_WIDTH)             => dec_l_extendedprice_dvalid_4,
      out_data(DATA_WIDTH - 1 downto 0)=> dec_l_extendedprice_4
    );
  shipdate_buffer_pu_4: StreamBuffer
    generic map (
    DATA_WIDTH                      => 64 + 2,
    MIN_DEPTH                       => SYNC_OUT_BUFFER_DEPTH -- plus last and dvalid : Maybe later count 
    )
    port map (
      clk                              => kcd_clk,
      reset                            => kcd_reset or reset,
      in_valid                         => shipdate_valid(4),
      in_ready                         => shipdate_ready(4),
      in_data(DATA_WIDTH + 1)          => buf_l_shipdate_last,
      in_data(DATA_WIDTH)              => buf_l_shipdate_dvalid,
      in_data(DATA_WIDTH - 1 downto 0) => buf_l_shipdate_4,
      out_valid                        => dec_l_shipdate_valid(4),
      out_ready                        => dec_l_shipdate_ready(4),
      out_data(DATA_WIDTH + 1)         => dec_l_shipdate_last_4,
      out_data(DATA_WIDTH)             => dec_l_shipdate_dvalid_4,
      out_data(DATA_WIDTH - 1 downto 0)=> dec_l_shipdate_4
    );
  processing_unit_4: PU
    generic map (
      FIXED_LEFT_INDEX             => FIXED_LEFT_INDEX,
      FIXED_RIGHT_INDEX            => FIXED_RIGHT_INDEX,
      DATA_WIDTH                   => 64,
      INDEX_WIDTH                  => INDEX_WIDTH,
      CONVERTERS                   => "FLOAT_TO_FIXED", -- TODO: Implement this
      ILA                          => ""
    )
    port map (
      clk                          => kcd_clk,
      reset                        => kcd_reset or reset,
      
      l_quantity_valid             => dec_l_quantity_valid(4), 
      l_quantity_ready             => dec_l_quantity_ready(4),
      l_quantity_dvalid            => dec_l_quantity_dvalid_4,
      l_quantity_last              => dec_l_quantity_last_4,
      l_quantity                   => dec_l_quantity_4,

      l_extendedprice_valid        => dec_l_extendedprice_valid(4), 
      l_extendedprice_ready        => dec_l_extendedprice_ready(4),
      l_extendedprice_dvalid       => dec_l_extendedprice_dvalid_4,
      l_extendedprice_last         => dec_l_extendedprice_last_4,
      l_extendedprice              => dec_l_extendedprice_4,

      l_discount_valid             => dec_l_discount_valid(4), 
      l_discount_ready             => dec_l_discount_ready(4),
      l_discount_dvalid            => dec_l_discount_dvalid_4,
      l_discount_last              => dec_l_discount_last_4,
      l_discount                   => dec_l_discount_4,

      l_shipdate_valid             => dec_l_shipdate_valid(4), 
      l_shipdate_ready             => dec_l_shipdate_ready(4),
      l_shipdate_dvalid            => dec_l_shipdate_dvalid_4,
      l_shipdate_last              => dec_l_shipdate_last_4,
      l_shipdate                   => dec_l_shipdate_4,

      sum_out_valid                => sum_out_valid_stages(4),
      sum_out_ready                => sum_out_ready_stages(4),
      sum_out_data                 => sum_out_data_stages((4+1)* 64 - 1 downto 4 * 64)
    );
-------------------------------------------------------------------------------

-- Output buf.
--------------------------------------------------------------------
  discount_buffer_pu_5: StreamBuffer
    generic map (
    DATA_WIDTH                      => 64 + 2,
    MIN_DEPTH                       => SYNC_OUT_BUFFER_DEPTH -- plus last and dvalid : Maybe later count 
    )
    port map (
      clk                              => kcd_clk,
      reset                            => kcd_reset or reset,
      in_valid                         => discount_valid(5),
      in_ready                         => discount_ready(5),
      in_data(DATA_WIDTH + 1)          => buf_l_discount_last,
      in_data(DATA_WIDTH)              => buf_l_discount_dvalid,
      in_data(DATA_WIDTH - 1 downto 0) => buf_l_discount_5,
      out_valid                        => dec_l_discount_valid(5),
      out_ready                        => dec_l_discount_ready(5),
      out_data(DATA_WIDTH + 1)         => dec_l_discount_last_5,
      out_data(DATA_WIDTH)             => dec_l_discount_dvalid_5,
      out_data(DATA_WIDTH - 1 downto 0)=> dec_l_discount_5
    );
  quantity_buffer_pu_5: StreamBuffer
    generic map (
    DATA_WIDTH                      => 64 + 2,
    MIN_DEPTH                       => SYNC_OUT_BUFFER_DEPTH -- plus last and dvalid : Maybe later count 
    )
    port map (
      clk                              => kcd_clk,
      reset                            => kcd_reset or reset,
      in_valid                         => quantity_valid(5),
      in_ready                         => quantity_ready(5),
      in_data(DATA_WIDTH + 1)          => buf_l_quantity_last,
      in_data(DATA_WIDTH)              => buf_l_quantity_dvalid,
      in_data(DATA_WIDTH - 1 downto 0) => buf_l_quantity_5,
      out_valid                        => dec_l_quantity_valid(5),
      out_ready                        => dec_l_quantity_ready(5),
      out_data(DATA_WIDTH + 1)         => dec_l_quantity_last_5,
      out_data(DATA_WIDTH)             => dec_l_quantity_dvalid_5,
      out_data(DATA_WIDTH - 1 downto 0)=> dec_l_quantity_5
    );
  extendedprice_buffer_pu_5: StreamBuffer
    generic map (
    DATA_WIDTH                      => 64 + 2,
    MIN_DEPTH                       => SYNC_OUT_BUFFER_DEPTH -- plus last and dvalid : Maybe later count 
    )
    port map (
      clk                              => kcd_clk,
      reset                            => kcd_reset or reset,
      in_valid                         => extendedprice_valid(5),
      in_ready                         => extendedprice_ready(5),
      in_data(DATA_WIDTH + 1)          => buf_l_extendedprice_last,
      in_data(DATA_WIDTH)              => buf_l_extendedprice_dvalid,
      in_data(DATA_WIDTH - 1 downto 0) => buf_l_extendedprice_5,
      out_valid                        => dec_l_extendedprice_valid(5),
      out_ready                        => dec_l_extendedprice_ready(5),
      out_data(DATA_WIDTH + 1)         => dec_l_extendedprice_last_5,
      out_data(DATA_WIDTH)             => dec_l_extendedprice_dvalid_5,
      out_data(DATA_WIDTH - 1 downto 0)=> dec_l_extendedprice_5
    );
  shipdate_buffer_pu_5: StreamBuffer
    generic map (
    DATA_WIDTH                      => 64 + 2,
    MIN_DEPTH                       => SYNC_OUT_BUFFER_DEPTH -- plus last and dvalid : Maybe later count 
    )
    port map (
      clk                              => kcd_clk,
      reset                            => kcd_reset or reset,
      in_valid                         => shipdate_valid(5),
      in_ready                         => shipdate_ready(5),
      in_data(DATA_WIDTH + 1)          => buf_l_shipdate_last,
      in_data(DATA_WIDTH)              => buf_l_shipdate_dvalid,
      in_data(DATA_WIDTH - 1 downto 0) => buf_l_shipdate_5,
      out_valid                        => dec_l_shipdate_valid(5),
      out_ready                        => dec_l_shipdate_ready(5),
      out_data(DATA_WIDTH + 1)         => dec_l_shipdate_last_5,
      out_data(DATA_WIDTH)             => dec_l_shipdate_dvalid_5,
      out_data(DATA_WIDTH - 1 downto 0)=> dec_l_shipdate_5
    );
  processing_unit_5: PU
    generic map (
      FIXED_LEFT_INDEX             => FIXED_LEFT_INDEX,
      FIXED_RIGHT_INDEX            => FIXED_RIGHT_INDEX,
      DATA_WIDTH                   => 64,
      INDEX_WIDTH                  => INDEX_WIDTH,
      CONVERTERS                   => "FLOAT_TO_FIXED", -- TODO: Implement this
      ILA                          => ""
    )
    port map (
      clk                          => kcd_clk,
      reset                        => kcd_reset or reset,
      
      l_quantity_valid             => dec_l_quantity_valid(5), 
      l_quantity_ready             => dec_l_quantity_ready(5),
      l_quantity_dvalid            => dec_l_quantity_dvalid_5,
      l_quantity_last              => dec_l_quantity_last_5,
      l_quantity                   => dec_l_quantity_5,

      l_extendedprice_valid        => dec_l_extendedprice_valid(5), 
      l_extendedprice_ready        => dec_l_extendedprice_ready(5),
      l_extendedprice_dvalid       => dec_l_extendedprice_dvalid_5,
      l_extendedprice_last         => dec_l_extendedprice_last_5,
      l_extendedprice              => dec_l_extendedprice_5,

      l_discount_valid             => dec_l_discount_valid(5), 
      l_discount_ready             => dec_l_discount_ready(5),
      l_discount_dvalid            => dec_l_discount_dvalid_5,
      l_discount_last              => dec_l_discount_last_5,
      l_discount                   => dec_l_discount_5,

      l_shipdate_valid             => dec_l_shipdate_valid(5), 
      l_shipdate_ready             => dec_l_shipdate_ready(5),
      l_shipdate_dvalid            => dec_l_shipdate_dvalid_5,
      l_shipdate_last              => dec_l_shipdate_last_5,
      l_shipdate                   => dec_l_shipdate_5,

      sum_out_valid                => sum_out_valid_stages(5),
      sum_out_ready                => sum_out_ready_stages(5),
      sum_out_data                 => sum_out_data_stages((5+1)* 64 - 1 downto 5 * 64)
    );
-------------------------------------------------------------------------------

-- Output buf.
--------------------------------------------------------------------
  discount_buffer_pu_6: StreamBuffer
    generic map (
    DATA_WIDTH                      => 64 + 2,
    MIN_DEPTH                       => SYNC_OUT_BUFFER_DEPTH -- plus last and dvalid : Maybe later count 
    )
    port map (
      clk                              => kcd_clk,
      reset                            => kcd_reset or reset,
      in_valid                         => discount_valid(6),
      in_ready                         => discount_ready(6),
      in_data(DATA_WIDTH + 1)          => buf_l_discount_last,
      in_data(DATA_WIDTH)              => buf_l_discount_dvalid,
      in_data(DATA_WIDTH - 1 downto 0) => buf_l_discount_6,
      out_valid                        => dec_l_discount_valid(6),
      out_ready                        => dec_l_discount_ready(6),
      out_data(DATA_WIDTH + 1)         => dec_l_discount_last_6,
      out_data(DATA_WIDTH)             => dec_l_discount_dvalid_6,
      out_data(DATA_WIDTH - 1 downto 0)=> dec_l_discount_6
    );
  quantity_buffer_pu_6: StreamBuffer
    generic map (
    DATA_WIDTH                      => 64 + 2,
    MIN_DEPTH                       => SYNC_OUT_BUFFER_DEPTH -- plus last and dvalid : Maybe later count 
    )
    port map (
      clk                              => kcd_clk,
      reset                            => kcd_reset or reset,
      in_valid                         => quantity_valid(6),
      in_ready                         => quantity_ready(6),
      in_data(DATA_WIDTH + 1)          => buf_l_quantity_last,
      in_data(DATA_WIDTH)              => buf_l_quantity_dvalid,
      in_data(DATA_WIDTH - 1 downto 0) => buf_l_quantity_6,
      out_valid                        => dec_l_quantity_valid(6),
      out_ready                        => dec_l_quantity_ready(6),
      out_data(DATA_WIDTH + 1)         => dec_l_quantity_last_6,
      out_data(DATA_WIDTH)             => dec_l_quantity_dvalid_6,
      out_data(DATA_WIDTH - 1 downto 0)=> dec_l_quantity_6
    );
  extendedprice_buffer_pu_6: StreamBuffer
    generic map (
    DATA_WIDTH                      => 64 + 2,
    MIN_DEPTH                       => SYNC_OUT_BUFFER_DEPTH -- plus last and dvalid : Maybe later count 
    )
    port map (
      clk                              => kcd_clk,
      reset                            => kcd_reset or reset,
      in_valid                         => extendedprice_valid(6),
      in_ready                         => extendedprice_ready(6),
      in_data(DATA_WIDTH + 1)          => buf_l_extendedprice_last,
      in_data(DATA_WIDTH)              => buf_l_extendedprice_dvalid,
      in_data(DATA_WIDTH - 1 downto 0) => buf_l_extendedprice_6,
      out_valid                        => dec_l_extendedprice_valid(6),
      out_ready                        => dec_l_extendedprice_ready(6),
      out_data(DATA_WIDTH + 1)         => dec_l_extendedprice_last_6,
      out_data(DATA_WIDTH)             => dec_l_extendedprice_dvalid_6,
      out_data(DATA_WIDTH - 1 downto 0)=> dec_l_extendedprice_6
    );
  shipdate_buffer_pu_6: StreamBuffer
    generic map (
    DATA_WIDTH                      => 64 + 2,
    MIN_DEPTH                       => SYNC_OUT_BUFFER_DEPTH -- plus last and dvalid : Maybe later count 
    )
    port map (
      clk                              => kcd_clk,
      reset                            => kcd_reset or reset,
      in_valid                         => shipdate_valid(6),
      in_ready                         => shipdate_ready(6),
      in_data(DATA_WIDTH + 1)          => buf_l_shipdate_last,
      in_data(DATA_WIDTH)              => buf_l_shipdate_dvalid,
      in_data(DATA_WIDTH - 1 downto 0) => buf_l_shipdate_6,
      out_valid                        => dec_l_shipdate_valid(6),
      out_ready                        => dec_l_shipdate_ready(6),
      out_data(DATA_WIDTH + 1)         => dec_l_shipdate_last_6,
      out_data(DATA_WIDTH)             => dec_l_shipdate_dvalid_6,
      out_data(DATA_WIDTH - 1 downto 0)=> dec_l_shipdate_6
    );
  processing_unit_6: PU
    generic map (
      FIXED_LEFT_INDEX             => FIXED_LEFT_INDEX,
      FIXED_RIGHT_INDEX            => FIXED_RIGHT_INDEX,
      DATA_WIDTH                   => 64,
      INDEX_WIDTH                  => INDEX_WIDTH,
      CONVERTERS                   => "FLOAT_TO_FIXED", -- TODO: Implement this
      ILA                          => ""
    )
    port map (
      clk                          => kcd_clk,
      reset                        => kcd_reset or reset,
      
      l_quantity_valid             => dec_l_quantity_valid(6), 
      l_quantity_ready             => dec_l_quantity_ready(6),
      l_quantity_dvalid            => dec_l_quantity_dvalid_6,
      l_quantity_last              => dec_l_quantity_last_6,
      l_quantity                   => dec_l_quantity_6,

      l_extendedprice_valid        => dec_l_extendedprice_valid(6), 
      l_extendedprice_ready        => dec_l_extendedprice_ready(6),
      l_extendedprice_dvalid       => dec_l_extendedprice_dvalid_6,
      l_extendedprice_last         => dec_l_extendedprice_last_6,
      l_extendedprice              => dec_l_extendedprice_6,

      l_discount_valid             => dec_l_discount_valid(6), 
      l_discount_ready             => dec_l_discount_ready(6),
      l_discount_dvalid            => dec_l_discount_dvalid_6,
      l_discount_last              => dec_l_discount_last_6,
      l_discount                   => dec_l_discount_6,

      l_shipdate_valid             => dec_l_shipdate_valid(6), 
      l_shipdate_ready             => dec_l_shipdate_ready(6),
      l_shipdate_dvalid            => dec_l_shipdate_dvalid_6,
      l_shipdate_last              => dec_l_shipdate_last_6,
      l_shipdate                   => dec_l_shipdate_6,

      sum_out_valid                => sum_out_valid_stages(6),
      sum_out_ready                => sum_out_ready_stages(6),
      sum_out_data                 => sum_out_data_stages((6+1)* 64 - 1 downto 6 * 64)
    );
-------------------------------------------------------------------------------

-- Output buf.
--------------------------------------------------------------------
  discount_buffer_pu_7: StreamBuffer
    generic map (
    DATA_WIDTH                      => 64 + 2,
    MIN_DEPTH                       => SYNC_OUT_BUFFER_DEPTH -- plus last and dvalid : Maybe later count 
    )
    port map (
      clk                              => kcd_clk,
      reset                            => kcd_reset or reset,
      in_valid                         => discount_valid(7),
      in_ready                         => discount_ready(7),
      in_data(DATA_WIDTH + 1)          => buf_l_discount_last,
      in_data(DATA_WIDTH)              => buf_l_discount_dvalid,
      in_data(DATA_WIDTH - 1 downto 0) => buf_l_discount_7,
      out_valid                        => dec_l_discount_valid(7),
      out_ready                        => dec_l_discount_ready(7),
      out_data(DATA_WIDTH + 1)         => dec_l_discount_last_7,
      out_data(DATA_WIDTH)             => dec_l_discount_dvalid_7,
      out_data(DATA_WIDTH - 1 downto 0)=> dec_l_discount_7
    );
  quantity_buffer_pu_7: StreamBuffer
    generic map (
    DATA_WIDTH                      => 64 + 2,
    MIN_DEPTH                       => SYNC_OUT_BUFFER_DEPTH -- plus last and dvalid : Maybe later count 
    )
    port map (
      clk                              => kcd_clk,
      reset                            => kcd_reset or reset,
      in_valid                         => quantity_valid(7),
      in_ready                         => quantity_ready(7),
      in_data(DATA_WIDTH + 1)          => buf_l_quantity_last,
      in_data(DATA_WIDTH)              => buf_l_quantity_dvalid,
      in_data(DATA_WIDTH - 1 downto 0) => buf_l_quantity_7,
      out_valid                        => dec_l_quantity_valid(7),
      out_ready                        => dec_l_quantity_ready(7),
      out_data(DATA_WIDTH + 1)         => dec_l_quantity_last_7,
      out_data(DATA_WIDTH)             => dec_l_quantity_dvalid_7,
      out_data(DATA_WIDTH - 1 downto 0)=> dec_l_quantity_7
    );
  extendedprice_buffer_pu_7: StreamBuffer
    generic map (
    DATA_WIDTH                      => 64 + 2,
    MIN_DEPTH                       => SYNC_OUT_BUFFER_DEPTH -- plus last and dvalid : Maybe later count 
    )
    port map (
      clk                              => kcd_clk,
      reset                            => kcd_reset or reset,
      in_valid                         => extendedprice_valid(7),
      in_ready                         => extendedprice_ready(7),
      in_data(DATA_WIDTH + 1)          => buf_l_extendedprice_last,
      in_data(DATA_WIDTH)              => buf_l_extendedprice_dvalid,
      in_data(DATA_WIDTH - 1 downto 0) => buf_l_extendedprice_7,
      out_valid                        => dec_l_extendedprice_valid(7),
      out_ready                        => dec_l_extendedprice_ready(7),
      out_data(DATA_WIDTH + 1)         => dec_l_extendedprice_last_7,
      out_data(DATA_WIDTH)             => dec_l_extendedprice_dvalid_7,
      out_data(DATA_WIDTH - 1 downto 0)=> dec_l_extendedprice_7
    );
  shipdate_buffer_pu_7: StreamBuffer
    generic map (
    DATA_WIDTH                      => 64 + 2,
    MIN_DEPTH                       => SYNC_OUT_BUFFER_DEPTH -- plus last and dvalid : Maybe later count 
    )
    port map (
      clk                              => kcd_clk,
      reset                            => kcd_reset or reset,
      in_valid                         => shipdate_valid(7),
      in_ready                         => shipdate_ready(7),
      in_data(DATA_WIDTH + 1)          => buf_l_shipdate_last,
      in_data(DATA_WIDTH)              => buf_l_shipdate_dvalid,
      in_data(DATA_WIDTH - 1 downto 0) => buf_l_shipdate_7,
      out_valid                        => dec_l_shipdate_valid(7),
      out_ready                        => dec_l_shipdate_ready(7),
      out_data(DATA_WIDTH + 1)         => dec_l_shipdate_last_7,
      out_data(DATA_WIDTH)             => dec_l_shipdate_dvalid_7,
      out_data(DATA_WIDTH - 1 downto 0)=> dec_l_shipdate_7
    );
  processing_unit_7: PU
    generic map (
      FIXED_LEFT_INDEX             => FIXED_LEFT_INDEX,
      FIXED_RIGHT_INDEX            => FIXED_RIGHT_INDEX,
      DATA_WIDTH                   => 64,
      INDEX_WIDTH                  => INDEX_WIDTH,
      CONVERTERS                   => "FLOAT_TO_FIXED", -- TODO: Implement this
      ILA                          => ""
    )
    port map (
      clk                          => kcd_clk,
      reset                        => kcd_reset or reset,
      
      l_quantity_valid             => dec_l_quantity_valid(7), 
      l_quantity_ready             => dec_l_quantity_ready(7),
      l_quantity_dvalid            => dec_l_quantity_dvalid_7,
      l_quantity_last              => dec_l_quantity_last_7,
      l_quantity                   => dec_l_quantity_7,

      l_extendedprice_valid        => dec_l_extendedprice_valid(7), 
      l_extendedprice_ready        => dec_l_extendedprice_ready(7),
      l_extendedprice_dvalid       => dec_l_extendedprice_dvalid_7,
      l_extendedprice_last         => dec_l_extendedprice_last_7,
      l_extendedprice              => dec_l_extendedprice_7,

      l_discount_valid             => dec_l_discount_valid(7), 
      l_discount_ready             => dec_l_discount_ready(7),
      l_discount_dvalid            => dec_l_discount_dvalid_7,
      l_discount_last              => dec_l_discount_last_7,
      l_discount                   => dec_l_discount_7,

      l_shipdate_valid             => dec_l_shipdate_valid(7), 
      l_shipdate_ready             => dec_l_shipdate_ready(7),
      l_shipdate_dvalid            => dec_l_shipdate_dvalid_7,
      l_shipdate_last              => dec_l_shipdate_last_7,
      l_shipdate                   => dec_l_shipdate_7,

      sum_out_valid                => sum_out_valid_stages(7),
      sum_out_ready                => sum_out_ready_stages(7),
      sum_out_data                 => sum_out_data_stages((7+1)* 64 - 1 downto 7 * 64)
    );
-------------------------------------------------------------------------------
  temp_inp_1 <= to_sfixed(sum_out_data_stages(DATA_WIDTH - 1 downto 0), FIXED_LEFT_INDEX, FIXED_RIGHT_INDEX);
  temp_inp_2 <= to_sfixed(sum_out_data_stages(2*DATA_WIDTH - 1 downto DATA_WIDTH), FIXED_LEFT_INDEX, FIXED_RIGHT_INDEX);
  temp_inp_3 <= to_sfixed(sum_out_data_stages(3*DATA_WIDTH - 1 downto 2 * DATA_WIDTH), FIXED_LEFT_INDEX, FIXED_RIGHT_INDEX);
  temp_inp_4 <= to_sfixed(sum_out_data_stages(4*DATA_WIDTH - 1 downto 3 * DATA_WIDTH), FIXED_LEFT_INDEX, FIXED_RIGHT_INDEX);
  temp_inp_5 <= to_sfixed(sum_out_data_stages(5*DATA_WIDTH - 1 downto 4 * DATA_WIDTH), FIXED_LEFT_INDEX, FIXED_RIGHT_INDEX);
  temp_inp_6 <= to_sfixed(sum_out_data_stages(6*DATA_WIDTH - 1 downto 5 * DATA_WIDTH), FIXED_LEFT_INDEX, FIXED_RIGHT_INDEX);
  temp_inp_7 <= to_sfixed(sum_out_data_stages(7*DATA_WIDTH - 1 downto 6 * DATA_WIDTH), FIXED_LEFT_INDEX, FIXED_RIGHT_INDEX);
  temp_inp_8 <= to_sfixed(sum_out_data_stages(8*DATA_WIDTH - 1 downto 7 * DATA_WIDTH), FIXED_LEFT_INDEX, FIXED_RIGHT_INDEX);


  with state select state_slv <= 
               "000" when STATE_COMMAND,
               "011" when STATE_CALCULATING,
               "100" when STATE_UNLOCK,
               "101" when others;

  combinatorial_proc : process (
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
    ) is 
  begin

    l_quantity_cmd_valid             <= '0';
    l_quantity_cmd_firstIdx          <= (others => '0');
    l_quantity_cmd_lastIdx           <= (others => '0');
    l_quantity_cmd_tag               <= (others => '0');
    
    l_quantity_unl_ready             <= '0'; -- Do not accept "unlocks".

    l_discount_cmd_valid             <= '0';
    l_discount_cmd_firstIdx          <= (others => '0');
    l_discount_cmd_lastIdx           <= (others => '0');
    l_discount_cmd_tag               <= (others => '0');
    
    l_discount_unl_ready             <= '0'; -- Do not accept "unlocks".

    l_shipdate_cmd_valid             <= '0';
    l_shipdate_cmd_firstIdx          <= (others => '0');
    l_shipdate_cmd_lastIdx           <= (others => '0');
    l_shipdate_cmd_tag               <= (others => '0');
    
    l_shipdate_unl_ready             <= '0'; -- Do not accept "unlocks".

    l_extendedprice_cmd_valid        <= '0';
    l_extendedprice_cmd_firstIdx     <= (others => '0');
    l_extendedprice_cmd_lastIdx      <= (others => '0');
    l_extendedprice_cmd_tag          <= (others => '0');
    
    l_extendedprice_unl_ready        <= '0'; -- Do not accept "unlocks".
    state_next                       <= state; -- Retain current state.

    sum_out_ready_stages             <= (others => '0');

    case state is
      when STATE_IDLE =>
        -- Idle: We just wait for the start bit to come up.
        done <= '0';
        busy <= '0';
        idle <= '1';
                
        -- Wait for the start signal (typically controlled by the host-side 
        -- software).
        if start = '1' then
          state_next <= STATE_COMMAND;
        end if;

      when STATE_COMMAND =>
        -- Command: we send a command to the generated interface.
        done <= '0';
        busy <= '1';  
        idle <= '0';

                
        l_quantity_cmd_valid         <= '1';
        l_quantity_cmd_firstIdx      <= l_firstIdx;
        l_quantity_cmd_lastIdx       <= l_lastIdx;
        l_quantity_cmd_tag           <= (others => '0');
        
        l_extendedprice_cmd_valid    <= '1';
        l_extendedprice_cmd_firstIdx <= l_firstIdx;
        l_extendedprice_cmd_lastIdx  <= l_lastIdx;
        l_extendedprice_cmd_tag      <= (others => '0');

        l_shipdate_cmd_valid         <= '1';
        l_shipdate_cmd_firstIdx      <= l_firstIdx;
        l_shipdate_cmd_lastIdx       <= l_lastIdx;
        l_shipdate_cmd_tag           <= (others => '0');

        l_discount_cmd_valid         <= '1';
        l_discount_cmd_firstIdx      <= l_firstIdx;
        l_discount_cmd_lastIdx       <= l_lastIdx;
        l_discount_cmd_tag           <= (others => '0');

        if l_quantity_cmd_ready = '1' and l_extendedprice_cmd_ready = '1' and l_shipdate_cmd_ready = '1' and l_discount_cmd_ready = '1' then
          state_next <= STATE_CALCULATING;
        end if;

      when STATE_CALCULATING =>
        -- Calculating: we stream in and accumulate the numbers one by one. PROBE Phase is here!
        done                         <= '0';
        busy                         <= '1';  
        idle                         <= '0';
        
        sum_out_ready_stages         <= (others => '1');

        if sum_out_valid_stages = ONES then
          state_next                 <= STATE_UNLOCK;
        end if;
        
      when STATE_UNLOCK =>
        -- Unlock: the generated interface delivered all items in the stream.
        -- The unlock stream is supplied to make sure all bus transfers of the
        -- corresponding command are completed.
        done                         <= '1';
        busy                         <= '0';
        idle                         <= '1';
        
        -- Ready to handshake the unlock stream:
        l_quantity_unl_ready         <= '1';
        l_discount_unl_ready         <= '1';
        l_shipdate_unl_ready         <= '1';
        l_extendedprice_unl_ready    <= '1';
        -- Handshake when it is valid and go to the done state.
        -- if s_store_sk_unl_valid = '1' then
        if l_discount_unl_valid = '1' and l_quantity_unl_valid = '1' and l_shipdate_unl_valid = '1'  and l_extendedprice_unl_valid = '1' then
          state_next                 <= STATE_DONE;
        end if;

      when STATE_DONE =>
        -- Done: the kernel is done with its job.
        done                         <= '1';
        busy                         <= '0';
        idle                         <= '1';
        
        -- Wait for the reset signal (typically controlled by the host-side 
        -- software), so we can go to idle again. This reset is not to be
        -- confused with the system-wide reset that travels into the kernel
        -- alongside the clock (kcd_reset).        
    end case;
  end process;
  
 -- Sequential part:
  sequential_proc: process (kcd_clk)
    variable result_out_data    : std_logic_vector(DATA_WIDTH - 1 downto 0);
    variable temp_acc           : sfixed(FIXED_LEFT_INDEX + (EPC - 1) downto FIXED_RIGHT_INDEX);
  begin
    -- On the rising edge of the kernel clock:
    if rising_edge(kcd_clk) then
      -- Register the next state.
      state    <= state_next;        
      status_1  <= (31 downto EPC => '0') & sum_out_valid_stages;
      result_out_data := (others => '0');
      temp_acc := (others => '0');

      if sum_out_valid_stages = ONES then
        temp_acc := temp_inp_1 + temp_inp_2 + temp_inp_3 + temp_inp_4 + temp_inp_5 + temp_inp_6 + temp_inp_7 + temp_inp_8;
        result_out_data := to_slv(resize( arg => temp_acc,left_index => FIXED_LEFT_INDEX, right_index => FIXED_RIGHT_INDEX, round_style => fixed_round_style, overflow_style => fixed_overflow_style));
        result <= result_out_data;
        rhigh  <= result_out_data(63 downto 32);
        rlow   <= result_out_data(31 downto 0);
      end if;
      if(sum_out_valid_stages(0) = '0') then 
        r1     <= to_slv(resize( arg => temp_inp_1,left_index => FIXED_LEFT_INDEX, right_index => FIXED_RIGHT_INDEX, round_style => fixed_round_style, overflow_style => fixed_overflow_style));
      end if;
      if(sum_out_valid_stages(1) = '0') then 
        r2     <= to_slv(resize( arg => temp_inp_2,left_index => FIXED_LEFT_INDEX, right_index => FIXED_RIGHT_INDEX, round_style => fixed_round_style, overflow_style => fixed_overflow_style));   
      end if;
      if(sum_out_valid_stages(2) = '0') then 
        r3     <= to_slv(resize( arg => temp_inp_3,left_index => FIXED_LEFT_INDEX, right_index => FIXED_RIGHT_INDEX, round_style => fixed_round_style, overflow_style => fixed_overflow_style));   
      end if;
      if(sum_out_valid_stages(3) = '0') then 
        r4     <= to_slv(resize( arg => temp_inp_4,left_index => FIXED_LEFT_INDEX, right_index => FIXED_RIGHT_INDEX, round_style => fixed_round_style, overflow_style => fixed_overflow_style));   
      end if;
      if(sum_out_valid_stages(4) = '0') then 
        r5     <= to_slv(resize( arg => temp_inp_5,left_index => FIXED_LEFT_INDEX, right_index => FIXED_RIGHT_INDEX, round_style => fixed_round_style, overflow_style => fixed_overflow_style));   
      end if;
      if(sum_out_valid_stages(5) = '0') then 
        r6     <= to_slv(resize( arg => temp_inp_6,left_index => FIXED_LEFT_INDEX, right_index => FIXED_RIGHT_INDEX, round_style => fixed_round_style, overflow_style => fixed_overflow_style));   
      end if;
      if(sum_out_valid_stages(6) = '0') then 
        r7     <= to_slv(resize( arg => temp_inp_7,left_index => FIXED_LEFT_INDEX, right_index => FIXED_RIGHT_INDEX, round_style => fixed_round_style, overflow_style => fixed_overflow_style));   
      end if;
      if(sum_out_valid_stages(7) = '0') then 
        r8     <= to_slv(resize( arg => temp_inp_8,left_index => FIXED_LEFT_INDEX, right_index => FIXED_RIGHT_INDEX, round_style => fixed_round_style, overflow_style => fixed_overflow_style));   
      end if;

      if kcd_reset = '1' or reset = '1' then
        state  <= STATE_IDLE;
        status_1  <= (others => '0');
        status_2 <= (others => '0');
        result <= (others => '0');
        rhigh  <= (others => '0');
        rlow   <= (others => '0');
        r1     <= (others => '0');   
        r2     <= (others => '0');                           
        r3     <= (others => '0');                           
        r4     <= (others => '0');                           
        r5     <= (others => '0');                           
        r6     <= (others => '0');                           
        r7     <= (others => '0');                           
        r8     <= (others => '0');                           
      end if;
    end if;
  end process;

end architecture;

