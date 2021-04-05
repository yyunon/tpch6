


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.ParallelPatterns_pkg.all; 
use work.Stream_pkg.all;
use work.Forecast_pkg.all;

entity ReduceStage is
  generic (
    FIXED_LEFT_INDEX : INTEGER;
    FIXED_RIGHT_INDEX : INTEGER;
    INDEX_WIDTH : integer := 32;
    TAG_WIDTH   : integer := 1
  );
  port (
    clk                          : in  std_logic;
    reset                        : in  std_logic;
    
    in_valid                     : in  std_logic;
    in_dvalid                    : in  std_logic := '1';
    in_ready                     : out std_logic;
    in_last                      : in  std_logic;
    in_data                      : in  std_logic_vector(63 downto 0);
    
    out_valid                    : out std_logic;
    out_ready                    : in  std_logic;
    out_data                     : out std_logic_vector(63 downto 0)
    
  );
end entity;

architecture Behavioral of ReduceStage is  
  
  -- Accumulator output stream.
  signal acc_out_valid               : std_logic;
  signal acc_out_ready               : std_logic;
  signal acc_out_data                : std_logic_vector(63 downto 0);
    
  -- Accumulator input stream.
  signal acc_in_valid                : std_logic;
  signal acc_in_ready                : std_logic;
  signal acc_in_data                 : std_logic_vector(63 downto 0);
  signal acc_in_dvalid               : std_logic;
  
  -- CNTRL input stream.
  signal cntrl_s_in_valid            : std_logic;
  signal cntrl_s_in_ready            : std_logic;
  
  -- Operator input stream.
  signal op_s_in_valid               : std_logic;
  signal op_s_in_ready               : std_logic;
  
  
  -- Compensate counter -> sequencer path if the operation is low-latency.
  signal dly_in_valid               : std_logic;
  signal dly_in_ready               : std_logic;
  signal dly_in_data                : std_logic_vector(64 downto 0);
  
  signal dly_out_valid               :std_logic;
  signal dly_out_ready               :std_logic;
  signal dly_out_data                :std_logic_vector(64 downto 0);
  
   -- controller output slice
  signal cntrl_out_slice_in_valid    : std_logic;
  signal cntrl_out_slice_in_ready    : std_logic;
  signal cntrl_out_slice_in_data     : std_logic_vector(63 downto 0);
  
begin

reduce_cntrl: ReduceStream
   generic map (
     DATA_WIDTH                 => 64,
     IN_DIMENSIONALITY          => 1,
     LENGTH_WIDTH               => INDEX_WIDTH
   )
   port map (
     clk                       => clk,
     reset                     => reset,
     in_valid                  => cntrl_s_in_valid,
     in_ready                  => cntrl_s_in_ready,
     in_last(0)                => in_last,
     
     acc_init_value            => (others => '0'),
      
     acc_out_valid             => acc_out_valid,
     acc_out_ready             => acc_out_ready,
     acc_out_data              => acc_out_data,
      
     acc_in_valid              => acc_in_valid,
     acc_in_ready              => acc_in_ready,
     acc_in_data               => acc_in_data,
     acc_in_dvalid             => acc_in_dvalid,
      
     out_valid                 => cntrl_out_slice_in_valid,
     out_ready                 => cntrl_out_slice_in_ready,
     out_data                  => cntrl_out_slice_in_data
    );
    
  in_sync: StreamSync
    generic map (
      NUM_INPUTS                => 1,
      NUM_OUTPUTS               => 2
    )
    port map (
      clk                       => clk,
      reset                     => reset,

      in_valid(0)               => in_valid,
      in_ready(0)               => in_ready,


      out_valid(0)              => cntrl_s_in_valid,
      out_valid(1)              => dly_in_valid,
      out_ready(0)              => cntrl_s_in_ready,
      out_ready(1)              => dly_in_ready

    );
    
    dly_in_data <= in_dvalid & in_data;
    
    dly: StreamSliceArray
    generic map (
      DATA_WIDTH                 => 65,
      DEPTH                      => 10
    )
    port map (
      clk                       => clk,
      reset                     => reset,

      in_valid                  => dly_in_valid,
      in_ready                  => dly_in_ready,
      in_data                   => dly_in_data,

      out_valid                 => op_s_in_valid,
      out_ready                 => op_s_in_ready,
      out_data                  => dly_out_data

    );
    
    
  operator: SumOp
   generic map (
    FIXED_LEFT_INDEX            => FIXED_LEFT_INDEX,
    FIXED_RIGHT_INDEX           => FIXED_RIGHT_INDEX,
     DATA_WIDTH                 => 64,
     DATA_TYPE                  => "FLOAT64"
   )
   port map (
     clk                       => clk,
     reset                     => reset,
     
     op1_valid                 => op_s_in_valid,
     op1_ready                 => op_s_in_ready,
     op1_dvalid                => dly_out_data(64),
     op1_data                  => dly_out_data(63 downto 0),
     
     op2_valid                 => acc_out_valid,
     op2_ready                 => acc_out_ready,
     op2_data                  => acc_out_data,
     
     out_valid                 => acc_in_valid,
     out_ready                 => acc_in_ready,
     out_data                  => acc_in_data,
     out_dvalid                => acc_in_dvalid
     
    );
    
      
   cntrl_out_slice : StreamSlice 
      generic map (
        DATA_WIDTH          => 64
      )
      port map(
        clk                 => clk,
        reset               => reset,
        in_valid            => cntrl_out_slice_in_valid,
        in_ready            => cntrl_out_slice_in_ready,
        in_data             => cntrl_out_slice_in_data,
        out_valid           => out_valid,
        out_ready           => out_ready,
        out_data            => out_data
      );
    
 
    
end Behavioral;
