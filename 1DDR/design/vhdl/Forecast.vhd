-- This source code is initialized by Yuksel Yonsel
-- rev 0.1 
-- Author: Yuksel Yonsel
-- The Hash join op. to be implemented
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

library work;
use work.Forecast_pkg.all;
use work.Stream_pkg.all;
use work.ParallelPatterns_pkg.all;

entity Forecast is
  generic (
    INDEX_WIDTH : integer := 32;
    TAG_WIDTH   : integer := 1
  );
  port (
    kcd_clk                          : in  std_logic;
    kcd_reset                        : in  std_logic;

    -- Column: quantity int64
    l_quantity_valid        : in  std_logic;
    l_quantity_ready        : out std_logic;
    l_quantity_dvalid       : in  std_logic;
    l_quantity_last         : in  std_logic;
    l_quantity              : in  std_logic_vector(63 downto 0);
    l_quantity_unl_valid    : in  std_logic;
    l_quantity_unl_ready    : out std_logic;
    l_quantity_unl_tag      : in  std_logic_vector(TAG_WIDTH-1 downto 0);
    l_quantity_cmd_valid    : out std_logic;
    l_quantity_cmd_ready    : in  std_logic;
    l_quantity_cmd_firstIdx : out std_logic_vector(INDEX_WIDTH-1 downto 0);
    l_quantity_cmd_lastIdx  : out std_logic_vector(INDEX_WIDTH-1 downto 0);
    l_quantity_cmd_tag      : out std_logic_vector(TAG_WIDTH-1 downto 0);

    -- Column: extendedprice int64
    l_extendedprice_valid        : in  std_logic;
    l_extendedprice_ready        : out std_logic;
    l_extendedprice_dvalid       : in  std_logic;
    l_extendedprice_last         : in  std_logic;
    l_extendedprice              : in  std_logic_vector(63 downto 0);
    l_extendedprice_unl_valid    : in  std_logic;
    l_extendedprice_unl_ready    : out std_logic;
    l_extendedprice_unl_tag      : in  std_logic_vector(TAG_WIDTH-1 downto 0);
    l_extendedprice_cmd_valid    : out std_logic;
    l_extendedprice_cmd_ready    : in  std_logic;
    l_extendedprice_cmd_firstIdx : out std_logic_vector(INDEX_WIDTH-1 downto 0);
    l_extendedprice_cmd_lastIdx  : out std_logic_vector(INDEX_WIDTH-1 downto 0);
    l_extendedprice_cmd_tag      : out std_logic_vector(TAG_WIDTH-1 downto 0);

    -- Column: discount int64
    l_discount_valid        : in  std_logic;
    l_discount_ready        : out std_logic;
    l_discount_dvalid       : in  std_logic;
    l_discount_last         : in  std_logic;
    l_discount              : in  std_logic_vector(63 downto 0);
    l_discount_unl_valid    : in  std_logic;
    l_discount_unl_ready    : out std_logic;
    l_discount_unl_tag      : in  std_logic_vector(TAG_WIDTH-1 downto 0);
    l_discount_cmd_valid    : out std_logic;
    l_discount_cmd_ready    : in  std_logic;
    l_discount_cmd_firstIdx : out std_logic_vector(INDEX_WIDTH-1 downto 0);
    l_discount_cmd_lastIdx  : out std_logic_vector(INDEX_WIDTH-1 downto 0);
    l_discount_cmd_tag      : out std_logic_vector(TAG_WIDTH-1 downto 0);

    -- Column: shipdate int64
    l_shipdate_valid        : in  std_logic;
    l_shipdate_ready        : out std_logic;
    l_shipdate_dvalid       : in  std_logic;
    l_shipdate_last         : in  std_logic;
    l_shipdate              : in  std_logic_vector(63 downto 0);
    l_shipdate_unl_valid    : in  std_logic;
    l_shipdate_unl_ready    : out std_logic;
    l_shipdate_unl_tag      : in  std_logic_vector(TAG_WIDTH-1 downto 0);
    l_shipdate_cmd_valid    : out std_logic;
    l_shipdate_cmd_ready    : in  std_logic;
    l_shipdate_cmd_firstIdx : out std_logic_vector(INDEX_WIDTH-1 downto 0);
    l_shipdate_cmd_lastIdx  : out std_logic_vector(INDEX_WIDTH-1 downto 0);
    l_shipdate_cmd_tag      : out std_logic_vector(TAG_WIDTH-1 downto 0);

    start                            : in  std_logic;
    stop                             : in  std_logic;
    reset                            : in  std_logic;
    idle                             : out std_logic;
    busy                             : out std_logic;
    done                             : out std_logic;
    result                           : out std_logic_vector(63 downto 0);
    l_firstidx                      : in  std_logic_vector(31 downto 0);
    l_lastidx                       : in  std_logic_vector(31 downto 0)

);
end entity;

