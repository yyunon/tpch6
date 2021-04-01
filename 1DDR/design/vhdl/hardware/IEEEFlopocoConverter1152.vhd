--------------------------------------------------------------------------------
--                          InputIEEE_11_52_to_12_52
-- This operator is part of the Infinite Virtual Library FloPoCoLib
-- All rights reserved 
-- Authors: Florent de Dinechin (2008)
--------------------------------------------------------------------------------
-- Pipeline depth: 0 cycles

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_unsigned.ALL;
LIBRARY std;
USE std.textio.ALL;
LIBRARY work;

ENTITY InputIEEE_11_52_to_12_52 IS
   PORT (
      clk, rst : IN STD_LOGIC;
      X : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
      R : OUT STD_LOGIC_VECTOR(12 + 52 + 2 DOWNTO 0));
END ENTITY;

ARCHITECTURE arch OF InputIEEE_11_52_to_12_52 IS
   SIGNAL expX : STD_LOGIC_VECTOR(10 DOWNTO 0);
   SIGNAL fracX : STD_LOGIC_VECTOR(51 DOWNTO 0);
   SIGNAL sX : STD_LOGIC;
   SIGNAL expZero : STD_LOGIC;
   SIGNAL expInfty : STD_LOGIC;
   SIGNAL fracZero : STD_LOGIC;
   SIGNAL overflow : STD_LOGIC;
   SIGNAL underflow : STD_LOGIC;
   SIGNAL expR : STD_LOGIC_VECTOR(11 DOWNTO 0);
   SIGNAL fracR : STD_LOGIC_VECTOR(51 DOWNTO 0);
   SIGNAL roundOverflow : STD_LOGIC;
   SIGNAL NaN : STD_LOGIC;
   SIGNAL infinity : STD_LOGIC;
   SIGNAL zero : STD_LOGIC;
   SIGNAL exnR : STD_LOGIC_VECTOR(1 DOWNTO 0);
BEGIN
   PROCESS (clk)
   BEGIN
      IF clk'event AND clk = '1' THEN
      END IF;
   END PROCESS;
   expX <= X(62 DOWNTO 52);
   fracX <= X(51 DOWNTO 0);
   sX <= X(63);
   expZero <= '1' WHEN expX = (10 DOWNTO 0 => '0') ELSE
   '0';
   expInfty <= '1' WHEN expX = (10 DOWNTO 0 => '1') ELSE
   '0';
   fracZero <= '1' WHEN fracX = (51 DOWNTO 0 => '0') ELSE
   '0';
   overflow <= '0';--  overflow never happens for these (wE_in, wE_out)
   underflow <= '0';--  underflow never happens for these (wE_in, wE_out)
   expR <= ((11 DOWNTO 11 => '0') & expX) + "010000000000";
   fracR <= fracX;
   roundOverflow <= '0';
   NaN <= expInfty AND NOT fracZero;
   infinity <= (expInfty AND fracZero) OR (NOT NaN AND (overflow OR roundOverflow));
   zero <= expZero OR underflow;
   exnR <=
   "11" WHEN NaN = '1'
   ELSE
   "10" WHEN infinity = '1'
   ELSE
   "00" WHEN zero = '1'
   ELSE
   "01"; -- normal number
   R <= exnR & sX & expR & fracR;
END ARCHITECTURE;