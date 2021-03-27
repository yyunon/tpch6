-- This source code is initialized by Yuksel Yonsel
-- rev 0.1 
-- Author: Yuksel Yonsel

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

library ieee_proposed;
use ieee_proposed.fixed_pkg.all;

library work;
use work.Forecast_pkg.all;
use work.Stream_pkg.all;
use work.ParallelPatterns_pkg.all;
--use work.fixed_generic_pkg_mod.all;

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


  signal buf_l_discount_valid       : std_logic;
  signal buf_l_discount_ready       : std_logic;
  signal buf_l_discount_dvalid      : std_logic;
  signal buf_l_discount_last        : std_logic;
  signal buf_l_discount             : std_logic_vector(DATA_WIDTH * EPC -1 downto 0);


  signal buf_l_extendedprice_valid  : std_logic;
  signal buf_l_extendedprice_ready  : std_logic;
  signal buf_l_extendedprice_dvalid : std_logic;
  signal buf_l_extendedprice_last   : std_logic;
  signal buf_l_extendedprice        : std_logic_vector(DATA_WIDTH * EPC - 1 downto 0);


  signal buf_l_shipdate_valid       : std_logic;
  signal buf_l_shipdate_ready       : std_logic;
  signal buf_l_shipdate_dvalid      : std_logic;
  signal buf_l_shipdate_last        : std_logic;
  signal buf_l_shipdate             : std_logic_vector(DATA_WIDTH * EPC - 1 downto 0);

  -- Buffered and decoded inputs
  signal dec_l_quantity_valid       : std_logic_vector(EPC-1 downto 0);
  signal dec_l_quantity_ready       : std_logic_vector(EPC-1 downto 0);
  signal dec_l_quantity_dvalid      : std_logic_vector(EPC-1 downto 0);
  signal dec_l_quantity_last        : std_logic_vector(EPC-1 downto 0);
  signal dec_l_quantity             : std_logic_vector(DATA_WIDTH * EPC - 1 downto 0);

  signal dec_l_discount_valid       : std_logic_vector(EPC-1 downto 0);
  signal dec_l_discount_ready       : std_logic_vector(EPC-1 downto 0);
  signal dec_l_discount_dvalid      : std_logic_vector(EPC-1 downto 0);
  signal dec_l_discount_last        : std_logic_vector(EPC-1 downto 0);
  signal dec_l_discount             : std_logic_vector(DATA_WIDTH * EPC - 1 downto 0);

  signal dec_l_extendedprice_valid  : std_logic_vector(EPC-1 downto 0);
  signal dec_l_extendedprice_ready  : std_logic_vector(EPC-1 downto 0);
  signal dec_l_extendedprice_dvalid : std_logic_vector(EPC-1 downto 0);
  signal dec_l_extendedprice_last   : std_logic_vector(EPC-1 downto 0);
  signal dec_l_extendedprice        : std_logic_vector(DATA_WIDTH * EPC - 1 downto 0);


  signal dec_l_shipdate_valid       : std_logic_vector(EPC-1 downto 0);
  signal dec_l_shipdate_ready       : std_logic_vector(EPC-1 downto 0);
  signal dec_l_shipdate_dvalid      : std_logic_vector(EPC-1 downto 0);
  signal dec_l_shipdate_last        : std_logic_vector(EPC-1 downto 0);
  signal dec_l_shipdate             : std_logic_vector(DATA_WIDTH * EPC - 1 downto 0);

  --Stage valid ready signals
  signal quantity_valid             : std_logic_vector(EPC-1 downto 0);
  signal quantity_ready             : std_logic_vector(EPC-1 downto 0);
  signal quantity_dvalid             : std_logic_vector(EPC-1 downto 0);
  signal quantity_last             : std_logic_vector(EPC-1 downto 0);

  signal extendedprice_valid        : std_logic_vector(EPC-1 downto 0);
  signal extendedprice_ready        : std_logic_vector(EPC-1 downto 0);
  signal extendedprice_dvalid        : std_logic_vector(EPC-1 downto 0);
  signal extendedprice_last        : std_logic_vector(EPC-1 downto 0);

  signal discount_valid             : std_logic_vector(EPC-1 downto 0);
  signal discount_ready             : std_logic_vector(EPC-1 downto 0);
  signal discount_dvalid             : std_logic_vector(EPC-1 downto 0);
  signal discount_last             : std_logic_vector(EPC-1 downto 0);

  signal shipdate_valid             : std_logic_vector(EPC-1 downto 0);
  signal shipdate_ready             : std_logic_vector(EPC-1 downto 0);
  signal shipdate_dvalid             : std_logic_vector(EPC-1 downto 0);
  signal shipdate_last            : std_logic_vector(EPC-1 downto 0);

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
assign_last_valid_signals:
for i in 0 to EPC-1 generate

  discount_dvalid(I) <= buf_l_discount_dvalid; 
  extendedprice_dvalid(I) <= buf_l_extendedprice_dvalid; 
  shipdate_dvalid(I) <= buf_l_shipdate_dvalid; 
  quantity_dvalid(I) <= buf_l_quantity_dvalid; 

  discount_last(I) <= buf_l_discount_last; 
  extendedprice_last(I) <= buf_l_extendedprice_last; 
  shipdate_last(I) <= buf_l_shipdate_last; 
  quantity_last(I) <= buf_l_quantity_last; 