architecture Implementation of Forecast is 
  constant DATA_WIDTH                  : integer := 64;
  constant FIXED_LEFT_INDEX            : integer := 45;
  constant FIXED_RIGHT_INDEX           : integer := FIXED_LEFT_INDEX - (DATA_WIDTH-1);
  
  -- Enumeration type for our state machine.
  type state_t is (STATE_IDLE, 
                   STATE_COMMAND, 
                   STATE_CALCULATING, 
                   STATE_UNLOCK, 
                   STATE_DONE);
                   
  signal state_slv : std_logic_vector(2 downto 0);


  
  -- Current state register and next state signal.
  signal state, state_next : state_t;

  -- Input filter stream 
  signal filter_in_ready        : std_logic;

  -- Output of filter stage
  signal filter_out_valid       : std_logic;
  signal filter_out_ready       : std_logic;
  signal filter_out_last        : std_logic;
  signal filter_out_strb        : std_logic;
  -- signal filter_out_strb        : std_logic;

  -- Sum output stream.
  signal sum_out_valid          : std_logic;
  signal sum_out_ready          : std_logic;
  signal sum_out_data           : std_logic_vector(63 downto 0);

  -- Sync inputs 
  signal sync_1_valid          : std_logic;
  signal sync_1_ready          : std_logic;
  signal sync_1_data           : std_logic;
  signal sync_2_valid          : std_logic;
  signal sync_2_ready          : std_logic;
  signal sync_2_data           : std_logic;
  signal sync_3_valid          : std_logic;
  signal sync_3_ready          : std_logic;
  signal sync_3_data           : std_logic;

-- Outputs of operators
  signal lessthan_out_ready          : std_logic;
  signal lessthan_out_valid           : std_logic;
  signal lessthan_out_data           : std_logic_vector(63 downto 0);

  signal between_out_ready          : std_logic;
  signal between_out_valid           : std_logic;
  signal between_out_data           : std_logic_vector(63 downto 0);

  signal date_engine_out_ready          : std_logic;
  signal date_engine_out_valid           : std_logic;
  signal date_engine_out_data           : std_logic_vector(63 downto 0);
--
  signal reduce_in_ready          : std_logic;
  signal reduce_in_valid           : std_logic;
  signal reduce_in_last            : std_logic;
  signal reduce_in_dvalid           : std_logic;
  signal reduce_in_data           : std_logic_vector(63 downto 0);

  signal between_in_valid          : std_logic;
  signal between_in_ready          : std_logic;

  signal merge_discount_in_valid          : std_logic;
  signal merge_discount_in_ready          : std_logic;

  signal out_predicate     : std_logic;

