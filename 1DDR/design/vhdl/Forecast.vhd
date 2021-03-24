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
    rhigh                        : out std_logic_vector(31 downto 0);
    rlow                         : out std_logic_vector(31 downto 0)

);
end entity;

architecture Implementation of Forecast is 

  constant DATA_WIDTH               : integer := 64;
  constant EPC                      : integer := 8;
  constant FIXED_LEFT_INDEX         : integer := 45;
  constant FIXED_RIGHT_INDEX        : integer := FIXED_LEFT_INDEX - (DATA_WIDTH-1);
 
  constant SYNC_IN_BUFFER_DEPTH     : integer := 8;
  constant SYNC_OUT_BUFFER_DEPTH    : integer := 8;

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
  signal result_out_data            : std_logic_vector(DATA_WIDTH - 1 downto 0);

  constant ONES                     : std_logic_vector(EPC - 1 downto 0) := (others => '1');

  component ila_1 
  port(
        clk     : in std_logic;
        probe0  : in std_logic_vector(0 downto 0);
        probe1  : in std_logic_vector(63 downto 0);
        probe2  : in std_logic_vector(1 downto 0);
        probe3  : in std_logic_vector(0 downto 0);
        probe4  : in std_logic_vector(0 downto 0);
        probe5  : in std_logic_vector(63 downto 0);
        probe6  : in std_logic_vector(0 downto 0);
        probe7  : in std_logic_vector(0 downto 0);
        probe8  : in std_logic_vector(0 downto 0);
        probe9  : in std_logic_vector(0 downto 0);
        probe10 : in std_logic_vector(511 downto 0);
        probe11 : in std_logic_vector(0 downto 0);
        probe12 : in std_logic_vector(0 downto 0);
        probe13 : in std_logic_vector(1 downto 0);
        probe14 : in std_logic_vector(511 downto 0);
        probe15 : in std_logic_vector(63 downto 0);
        probe16 : in std_logic_vector(0 downto 0);
        probe17 : in std_logic_vector(2 downto 0);
        probe18 : in std_logic_vector(2 downto 0);
        probe19 : in std_logic_vector(4 downto 0);
        probe20 : in std_logic_vector(4 downto 0);
        probe21 : in std_logic_vector(7 downto 0);
        probe22 : in std_logic_vector(0 downto 0);
        probe23 : in std_logic_vector(2 downto 0);
        probe24 : in std_logic_vector(1 downto 0);
        probe25 : in std_logic_vector(4 downto 0);
        probe26 : in std_logic_vector(0 downto 0);
        probe27 : in std_logic_vector(7 downto 0);
        probe28 : in std_logic_vector(2 downto 0);
        probe29 : in std_logic_vector(1 downto 0);
        probe30 : in std_logic_vector(0 downto 0);
        probe31 : in std_logic_vector(3 downto 0);
        probe32 : in std_logic_vector(3 downto 0);
        probe33 : in std_logic_vector(3 downto 0);
        probe34 : in std_logic_vector(3 downto 0);
        probe35 : in std_logic_vector(0 downto 0);
        probe36 : in std_logic_vector(3 downto 0);
        probe37 : in std_logic_vector(3 downto 0);
        probe38 : in std_logic_vector(4 downto 0);
        probe39 : in std_logic_vector(0 downto 0);
        probe40 : in std_logic_vector(0 downto 0);
        probe41 : in std_logic_vector(0 downto 0);
        probe42 : in std_logic_vector(0 downto 0); 
        probe43 : in std_logic_vector(0 downto 0)
  );
  end component;

