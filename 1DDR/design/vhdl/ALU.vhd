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
entity FILTER is
  generic (

    -- Width of a data word.
    FIXED_LEFT_INDEX             : INTEGER;
    FIXED_RIGHT_INDEX            : INTEGER;
    DATA_WIDTH                   : NATURAl;
    INPUT_MIN_DEPTH              : INTEGER;
    OUTPUT_MIN_DEPTH             : INTEGER;

    FILTERTYPE                      : string := ""

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
    out_data                     : out std_logic

  );
end FILTER;

architecture Behavioral of FILTER is

  signal temp_buffer             : sfixed(FIXED_LEFT_INDEX downto FIXED_RIGHT_INDEX);
  signal temp_buffer_int         : integer;
  signal ops_valid               : std_logic;
  signal ops_ready               : std_logic;
  signal ops_last                : std_logic;
  signal ops_data                : std_logic_vector(DATA_WIDTH - 1 downto 0);

  signal result                  : std_logic := '0';

  signal ops_ready_s             : std_logic;

  signal out_ready_s             : std_logic;
  signal out_valid_s             : std_logic;
  signal out_data_s              : std_logic;

begin

   -- Synchronize the operand stream
 filter_in_buffer: StreamBuffer
    generic map (
        DATA_WIDTH => DATA_WIDTH + 1,
        MIN_DEPTH => INPUT_MIN_DEPTH
    )
    port map (
      clk                        => clk,
      reset                      => reset,

      in_valid                   => in_valid,
      in_ready                   => in_ready,
      in_data(64)                => in_last,
      in_data(63 downto 0)       => in_data,

      out_valid                  => ops_valid,
      out_ready                  => ops_ready,
      out_data(64)               => ops_last,
      out_data(63 downto 0)      => ops_data
    );   

   -- Synchronize the operand stream
 filter_out_buffer: StreamBuffer
    generic map (
        DATA_WIDTH => 1,
        MIN_DEPTH => OUTPUT_MIN_DEPTH
    )
    port map (
      clk                        => clk,
      reset                      => reset,

      in_valid                   => out_valid_s,
      in_ready                   => out_ready_s,
      in_data(0)                 => out_data_s,

      out_valid                  => out_valid,
      out_ready                  => out_ready,
      out_data(0)                => out_data
    );   

  ops_ready <= out_ready_s and ops_ready_s;
  out_data_s <= result;

  quantity_proc: 
  if FILTERTYPE="LESSTHAN"  generate
    --process(ops_data) is 
    --  --variable temp_float_1 : float64; -- float(11 downto -52);
    --  variable temp_buffer_1: sfixed(FIXED_LEFT_INDEX downto FIXED_RIGHT_INDEX);
    --begin
    --  temp_buffer <=to_sfixed(ops_data,FIXED_LEFT_INDEX, FIXED_RIGHT_INDEX) ;
    --  --temp_buffer <= temp_buffer_1;
    --end process;
    process(ops_data,ops_valid,out_ready_s) is
      -- Comparison constants
      constant QUANTITY_CONST                  : sfixed(FIXED_LEFT_INDEX downto FIXED_RIGHT_INDEX) := to_sfixed(24.0, FIXED_LEFT_INDEX,FIXED_RIGHT_INDEX);
    begin 
      out_valid_s   <= '0';
      ops_ready_s   <= '0';
      result        <= '0';
      if ops_valid = '1' and out_ready_s = '1' then
        ops_ready_s <= '1';
        out_valid_s <= '1';
        if to_sfixed(ops_data,FIXED_LEFT_INDEX, FIXED_RIGHT_INDEX) < QUANTITY_CONST then 
          result    <= '1';
        end if;
      end if;
    end process;
  end generate;

  discount_proc: 
  if FILTERTYPE="BETWEEN" generate
    --process(ops_data) is 
    --  --variable temp_float_1 : float64; -- float(11 downto -52);
    --  variable temp_buffer_1: sfixed(FIXED_LEFT_INDEX downto FIXED_RIGHT_INDEX);
    --begin
    --  temp_buffer <= to_sfixed(ops_data,temp_buffer_1'high,temp_buffer_1'low);
    --  --temp_buffer <= temp_buffer_1;
    --end process;
    process(ops_data,ops_valid,out_ready_s) is

      constant DISCOUNT_CONST_DOWN              : sfixed(FIXED_LEFT_INDEX downto FIXED_RIGHT_INDEX) := to_sfixed(0.05000000, FIXED_LEFT_INDEX,FIXED_RIGHT_INDEX);
      constant DISCOUNT_CONST_UP                : sfixed(FIXED_LEFT_INDEX downto FIXED_RIGHT_INDEX) := to_sfixed(0.07000000, FIXED_LEFT_INDEX,FIXED_RIGHT_INDEX);

    begin 
      out_valid_s  <= '0';
      ops_ready_s  <= '0';
      result       <= '0';
      if ops_valid = '1' and out_ready_s = '1' then
        ops_ready_s<= '1';
        out_valid_s<= '1';
        if (to_sfixed(ops_data,FIXED_LEFT_INDEX, FIXED_RIGHT_INDEX) <= DISCOUNT_CONST_UP) and (to_sfixed(ops_data,FIXED_LEFT_INDEX, FIXED_RIGHT_INDEX) >= DISCOUNT_CONST_DOWN) then 
          result   <= '1';
        end if;
      end if;
    end process;
  end generate;

  shipdate_proc: 
  if FILTERTYPE="DATE"  generate
    --process(ops_data) is 
    --  --variable temp_float_1 : float64; -- float(11 downto -52);
    --  variable temp_buffer_1: sfixed(FIXED_LEFT_INDEX downto FIXED_RIGHT_INDEX);
    --begin
    --  temp_buffer_int <= to_integer(unsigned(ops_data));
    --end process;
    process(ops_data,ops_valid,out_ready_s) is
      constant DATE_LOW: integer := 8766;
      constant DATE_HIGH: integer := 9131;
    begin 
      out_valid_s   <= '0';
      ops_ready_s   <= '0';
      result        <= '0';
      if ops_valid = '1' and out_ready_s = '1' then
        ops_ready_s <= '1';
        out_valid_s <= '1';
        if ( to_integer(unsigned(ops_data)) >= DATE_LOW) and ( to_integer(unsigned(ops_data)) < DATE_HIGH)  then
            result  <= '1';
        end if;
      end if;
    end process;
  end generate;

end Behavioral;