begin
  discount_sync: StreamSync
    generic map (
      NUM_INPUTS                => 1,
      NUM_OUTPUTS               => 2
    )
    port map (
      clk                       => kcd_clk,
      reset                     => kcd_reset or reset,

      in_valid(0)               => l_discount_valid,
      in_ready(0)               => l_discount_ready,


      out_valid(0)              => between_in_valid,
      out_valid(1)              => merge_discount_in_valid,
      out_ready(0)              => between_in_ready,
      out_ready(1)              => merge_discount_in_ready
    );

  lessthan: ALU
    generic map(
      FIXED_LEFT_INDEX          => FIXED_LEFT_INDEX,
      FIXED_RIGHT_INDEX         => FIXED_RIGHT_INDEX,
      DATA_WIDTH                => DATA_WIDTH,
      ALUTYPE                   => "LESSTHAN"
    )
    port map (
      clk                       => kcd_clk,
      reset                     => kcd_reset or reset,

      in_valid                  => l_quantity_valid,
      in_dvalid                 => l_quantity_dvalid,
      in_ready                  => l_quantity_ready,
      in_last                   => l_quantity_last,
      in_data                   => l_quantity,
      
      out_valid                 => lessthan_out_valid,
      out_ready                 => lessthan_out_ready,
      out_data                  => lessthan_out_data
    );
  between: ALU
    generic map(
      FIXED_LEFT_INDEX          => FIXED_LEFT_INDEX,
      FIXED_RIGHT_INDEX         => FIXED_RIGHT_INDEX,
      DATA_WIDTH                => DATA_WIDTH,
      ALUTYPE                   => "BETWEEN"
    )
    port map (
      clk                       => kcd_clk,
      reset                     => kcd_reset or reset,

      in_valid                  => between_in_valid,
      in_dvalid                 => l_discount_dvalid,
      in_ready                  => between_in_ready,
      in_last                   => l_discount_last,
      in_data                   => l_discount,
      
      out_valid                 => between_out_valid,
      out_ready                 => between_out_ready,
      out_data                  => between_out_data
    );
  compare: ALU
    generic map(
      FIXED_LEFT_INDEX          => FIXED_LEFT_INDEX,
      FIXED_RIGHT_INDEX         => FIXED_RIGHT_INDEX,
      DATA_WIDTH                => DATA_WIDTH,
      ALUTYPE                   => "DATE"
    )
    port map (
      clk                       => kcd_clk,
      reset                     => kcd_reset or reset,

      in_valid                  => l_shipdate_valid,
      in_dvalid                 => l_shipdate_dvalid,
      in_ready                  => l_shipdate_ready,
      in_last                   => l_shipdate_last,
      in_data                   => l_shipdate,
      
      out_valid                 => date_engine_out_valid,
      out_ready                 => date_engine_out_ready,
      out_data                  => date_engine_out_data
    );
  matcher_out_buffer_lessthan: StreamBuffer
    generic map (
     DATA_WIDTH                => 1,
     MIN_DEPTH                 => 64
    )
    port map (
      clk                               => kcd_clk,
      reset                             => kcd_reset or reset,
      in_valid                          => lessthan_out_valid,
      in_ready                          => lessthan_out_ready,
      in_data(0)                        => lessthan_out_data(0),
      out_valid                         => sync_1_valid,
      out_ready                         => sync_1_ready,
      out_data(0)                       => sync_1_data
    );
  matcher_out_buffer_between: StreamBuffer
    generic map (
     DATA_WIDTH                => 1,
     MIN_DEPTH                 => 64
    )
    port map (
      clk                               => kcd_clk,
      reset                             => kcd_reset or reset,
      in_valid                          => between_out_valid,
      in_ready                          => between_out_ready,
      in_data(0)                        => between_out_data(0),
      out_valid                         => sync_2_valid,
      out_ready                         => sync_2_ready,
      out_data(0)                       => sync_2_data
    );
  matcher_out_buffer_date: StreamBuffer
    generic map (
     DATA_WIDTH                => 1,
     MIN_DEPTH                 => 64
    )
    port map (
      clk                               => kcd_clk,
      reset                             => kcd_reset or reset,
      in_valid                          => date_engine_out_valid,
      in_ready                          => date_engine_out_ready,
      in_data(0)                        => date_engine_out_data(0),
      out_valid                         => sync_3_valid,
      out_ready                         => sync_3_ready,
      out_data(0)                       => sync_3_data
    );
  merge_predicate: MergeOp
   generic map (
     FIXED_LEFT_INDEX          => FIXED_LEFT_INDEX,
     FIXED_RIGHT_INDEX         => FIXED_RIGHT_INDEX,
     DATA_WIDTH                 => 64,
     MIN_DEPTH                  => 32,
     DATA_TYPE                  => "FLOAT64"
   )
   port map (
     clk                       => kcd_clk,
     reset                     => kcd_reset or reset,
     
     op1_valid                 => merge_discount_in_valid,
     op1_last                  => l_discount_last,
     op1_ready                 => merge_discount_in_ready,
     op1_dvalid                => l_discount_dvalid,
     op1_data                  => l_discount,
     
     op2_valid                 => l_extendedprice_valid,
     op2_last                  => l_extendedprice_last,
     op2_ready                 => l_extendedprice_ready,
     op2_dvalid                => l_extendedprice_dvalid,
     op2_data                  => l_extendedprice,
     
     out_valid                 => reduce_in_valid,
     out_last                  => reduce_in_last,
     out_ready                 => reduce_in_ready,
     out_data                  => reduce_in_data,
     out_dvalid                => reduce_in_dvalid
    );
    

  filter_in_sync: StreamSync
    generic map (
      NUM_INPUTS                => 4,
      NUM_OUTPUTS               => 1
    )
    port map (
      clk                       => kcd_clk,
      reset                     => kcd_reset or reset,

      in_valid(0)               => sync_1_valid,
      in_valid(1)               => sync_2_valid,
      in_valid(2)               => sync_3_valid,
      in_valid(3)               => reduce_in_valid,
      in_ready(0)               => sync_1_ready,
      in_ready(1)               => sync_2_ready,
      in_ready(2)               => sync_3_ready,
      in_ready(3)               => reduce_in_ready,


      out_valid(0)              => filter_out_valid,
      out_ready(0)              => filter_out_ready
    );

  --filter_stage: FilterStream
  --generic map(
  --  LANE_COUNT                  => 3,
  --  INDEX_WIDTH                 => INDEX_WIDTH-1,
  --  DIMENSIONALITY              => 1,
  --  MIN_BUFFER_DEPTH            => 16
  --)
  --port map(
  --  
  --  clk                         => kcd_clk,
  --  reset                       => kcd_reset or reset,
  --  in_valid                    => reduce_in_valid,
  --  in_ready                    => reduce_in_ready,
  --  in_last(0)                  => reduce_in_last,
  --                              
  --  pred_in_valid               => matcher_out_s_valid,
  --  pred_in_ready               => matcher_out_s_ready,
  --  pred_in_data(0)             => sync_1_data,
  --  pred_in_data(1)             => sync_2_data,
  --  pred_in_data(2)             => sync_3_data,
  --                              
  --  out_valid                   => filter_out_valid,
  --  out_ready                   => filter_out_ready,
  --  out_strb                    => filter_out_strb,
  --  out_last(0)                 => filter_out_last
  --);

  -- filter_out_valid <= matcher_out_s_valid;
  -- filter_out_ready <= matcher_out_s_ready;
  filter_out_strb <= sync_1_data and sync_2_data and sync_3_data;
  filter_out_last <= reduce_in_last;

  reduce_stage: ReduceStage
  generic map (
      FIXED_LEFT_INDEX          => FIXED_LEFT_INDEX,
      FIXED_RIGHT_INDEX         => FIXED_RIGHT_INDEX,
      INDEX_WIDTH => INDEX_WIDTH-1
    )
  port map (
    clk                       => kcd_clk,
    reset                     => kcd_reset or reset,
    in_valid                  => filter_out_valid,
    in_ready                  => filter_out_ready,
    in_dvalid                 => filter_out_strb,
    in_last                   => filter_out_last,
    in_data                   => reduce_in_data,
    out_valid                 => sum_out_valid,
    out_ready                 => sum_out_ready,
    out_data                  => sum_out_data
  );


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

        sum_out_valid,

        state,
        start,
        reset,
        kcd_reset
    ) is 
  begin

    l_quantity_cmd_valid       <= '0';
    l_quantity_cmd_firstIdx    <= (others => '0');
    l_quantity_cmd_lastIdx     <= (others => '0');
    l_quantity_cmd_tag         <= (others => '0');
    
    l_quantity_unl_ready       <= '0'; -- Do not accept "unlocks".

    l_discount_cmd_valid       <= '0';
    l_discount_cmd_firstIdx    <= (others => '0');
    l_discount_cmd_lastIdx     <= (others => '0');
    l_discount_cmd_tag         <= (others => '0');
    
    l_discount_unl_ready       <= '0'; -- Do not accept "unlocks".

    l_shipdate_cmd_valid       <= '0';
    l_shipdate_cmd_firstIdx    <= (others => '0');
    l_shipdate_cmd_lastIdx     <= (others => '0');
    l_shipdate_cmd_tag         <= (others => '0');
    
    l_shipdate_unl_ready       <= '0'; -- Do not accept "unlocks".

    l_extendedprice_cmd_valid       <= '0';
    l_extendedprice_cmd_firstIdx    <= (others => '0');
    l_extendedprice_cmd_lastIdx     <= (others => '0');
    l_extendedprice_cmd_tag         <= (others => '0');
    
    l_extendedprice_unl_ready       <= '0'; -- Do not accept "unlocks".
    state_next                  <= state; -- Retain current state.

    sum_out_ready               <='0';

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

                
        l_quantity_cmd_valid    <= '1';
        l_quantity_cmd_firstIdx <= l_firstIdx;
        l_quantity_cmd_lastIdx  <= l_lastIdx;
        l_quantity_cmd_tag      <= (others => '0');
        
        l_extendedprice_cmd_valid    <= '1';
        l_extendedprice_cmd_firstIdx <= l_firstIdx;
        l_extendedprice_cmd_lastIdx  <= l_lastIdx;
        l_extendedprice_cmd_tag      <= (others => '0');

        l_shipdate_cmd_valid    <= '1';
        l_shipdate_cmd_firstIdx <= l_firstIdx;
        l_shipdate_cmd_lastIdx  <= l_lastIdx;
        l_shipdate_cmd_tag      <= (others => '0');

        l_discount_cmd_valid    <= '1';
        l_discount_cmd_firstIdx <= l_firstIdx;
        l_discount_cmd_lastIdx  <= l_lastIdx;
        l_discount_cmd_tag      <= (others => '0');

        if l_quantity_cmd_ready = '1' and l_extendedprice_cmd_ready = '1' and l_shipdate_cmd_ready = '1' and l_discount_cmd_ready = '1' then
          state_next <= STATE_CALCULATING;
        end if;

      when STATE_CALCULATING =>
        -- Calculating: we stream in and accumulate the numbers one by one. PROBE Phase is here!
        done <= '0';
        busy <= '1';  
        idle <= '0';
        
        sum_out_ready <='1';

        if sum_out_valid = '1' then
          state_next <= STATE_UNLOCK;
        end if;
        
      when STATE_UNLOCK =>
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
        if l_discount_unl_valid = '1' and l_quantity_unl_valid = '1' and l_shipdate_unl_valid = '1'  and l_extendedprice_unl_valid = '1' then
          state_next <= STATE_DONE;
        end if;

      when STATE_DONE =>
        -- Done: the kernel is done with its job.
        done <= '1';
        busy <= '0';
        idle <= '1';
        
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
        result <= sum_out_data;
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