begin

   --One-hot encoded char mask.
   --with l_quantity_count(3 downto 0) select pu_mask  <=
   --     "00000001" when "0001",
   --     "00000011" when "0010", 
   --     "00000111" when "0011", 
   --     "00001111" when "0100",
   --     "00011111" when "0101", 
   --     "00111111" when "0110",
   --     "01111111" when "0111",
   --     "11111111" when "1000",
   --     "11111111" when "1001",
   --     "11111111" when "1010", 
   --     "11111111" when "1011", 
   --     "11111111" when "1100",
   --     "11111111" when "1101", 
   --     "11111111" when "1110",
   --     "11111111" when "1111",
   --     "00000000" when others;

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
        out_data(DATA_WIDTH + 1)         => dec_l_discount_last,
        out_data(DATA_WIDTH)             => dec_l_discount_dvalid,
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
        out_data(DATA_WIDTH + 1)         => dec_l_quantity_last,
        out_data(DATA_WIDTH)             => dec_l_quantity_dvalid,
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
        out_data(DATA_WIDTH + 1)         => dec_l_extendedprice_last,
        out_data(DATA_WIDTH)             => dec_l_extendedprice_dvalid,
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
        out_data(DATA_WIDTH + 1)         => dec_l_shipdate_last,
        out_data(DATA_WIDTH)             => dec_l_shipdate_dvalid,
        out_data(DATA_WIDTH - 1 downto 0)=> dec_l_shipdate_0
      );
    processing_unit_0: PU
      generic map (
        FIXED_LEFT_INDEX             => FIXED_LEFT_INDEX,
        FIXED_RIGHT_INDEX            => FIXED_RIGHT_INDEX,
        DATA_WIDTH                   => 64,
        INDEX_WIDTH                  => INDEX_WIDTH,
        CONVERTERS                   => "FLOAT_TO_FIXED" -- TODO: Implement this
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
        l_extendedprice_dvalid       => dec_l_extendedprice_dvalid,
        l_extendedprice_last         => dec_l_extendedprice_last,
        l_extendedprice              => dec_l_extendedprice_0,

        l_discount_valid             => dec_l_discount_valid(0), 
        l_discount_ready             => dec_l_discount_ready(0),
        l_discount_dvalid            => dec_l_discount_dvalid,
        l_discount_last              => dec_l_discount_last,
        l_discount                   => dec_l_discount_0,

        l_shipdate_valid             => dec_l_shipdate_valid(0), 
        l_shipdate_ready             => dec_l_shipdate_ready(0),
        l_shipdate_dvalid            => dec_l_shipdate_dvalid,
        l_shipdate_last              => dec_l_shipdate_last,
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
        out_data(DATA_WIDTH + 1)         => dec_l_discount_last,
        out_data(DATA_WIDTH)             => dec_l_discount_dvalid,
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
        out_data(DATA_WIDTH + 1)         => dec_l_quantity_last,
        out_data(DATA_WIDTH)             => dec_l_quantity_dvalid,
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
        out_data(DATA_WIDTH + 1)         => dec_l_extendedprice_last,
        out_data(DATA_WIDTH)             => dec_l_extendedprice_dvalid,
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
        out_data(DATA_WIDTH + 1)         => dec_l_shipdate_last,
        out_data(DATA_WIDTH)             => dec_l_shipdate_dvalid,
        out_data(DATA_WIDTH - 1 downto 0)=> dec_l_shipdate_1
      );
    processing_unit_1: PU
      generic map (
        FIXED_LEFT_INDEX             => FIXED_LEFT_INDEX,
        FIXED_RIGHT_INDEX            => FIXED_RIGHT_INDEX,
        DATA_WIDTH                   => 64,
        INDEX_WIDTH                  => INDEX_WIDTH,
        CONVERTERS                   => "FLOAT_TO_FIXED" -- TODO: Implement this
      )
      port map (
        clk                          => kcd_clk,
        reset                        => kcd_reset or reset,
        
        l_quantity_valid             => dec_l_quantity_valid(1), 
        l_quantity_ready             => dec_l_quantity_ready(1),
        l_quantity_dvalid            => dec_l_quantity_dvalid,
        l_quantity_last              => dec_l_quantity_last,
        l_quantity                   => dec_l_quantity_1,

        l_extendedprice_valid        => dec_l_extendedprice_valid(1), 
        l_extendedprice_ready        => dec_l_extendedprice_ready(1),
        l_extendedprice_dvalid       => dec_l_extendedprice_dvalid,
        l_extendedprice_last         => dec_l_extendedprice_last,
        l_extendedprice              => dec_l_extendedprice_1,

        l_discount_valid             => dec_l_discount_valid(1), 
        l_discount_ready             => dec_l_discount_ready(1),
        l_discount_dvalid            => dec_l_discount_dvalid,
        l_discount_last              => dec_l_discount_last,
        l_discount                   => dec_l_discount_1,

        l_shipdate_valid             => dec_l_shipdate_valid(1), 
        l_shipdate_ready             => dec_l_shipdate_ready(1),
        l_shipdate_dvalid            => dec_l_shipdate_dvalid,
        l_shipdate_last              => dec_l_shipdate_last,
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
        out_data(DATA_WIDTH + 1)         => dec_l_discount_last,
        out_data(DATA_WIDTH)             => dec_l_discount_dvalid,
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
        out_data(DATA_WIDTH + 1)         => dec_l_quantity_last,
        out_data(DATA_WIDTH)             => dec_l_quantity_dvalid,
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
        out_data(DATA_WIDTH + 1)         => dec_l_extendedprice_last,
        out_data(DATA_WIDTH)             => dec_l_extendedprice_dvalid,
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
        out_data(DATA_WIDTH + 1)         => dec_l_shipdate_last,
        out_data(DATA_WIDTH)             => dec_l_shipdate_dvalid,
        out_data(DATA_WIDTH - 1 downto 0)=> dec_l_shipdate_2
      );
    processing_unit_2: PU
      generic map (
        FIXED_LEFT_INDEX             => FIXED_LEFT_INDEX,
        FIXED_RIGHT_INDEX            => FIXED_RIGHT_INDEX,
        DATA_WIDTH                   => 64,
        INDEX_WIDTH                  => INDEX_WIDTH,
        CONVERTERS                   => "FLOAT_TO_FIXED" -- TODO: Implement this
      )
      port map (
        clk                          => kcd_clk,
        reset                        => kcd_reset or reset,
        
        l_quantity_valid             => dec_l_quantity_valid(2), 
        l_quantity_ready             => dec_l_quantity_ready(2),
        l_quantity_dvalid            => dec_l_quantity_dvalid,
        l_quantity_last              => dec_l_quantity_last,
        l_quantity                   => dec_l_quantity_2,

        l_extendedprice_valid        => dec_l_extendedprice_valid(2), 
        l_extendedprice_ready        => dec_l_extendedprice_ready(2),
        l_extendedprice_dvalid       => dec_l_extendedprice_dvalid,
        l_extendedprice_last         => dec_l_extendedprice_last,
        l_extendedprice              => dec_l_extendedprice_2,

        l_discount_valid             => dec_l_discount_valid(2), 
        l_discount_ready             => dec_l_discount_ready(2),
        l_discount_dvalid            => dec_l_discount_dvalid,
        l_discount_last              => dec_l_discount_last,
        l_discount                   => dec_l_discount_2,

        l_shipdate_valid             => dec_l_shipdate_valid(2), 
        l_shipdate_ready             => dec_l_shipdate_ready(2),
        l_shipdate_dvalid            => dec_l_shipdate_dvalid,
        l_shipdate_last              => dec_l_shipdate_last,
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
        out_data(DATA_WIDTH + 1)         => dec_l_discount_last,
        out_data(DATA_WIDTH)             => dec_l_discount_dvalid,
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
        out_data(DATA_WIDTH + 1)         => dec_l_quantity_last,
        out_data(DATA_WIDTH)             => dec_l_quantity_dvalid,
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
        out_data(DATA_WIDTH + 1)         => dec_l_extendedprice_last,
        out_data(DATA_WIDTH)             => dec_l_extendedprice_dvalid,
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
        out_data(DATA_WIDTH + 1)         => dec_l_shipdate_last,
        out_data(DATA_WIDTH)             => dec_l_shipdate_dvalid,
        out_data(DATA_WIDTH - 1 downto 0)=> dec_l_shipdate_3
      );
    processing_unit_3: PU
      generic map (
        FIXED_LEFT_INDEX             => FIXED_LEFT_INDEX,
        FIXED_RIGHT_INDEX            => FIXED_RIGHT_INDEX,
        DATA_WIDTH                   => 64,
        INDEX_WIDTH                  => INDEX_WIDTH,
        CONVERTERS                   => "FLOAT_TO_FIXED" -- TODO: Implement this
      )
      port map (
        clk                          => kcd_clk,
        reset                        => kcd_reset or reset,
        
        l_quantity_valid             => dec_l_quantity_valid(3), 
        l_quantity_ready             => dec_l_quantity_ready(3),
        l_quantity_dvalid            => dec_l_quantity_dvalid,
        l_quantity_last              => dec_l_quantity_last,
        l_quantity                   => dec_l_quantity_3,

        l_extendedprice_valid        => dec_l_extendedprice_valid(3), 
        l_extendedprice_ready        => dec_l_extendedprice_ready(3),
        l_extendedprice_dvalid       => dec_l_extendedprice_dvalid,
        l_extendedprice_last         => dec_l_extendedprice_last,
        l_extendedprice              => dec_l_extendedprice_3,

        l_discount_valid             => dec_l_discount_valid(3), 
        l_discount_ready             => dec_l_discount_ready(3),
        l_discount_dvalid            => dec_l_discount_dvalid,
        l_discount_last              => dec_l_discount_last,
        l_discount                   => dec_l_discount_3,

        l_shipdate_valid             => dec_l_shipdate_valid(3), 
        l_shipdate_ready             => dec_l_shipdate_ready(3),
        l_shipdate_dvalid            => dec_l_shipdate_dvalid,
        l_shipdate_last              => dec_l_shipdate_last,
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
        out_data(DATA_WIDTH + 1)         => dec_l_discount_last,
        out_data(DATA_WIDTH)             => dec_l_discount_dvalid,
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
        out_data(DATA_WIDTH + 1)         => dec_l_quantity_last,
        out_data(DATA_WIDTH)             => dec_l_quantity_dvalid,
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
        out_data(DATA_WIDTH + 1)         => dec_l_extendedprice_last,
        out_data(DATA_WIDTH)             => dec_l_extendedprice_dvalid,
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
        out_data(DATA_WIDTH + 1)         => dec_l_shipdate_last,
        out_data(DATA_WIDTH)             => dec_l_shipdate_dvalid,
        out_data(DATA_WIDTH - 1 downto 0)=> dec_l_shipdate_4
      );
    processing_unit_4: PU
      generic map (
        FIXED_LEFT_INDEX             => FIXED_LEFT_INDEX,
        FIXED_RIGHT_INDEX            => FIXED_RIGHT_INDEX,
        DATA_WIDTH                   => 64,
        INDEX_WIDTH                  => INDEX_WIDTH,
        CONVERTERS                   => "FLOAT_TO_FIXED" -- TODO: Implement this
      )
      port map (
        clk                          => kcd_clk,
        reset                        => kcd_reset or reset,
        
        l_quantity_valid             => dec_l_quantity_valid(4), 
        l_quantity_ready             => dec_l_quantity_ready(4),
        l_quantity_dvalid            => dec_l_quantity_dvalid,
        l_quantity_last              => dec_l_quantity_last,
        l_quantity                   => dec_l_quantity_4,

        l_extendedprice_valid        => dec_l_extendedprice_valid(4), 
        l_extendedprice_ready        => dec_l_extendedprice_ready(4),
        l_extendedprice_dvalid       => dec_l_extendedprice_dvalid,
        l_extendedprice_last         => dec_l_extendedprice_last,
        l_extendedprice              => dec_l_extendedprice_4,

        l_discount_valid             => dec_l_discount_valid(4), 
        l_discount_ready             => dec_l_discount_ready(4),
        l_discount_dvalid            => dec_l_discount_dvalid,
        l_discount_last              => dec_l_discount_last,
        l_discount                   => dec_l_discount_4,

        l_shipdate_valid             => dec_l_shipdate_valid(4), 
        l_shipdate_ready             => dec_l_shipdate_ready(4),
        l_shipdate_dvalid            => dec_l_shipdate_dvalid,
        l_shipdate_last              => dec_l_shipdate_last,
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
        out_data(DATA_WIDTH + 1)         => dec_l_discount_last,
        out_data(DATA_WIDTH)             => dec_l_discount_dvalid,
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
        out_data(DATA_WIDTH + 1)         => dec_l_quantity_last,
        out_data(DATA_WIDTH)             => dec_l_quantity_dvalid,
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
        out_data(DATA_WIDTH + 1)         => dec_l_extendedprice_last,
        out_data(DATA_WIDTH)             => dec_l_extendedprice_dvalid,
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
        out_data(DATA_WIDTH + 1)         => dec_l_shipdate_last,
        out_data(DATA_WIDTH)             => dec_l_shipdate_dvalid,
        out_data(DATA_WIDTH - 1 downto 0)=> dec_l_shipdate_5
      );
    processing_unit_5: PU
      generic map (
        FIXED_LEFT_INDEX             => FIXED_LEFT_INDEX,
        FIXED_RIGHT_INDEX            => FIXED_RIGHT_INDEX,
        DATA_WIDTH                   => 64,
        INDEX_WIDTH                  => INDEX_WIDTH,
        CONVERTERS                   => "FLOAT_TO_FIXED" -- TODO: Implement this
      )
      port map (
        clk                          => kcd_clk,
        reset                        => kcd_reset or reset,
        
        l_quantity_valid             => dec_l_quantity_valid(5), 
        l_quantity_ready             => dec_l_quantity_ready(5),
        l_quantity_dvalid            => dec_l_quantity_dvalid,
        l_quantity_last              => dec_l_quantity_last,
        l_quantity                   => dec_l_quantity_5,

        l_extendedprice_valid        => dec_l_extendedprice_valid(5), 
        l_extendedprice_ready        => dec_l_extendedprice_ready(5),
        l_extendedprice_dvalid       => dec_l_extendedprice_dvalid,
        l_extendedprice_last         => dec_l_extendedprice_last,
        l_extendedprice              => dec_l_extendedprice_5,

        l_discount_valid             => dec_l_discount_valid(5), 
        l_discount_ready             => dec_l_discount_ready(5),
        l_discount_dvalid            => dec_l_discount_dvalid,
        l_discount_last              => dec_l_discount_last,
        l_discount                   => dec_l_discount_5,

        l_shipdate_valid             => dec_l_shipdate_valid(5), 
        l_shipdate_ready             => dec_l_shipdate_ready(5),
        l_shipdate_dvalid            => dec_l_shipdate_dvalid,
        l_shipdate_last              => dec_l_shipdate_last,
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
        out_data(DATA_WIDTH + 1)         => dec_l_discount_last,
        out_data(DATA_WIDTH)             => dec_l_discount_dvalid,
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
        out_data(DATA_WIDTH + 1)         => dec_l_quantity_last,
        out_data(DATA_WIDTH)             => dec_l_quantity_dvalid,
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
        out_data(DATA_WIDTH + 1)         => dec_l_extendedprice_last,
        out_data(DATA_WIDTH)             => dec_l_extendedprice_dvalid,
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
        out_data(DATA_WIDTH + 1)         => dec_l_shipdate_last,
        out_data(DATA_WIDTH)             => dec_l_shipdate_dvalid,
        out_data(DATA_WIDTH - 1 downto 0)=> dec_l_shipdate_6
      );
    processing_unit_6: PU
      generic map (
        FIXED_LEFT_INDEX             => FIXED_LEFT_INDEX,
        FIXED_RIGHT_INDEX            => FIXED_RIGHT_INDEX,
        DATA_WIDTH                   => 64,
        INDEX_WIDTH                  => INDEX_WIDTH,
        CONVERTERS                   => "FLOAT_TO_FIXED" -- TODO: Implement this
      )
      port map (
        clk                          => kcd_clk,
        reset                        => kcd_reset or reset,
        
        l_quantity_valid             => dec_l_quantity_valid(6), 
        l_quantity_ready             => dec_l_quantity_ready(6),
        l_quantity_dvalid            => dec_l_quantity_dvalid,
        l_quantity_last              => dec_l_quantity_last,
        l_quantity                   => dec_l_quantity_6,

        l_extendedprice_valid        => dec_l_extendedprice_valid(6), 
        l_extendedprice_ready        => dec_l_extendedprice_ready(6),
        l_extendedprice_dvalid       => dec_l_extendedprice_dvalid,
        l_extendedprice_last         => dec_l_extendedprice_last,
        l_extendedprice              => dec_l_extendedprice_6,

        l_discount_valid             => dec_l_discount_valid(6), 
        l_discount_ready             => dec_l_discount_ready(6),
        l_discount_dvalid            => dec_l_discount_dvalid,
        l_discount_last              => dec_l_discount_last,
        l_discount                   => dec_l_discount_6,

        l_shipdate_valid             => dec_l_shipdate_valid(6), 
        l_shipdate_ready             => dec_l_shipdate_ready(6),
        l_shipdate_dvalid            => dec_l_shipdate_dvalid,
        l_shipdate_last              => dec_l_shipdate_last,
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
        out_data(DATA_WIDTH + 1)         => dec_l_discount_last,
        out_data(DATA_WIDTH)             => dec_l_discount_dvalid,
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
        out_data(DATA_WIDTH + 1)         => dec_l_quantity_last,
        out_data(DATA_WIDTH)             => dec_l_quantity_dvalid,
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
        out_data(DATA_WIDTH + 1)         => dec_l_extendedprice_last,
        out_data(DATA_WIDTH)             => dec_l_extendedprice_dvalid,
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
        out_data(DATA_WIDTH + 1)         => dec_l_shipdate_last,
        out_data(DATA_WIDTH)             => dec_l_shipdate_dvalid,
        out_data(DATA_WIDTH - 1 downto 0)=> dec_l_shipdate_7
      );
    processing_unit_7: PU
      generic map (
        FIXED_LEFT_INDEX             => FIXED_LEFT_INDEX,
        FIXED_RIGHT_INDEX            => FIXED_RIGHT_INDEX,
        DATA_WIDTH                   => 64,
        INDEX_WIDTH                  => INDEX_WIDTH,
        CONVERTERS                   => "FLOAT_TO_FIXED" -- TODO: Implement this
      )
      port map (
        clk                          => kcd_clk,
        reset                        => kcd_reset or reset,
        
        l_quantity_valid             => dec_l_quantity_valid(7), 
        l_quantity_ready             => dec_l_quantity_ready(7),
        l_quantity_dvalid            => dec_l_quantity_dvalid,
        l_quantity_last              => dec_l_quantity_last,
        l_quantity                   => dec_l_quantity_7,

        l_extendedprice_valid        => dec_l_extendedprice_valid(7), 
        l_extendedprice_ready        => dec_l_extendedprice_ready(7),
        l_extendedprice_dvalid       => dec_l_extendedprice_dvalid,
        l_extendedprice_last         => dec_l_extendedprice_last,
        l_extendedprice              => dec_l_extendedprice_7,

        l_discount_valid             => dec_l_discount_valid(7), 
        l_discount_ready             => dec_l_discount_ready(7),
        l_discount_dvalid            => dec_l_discount_dvalid,
        l_discount_last              => dec_l_discount_last,
        l_discount                   => dec_l_discount_7,

        l_shipdate_valid             => dec_l_shipdate_valid(7), 
        l_shipdate_ready             => dec_l_shipdate_ready(7),
        l_shipdate_dvalid            => dec_l_shipdate_dvalid,
        l_shipdate_last              => dec_l_shipdate_last,
        l_shipdate                   => dec_l_shipdate_7,

        sum_out_valid                => sum_out_valid_stages(7),
        sum_out_ready                => sum_out_ready_stages(7),
        sum_out_data                 => sum_out_data_stages((7+1)* 64 - 1 downto 7 * 64)
      );
