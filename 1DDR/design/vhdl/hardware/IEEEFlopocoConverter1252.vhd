--------------------------------------------------------------------------------
--                          InputIEEE_11_52_to_11_52
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

ENTITY InputIEEE_11_52_to_11_52 IS
   PORT (
      clk, rst : IN STD_LOGIC;
      X : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
      R : OUT STD_LOGIC_VECTOR(11 + 52 + 2 DOWNTO 0));
END ENTITY;

ARCHITECTURE arch OF InputIEEE_11_52_to_11_52 IS
   SIGNAL expX : STD_LOGIC_VECTOR(10 DOWNTO 0);
   SIGNAL fracX : STD_LOGIC_VECTOR(51 DOWNTO 0);
   SIGNAL sX : STD_LOGIC;
   SIGNAL expZero : STD_LOGIC;
   SIGNAL expInfty : STD_LOGIC;
   SIGNAL fracZero : STD_LOGIC;
   SIGNAL reprSubNormal : STD_LOGIC;
   SIGNAL sfracX : STD_LOGIC_VECTOR(51 DOWNTO 0);
   SIGNAL fracR : STD_LOGIC_VECTOR(51 DOWNTO 0);
   SIGNAL expR : STD_LOGIC_VECTOR(10 DOWNTO 0);
   SIGNAL infinity : STD_LOGIC;
   SIGNAL zero : STD_LOGIC;
   SIGNAL NaN : STD_LOGIC;
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
   reprSubNormal <= fracX(51);
   -- since we have one more exponent value than IEEE (field 0...0, value emin-1),
   -- we can represent subnormal numbers whose mantissa field begins with a 1
   --sfracX <= '0' & fracX(50 DOWNTO 0) WHEN (expZero = '1' OR reprSubNormal = '1') ELSE
   sfracX <= fracX;
   fracR <= sfracX;
   -- copy exponent. This will be OK even for subnormals, zero and infty since in such cases the exn bits will prevail
   expR <= expX(10 DOWNTO 1) & '1' WHEN (reprSubNormal = '1') ELSE
   expX;
   infinity <= expInfty AND fracZero;
   zero <= expZero AND NOT reprSubNormal;
   NaN <= reprSubNormal; -- Overriden this for now
   exnR <=
   "00" WHEN zero = '1'
   ELSE
   "10" WHEN infinity = '1'
   ELSE
   "11" WHEN NaN = '1'
   ELSE
   "01"; -- normal number
   R <= exnR & sX & expR & fracR;
END ARCHITECTURE;