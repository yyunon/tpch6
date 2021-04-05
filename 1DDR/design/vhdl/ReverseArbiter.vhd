---------------------------------
-- Bus Arbiter
-- Yuksel Yonsel
---------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

LIBRARY work;
USE work.Stream_pkg.ALL;
USE work.ParallelPatterns_pkg.ALL;
USE work.Forecast_pkg.ALL;

-- There already is a arbiter in fletcher. 
-- This module will try to modulate it with 1 inputs 
-- and 4 
ENTITY ReverseArbiter IS
  GENERIC (

    -- Width of the stream data vector.

    DATA_TYPE : STRING := "";
    EPC : NATURAL

  );
  PORT (

    -- Rising-edge sensitive clock.
    clk : IN STD_LOGIC;

    -- Active-high synchronous reset.
    reset : IN STD_LOGIC;

    in_ready : IN STD_LOGIC;

    out_ready : in std_logic_vector(EPC - 1 downto 0);
    request : IN STD_LOGIC_VECTOR(EPC - 1 DOWNTO 0);
    grant : IN STD_LOGIC_VECTOR(EPC - 1 DOWNTO 0)
  );
END ReverseArbiter;

ARCHITECTURE Behaviour OF ReverseArbiter IS

BEGIN

END ARCHITECTURE;