end generate;

parallel_pu_gen:
for I in 0 to EPC-1 generate 
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
        in_valid                         => discount_valid(I),
        in_ready                         => discount_ready(I),
        in_data(DATA_WIDTH + 1)          => discount_last(I),
        in_data(DATA_WIDTH)              => discount_dvalid(I),
        in_data(DATA_WIDTH - 1 downto 0) => buf_l_discount((I+1)* 64 - 1 downto I * 64),
        out_valid                        => dec_l_discount_valid(I),
        out_ready                        => dec_l_discount_ready(I),
        out_data(DATA_WIDTH + 1)         => dec_l_discount_last(I),
        out_data(DATA_WIDTH)             => dec_l_discount_dvalid(I),
        out_data(DATA_WIDTH - 1 downto 0)=> dec_l_discount((I+1)* 64 - 1 downto I * 64)
      );
    quantity_buffer_pu_0: StreamBuffer
      generic map (
      DATA_WIDTH                      => 64 + 2,
      MIN_DEPTH                       => SYNC_OUT_BUFFER_DEPTH -- plus last and dvalid : Maybe later count 
      )
      port map (
        clk                              => kcd_clk,
        reset                            => kcd_reset or reset,
        in_valid                         => quantity_valid(I),
        in_ready                         => quantity_ready(I),
        in_data(DATA_WIDTH + 1)          => quantity_last(I),
        in_data(DATA_WIDTH)              => quantity_dvalid(I),
        in_data(DATA_WIDTH - 1 downto 0) => buf_l_quantity((I+1)* 64 - 1 downto I * 64),
        out_valid                        => dec_l_quantity_valid(I),
        out_ready                        => dec_l_quantity_ready(I),
        out_data(DATA_WIDTH + 1)         => dec_l_quantity_last(I),
        out_data(DATA_WIDTH)             => dec_l_quantity_dvalid(I),
        out_data(DATA_WIDTH - 1 downto 0)=> dec_l_quantity((I+1)* 64 - 1 downto I * 64)
      );
    extendedprice_buffer_pu_0: StreamBuffer
      generic map (
      DATA_WIDTH                      => 64 + 2,
      MIN_DEPTH                       => SYNC_OUT_BUFFER_DEPTH -- plus last and dvalid : Maybe later count 
      )
      port map (
        clk                              => kcd_clk,
        reset                            => kcd_reset or reset,
        in_valid                         => extendedprice_valid(I),
        in_ready                         => extendedprice_ready(I),
        in_data(DATA_WIDTH + 1)          => extendedprice_last(I),
        in_data(DATA_WIDTH)              => extendedprice_dvalid(I),
        in_data(DATA_WIDTH - 1 downto 0) => buf_l_extendedprice((I+1)* 64 - 1 downto I * 64),
        out_valid                        => dec_l_extendedprice_valid(I),
        out_ready                        => dec_l_extendedprice_ready(I),
        out_data(DATA_WIDTH + 1)         => dec_l_extendedprice_last(I),
        out_data(DATA_WIDTH)             => dec_l_extendedprice_dvalid(I),
        out_data(DATA_WIDTH - 1 downto 0)=> dec_l_extendedprice((I+1)* 64 - 1 downto I * 64)
      );
    shipdate_buffer_pu_0: StreamBuffer
      generic map (
      DATA_WIDTH                      => 64 + 2,
      MIN_DEPTH                       => SYNC_OUT_BUFFER_DEPTH -- plus last and dvalid : Maybe later count 
      )
      port map (
        clk                              => kcd_clk,
        reset                            => kcd_reset or reset,
        in_valid                         => shipdate_valid(I),
        in_ready                         => shipdate_ready(I),
        in_data(DATA_WIDTH + 1)          => shipdate_last(I),
        in_data(DATA_WIDTH)              => shipdate_dvalid(I),
        in_data(DATA_WIDTH - 1 downto 0) => buf_l_shipdate((I+1)* 64 - 1 downto I * 64),
        out_valid                        => dec_l_shipdate_valid(I),
        out_ready                        => dec_l_shipdate_ready(I),
        out_data(DATA_WIDTH + 1)         => dec_l_shipdate_last(I),
        out_data(DATA_WIDTH)             => dec_l_shipdate_dvalid(I),
        out_data(DATA_WIDTH - 1 downto 0)=> dec_l_shipdate((I+1)* 64 - 1 downto I * 64)
      );
    processing_unit_0: PU
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
        
        l_quantity_valid             => dec_l_quantity_valid(I), 
        l_quantity_ready             => dec_l_quantity_ready(I),
        l_quantity_dvalid            => dec_l_quantity_dvalid(I),
        l_quantity_last              => dec_l_quantity_last(I),
        l_quantity                   => dec_l_quantity((I+1)* 64 - 1 downto I * 64),

        l_extendedprice_valid        => dec_l_extendedprice_valid(I), 
        l_extendedprice_ready        => dec_l_extendedprice_ready(I),
        l_extendedprice_dvalid       => dec_l_extendedprice_dvalid(I),
        l_extendedprice_last         => dec_l_extendedprice_last(I),
        l_extendedprice              => dec_l_extendedprice((I+1)* 64 - 1 downto I * 64),

        l_discount_valid             => dec_l_discount_valid(I), 
        l_discount_ready             => dec_l_discount_ready(I),
        l_discount_dvalid            => dec_l_discount_dvalid(I),
        l_discount_last              => dec_l_discount_last(I),
        l_discount                   => dec_l_discount((I+1)* 64 - 1 downto I * 64),

        l_shipdate_valid             => dec_l_shipdate_valid(I), 
        l_shipdate_ready             => dec_l_shipdate_ready(I),
        l_shipdate_dvalid            => dec_l_shipdate_dvalid(I),
        l_shipdate_last              => dec_l_shipdate_last(I),
        l_shipdate                   => dec_l_shipdate((I+1)* 64 - 1 downto I * 64),

        sum_out_valid                => sum_out_valid_stages(I),
        sum_out_ready                => sum_out_ready_stages(I),
        sum_out_data                 => sum_out_data_stages((I+1)* 64 - 1 downto I * 64)
      );
  -------------------------------------------------------------------------------
  end generate;

  
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