-------------------------------------------------------------------------------


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
      variable temp_inp_1         : sfixed(FIXED_LEFT_INDEX downto FIXED_RIGHT_INDEX);
      variable temp_inp_2         : sfixed(FIXED_LEFT_INDEX downto FIXED_RIGHT_INDEX);
      variable temp_inp_3         : sfixed(FIXED_LEFT_INDEX downto FIXED_RIGHT_INDEX);
      variable temp_inp_4         : sfixed(FIXED_LEFT_INDEX downto FIXED_RIGHT_INDEX);
      variable temp_inp_5         : sfixed(FIXED_LEFT_INDEX downto FIXED_RIGHT_INDEX);
      variable temp_inp_6         : sfixed(FIXED_LEFT_INDEX downto FIXED_RIGHT_INDEX);
      variable temp_inp_7         : sfixed(FIXED_LEFT_INDEX downto FIXED_RIGHT_INDEX);
      variable temp_inp_8         : sfixed(FIXED_LEFT_INDEX downto FIXED_RIGHT_INDEX);
      variable temp_acc           : sfixed(FIXED_LEFT_INDEX + (EPC - 1) downto FIXED_RIGHT_INDEX);
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
          temp_inp_1 := to_sfixed(sum_out_data_stages(DATA_WIDTH - 1 downto 0), FIXED_LEFT_INDEX, FIXED_RIGHT_INDEX);
          temp_inp_2 := to_sfixed(sum_out_data_stages(2*DATA_WIDTH - 1 downto DATA_WIDTH), FIXED_LEFT_INDEX, FIXED_RIGHT_INDEX);
          temp_inp_3 := to_sfixed(sum_out_data_stages(3*DATA_WIDTH - 1 downto 2 * DATA_WIDTH), FIXED_LEFT_INDEX, FIXED_RIGHT_INDEX);
          temp_inp_4 := to_sfixed(sum_out_data_stages(4*DATA_WIDTH - 1 downto 3 * DATA_WIDTH), FIXED_LEFT_INDEX, FIXED_RIGHT_INDEX);
          temp_inp_5 := to_sfixed(sum_out_data_stages(5*DATA_WIDTH - 1 downto 4 * DATA_WIDTH), FIXED_LEFT_INDEX, FIXED_RIGHT_INDEX);
          temp_inp_6 := to_sfixed(sum_out_data_stages(6*DATA_WIDTH - 1 downto 5 * DATA_WIDTH), FIXED_LEFT_INDEX, FIXED_RIGHT_INDEX);
          temp_inp_7 := to_sfixed(sum_out_data_stages(7*DATA_WIDTH - 1 downto 6 * DATA_WIDTH), FIXED_LEFT_INDEX, FIXED_RIGHT_INDEX);
          temp_inp_8 := to_sfixed(sum_out_data_stages(8*DATA_WIDTH - 1 downto 7 * DATA_WIDTH), FIXED_LEFT_INDEX, FIXED_RIGHT_INDEX);

          temp_acc := temp_inp_1 + temp_inp_2 + temp_inp_3 + temp_inp_4 + temp_inp_5 + temp_inp_6 + temp_inp_7 + temp_inp_8;
          result_out_data <= to_slv(resize( arg => temp_acc,left_index => FIXED_LEFT_INDEX, right_index => FIXED_RIGHT_INDEX, round_style => fixed_round_style, overflow_style => fixed_overflow_style));

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
  begin
    -- On the rising edge of the kernel clock:
    if rising_edge(kcd_clk) then
      -- Register the next state.
      state <= state_next;        

      if state = STATE_DONE then
        result <= result_out_data;
        rhigh <= result_out_data(63 downto 32);
        rlow <= result_out_data(31 downto 0);
      else
        result <= (63 downto state_slv'length => '0') & state_slv;
      end if;

      if kcd_reset = '1' or reset = '1' then
        state <= STATE_IDLE;
        result <= (others => '0');
      end if;
    end if;
  end process;

end architecture;

