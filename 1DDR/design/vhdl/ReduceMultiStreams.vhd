-- This code is directly taken from vhlib but async read is implemented
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

library ieee_proposed;
use ieee_proposed.fixed_pkg.all;

library work;
use work.Stream_pkg.all;
use work.ParallelPatterns_pkg.all; 
use work.Forecast_pkg.all;

--use work.fixed_generic_pkg_mod.all;


-- In the first prototype generate different hws for each op.

entity ReduceMultiEpc is 
  generic (

    -- Width of a data word.
    EPC                             : natural;
    FIXED_LEFT_INDEX                : INTEGER;
    FIXED_RIGHT_INDEX               : INTEGER;
    DATA_WIDTH                      : natural

  );
  port (
    clk                             : in  std_logic;
    reset                           : in  std_logic;

    in_valid                        : in  std_logic;
    in_ready                        : out std_logic;
    in_data                         : in  std_logic_vector(DATA_WIDTH*EPC -1  downto 0);
    
    out_valid                       : out std_logic;
    out_ready                       : in  std_logic;
    out_data                        : out std_logic_vector(DATA_WIDTH - 1 downto 0)

  );

end ReduceMultiEpc;

architecture Behavioral of ReduceMultiEpc is

  signal accumulator               : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal accumulator_ready               : std_logic;
  signal accumulator_valid               : std_logic;

begin

   -- Output Slice
 op_in_sync: StreamSlice
    generic map (
        DATA_WIDTH => DATA_WIDTH
        --MIN_DEPTH => 1
    )
    port map (
      clk                       => clk,
      reset                     => reset,

      in_valid                  => accumulator_valid,
      in_ready                  => accumulator_ready,
      in_data                   => accumulator,

      out_valid                 => out_valid,
      out_ready                 => out_ready,
      out_data                  => out_data
    );   
 
  acc_process:
    process(in_data, in_valid, accumulator_ready)
      variable temp_inp_1         : sfixed(FIXED_LEFT_INDEX downto FIXED_RIGHT_INDEX);
      variable temp_inp_2         : sfixed(FIXED_LEFT_INDEX downto FIXED_RIGHT_INDEX);
      variable temp_inp_3         : sfixed(FIXED_LEFT_INDEX downto FIXED_RIGHT_INDEX);
      variable temp_inp_4         : sfixed(FIXED_LEFT_INDEX downto FIXED_RIGHT_INDEX);
      variable temp_acc           : sfixed(FIXED_LEFT_INDEX + 3 downto FIXED_RIGHT_INDEX);
    begin
      accumulator_valid <= '0';
      if(in_valid = '1') and (accumulator_ready = '1') then
      -- TODO: Make this unrolling better. Possibly not hardcoded.
        temp_inp_1 := to_sfixed(in_data(DATA_WIDTH - 1 downto 0), FIXED_LEFT_INDEX, FIXED_RIGHT_INDEX);
        temp_inp_2 := to_sfixed(in_data(2*DATA_WIDTH - 1 downto DATA_WIDTH), FIXED_LEFT_INDEX, FIXED_RIGHT_INDEX);
        temp_inp_3 := to_sfixed(in_data(3*DATA_WIDTH - 1 downto 2 * DATA_WIDTH), FIXED_LEFT_INDEX, FIXED_RIGHT_INDEX);
        temp_inp_4 := to_sfixed(in_data(4*DATA_WIDTH - 1 downto 3 * DATA_WIDTH), FIXED_LEFT_INDEX, FIXED_RIGHT_INDEX);

        temp_acc := temp_inp_1 + temp_inp_2 + temp_inp_3 + temp_inp_4;
        accumulator <= to_slv(resize( arg => temp_acc,left_index => FIXED_LEFT_INDEX, right_index => FIXED_RIGHT_INDEX, round_style => fixed_round_style, overflow_style => fixed_overflow_style));
        accumulator_valid <= '1';
      end if;

    end process;

end Behavioral;
