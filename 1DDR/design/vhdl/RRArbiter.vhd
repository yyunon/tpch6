---------------------------------
-- Bus Arbiter
-- Yuksel Yonsel
---------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.Stream_pkg.all;
use work.ParallelPatterns_pkg.all; 
use work.Forecast_pkg.all;
use work.fixed_generic_pkg_mod.all;

-- There already is a arbiter in fletcher. 
-- This module will try to modulate it with 1 inputs 
-- and 4 
entity InputArbiter is
  generic (

    -- Width of the stream data vector.

    DATA_TYPE                   : string :="";
    EPC                         : natural

  );
  port (

    -- Rising-edge sensitive clock.
    clk                          : in  std_logic;

    -- Active-high synchronous reset.
    reset                        : in  std_logic;

    request                      : in std_logic_vector(EPC - 1 downto 0);
    grant                        : in std_logic_vector(EPC - 1 downto 0)
  );
end InputArbiter;

architecture Behaviour of InputArbiter is 

begin      

end architecture;