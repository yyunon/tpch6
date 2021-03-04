-- This code is directly taken from vhlib but async read is implemented
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

--library ieee_proposed;
--use ieee_proposed.fixed_pkg.all;

library work;
use work.Stream_pkg.all;
use work.Forecast_pkg.all;

use work.fixed_generic_pkg_mod.all;
use work.float_pkg_mod.all;


-- In the first prototype generate different hws for each op.
entity ALU is
  generic (

    -- Width of a data word.
    FIXED_LEFT_INDEX            : INTEGER;
    FIXED_RIGHT_INDEX           : INTEGER;
    DATA_WIDTH                       : natural;

    ALUTYPE                          : string := ""

  );
  port (
    clk                       : in  std_logic;
    reset                     : in  std_logic;

    in_valid                     : in  std_logic;
    in_dvalid                    : in  std_logic := '1';
    in_ready                     : out std_logic;
    in_last                      : in  std_logic;
    in_data                      : in  std_logic_vector(63 downto 0);
    
    out_valid                    : out std_logic;
    out_ready                    : in  std_logic;
    out_data                     : out std_logic_vector(63 downto 0)

  );
end ALU;

architecture Behavioral of ALU is

  signal temp_buffer              : sfixed(FIXED_LEFT_INDEX downto FIXED_RIGHT_INDEX);
  signal ops_valid                : std_logic;
  signal ops_ready                : std_logic;
  signal ops_data                 : std_logic_vector(DATA_WIDTH - 1 downto 0);

  signal result                   : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
  signal ops_ready_s              : std_logic;
  signal out_valid_s              : std_logic;

begin

   -- Synchronize the operand stream
 op_in_sync: StreamSlice
    generic map (
        DATA_WIDTH => DATA_WIDTH
        --MIN_DEPTH => 64
    )
    port map (
      clk                       => clk,
      reset                     => reset,

      in_valid                  => in_valid,
      in_ready                  => in_ready,
      in_data                   => in_data,

      out_valid                 => ops_valid,
      out_ready                 => ops_ready,
      out_data                  => ops_data
    );   

  ops_ready <= out_ready;
  out_data <= result;
  out_valid <= out_valid_s;

  quantity_proc: 
  if ALUTYPE="LESSTHAN"  generate
    process(ops_data) is 
      variable temp_float_1 : float64; -- float(11 downto -52);
      variable temp_buffer_1: sfixed(FIXED_LEFT_INDEX downto FIXED_RIGHT_INDEX);
    begin
      temp_buffer_1 := to_sfixed(u_float64(ops_data),temp_buffer_1'high, temp_buffer_1'low);
      temp_buffer <= temp_buffer_1;
    end process;
    process(temp_buffer,ops_valid,out_ready, ops_ready) is
      -- Comparison constants
      constant QUANTITY_CONST                  : sfixed(FIXED_LEFT_INDEX downto FIXED_RIGHT_INDEX) := to_sfixed(24.0, FIXED_LEFT_INDEX,FIXED_RIGHT_INDEX);
    begin 
      out_valid_s <= '0';
      result(0) <= '0';
      if ops_valid = '1' and ops_ready = '1' then
        out_valid_s <= '1';
        if temp_buffer < QUANTITY_CONST then 
          result(0) <= '1';
        end if;
      end if;
    end process;
  end generate;

  discount_proc: 
  if ALUTYPE="BETWEEN" generate
    process(ops_data) is 
      variable temp_float_1 : float64; -- float(11 downto -52);
      variable temp_buffer_1: sfixed(FIXED_LEFT_INDEX downto FIXED_RIGHT_INDEX);
    begin
      temp_buffer_1 := to_sfixed(u_float64(ops_data),temp_buffer_1'high,temp_buffer_1'low);
      temp_buffer <= temp_buffer_1;
    end process;
    process(temp_buffer,ops_valid,ops_ready,out_ready) is

      constant DISCOUNT_CONST_DOWN              : sfixed(FIXED_LEFT_INDEX downto FIXED_RIGHT_INDEX) := to_sfixed(0.05000000, FIXED_LEFT_INDEX,FIXED_RIGHT_INDEX);
      constant DISCOUNT_CONST_UP                : sfixed(FIXED_LEFT_INDEX downto FIXED_RIGHT_INDEX) := to_sfixed(0.07000000, FIXED_LEFT_INDEX,FIXED_RIGHT_INDEX);

    begin 
      out_valid_s <= '0';
      result(0) <= '0';
      if ops_valid = '1' and ops_ready = '1' then
        ops_ready_s <= out_ready;
        out_valid_s <= '1';
        if (temp_buffer <= DISCOUNT_CONST_UP) and (temp_buffer >= DISCOUNT_CONST_DOWN) then 
          result(0) <= '1';
        end if;
      end if;
    end process;
  end generate;

  shipdate_proc: 
  if ALUTYPE="DATE"  generate
    process(ops_data,ops_valid,out_ready, ops_ready) is
    --Dates are encoded as 1000*year + 100*month + 10*day conventions
      constant DATE_LOW: integer := 8766;
      constant DATE_HIGH: integer := 9131;
    begin 
      out_valid_s <= '0';
      result(0) <= '0';
      if ops_valid = '1' and ops_ready = '1' then
        ops_ready_s <= out_ready;
        out_valid_s <= '1';
        if (to_integer(unsigned(ops_data)) >= DATE_LOW) and (to_integer(unsigned(ops_data)) < DATE_HIGH)  then
            result(0) <= '1';
        end if;
      end if;
    end process;
  end generate;

end Behavioral;
