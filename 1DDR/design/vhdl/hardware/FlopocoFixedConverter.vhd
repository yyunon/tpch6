--------------------------------------------------------------------------------
--                          InputIEEE_11_52_to_11_52
-- This operator is part of the Infinite Virtual Library FloPoCoLib
-- All rights reserved 
-- Authors: Florent de Dinechin (2008)
--------------------------------------------------------------------------------
-- Pipeline depth: 0 cycles

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
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
   constant exponent_base : std_logic_vector(10 downto 0) := "11111111111";
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
   sfracX <= fracX(50 DOWNTO 0) & '0' WHEN (expZero = '1' OR reprSubNormal = '1') ELSE
      fracX;
   fracR <= sfracX;
   -- copy exponent. This will be OK even for subnormals, zero and infty since in such cases the exn bits will prevail
   --expR <= "10000000010" WHEN (reprSubNormal = '1') ELSE
   --   expX;
   expR <= expX;
   infinity <= expInfty AND fracZero;
   zero <= expZero AND NOT reprSubNormal;
   NaN <= expInfty AND NOT fracZero;
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

--------------------------------------------------------------------------------
--           FP2Fix_11_52M_32_31_S_NT_F400_uid3Exponent_difference
--                          (IntAdder_11_f400_uid5)
-- This operator is part of the Infinite Virtual Library FloPoCoLib
-- All rights reserved 
-- Authors: Bogdan Pasca, Florent de Dinechin (2008-2010)
--------------------------------------------------------------------------------
-- Pipeline depth: 0 cycles

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_unsigned.ALL;
LIBRARY std;
USE std.textio.ALL;
LIBRARY work;

ENTITY FP2Fix_11_52M_32_31_S_NT_F400_uid3Exponent_difference IS
   PORT (
      clk, rst : IN STD_LOGIC;
      X : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
      Y : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
      Cin : IN STD_LOGIC;
      R : OUT STD_LOGIC_VECTOR(10 DOWNTO 0));
END ENTITY;

ARCHITECTURE arch OF FP2Fix_11_52M_32_31_S_NT_F400_uid3Exponent_difference IS
BEGIN
   PROCESS (clk)
   BEGIN
      IF clk'event AND clk = '1' THEN
      END IF;
   END PROCESS;
   --Classical
   R <= X + Y + Cin;
END ARCHITECTURE;

--------------------------------------------------------------------------------
--                    LeftShifter_53_by_max_66_F400_uid13
-- This operator is part of the Infinite Virtual Library FloPoCoLib
-- All rights reserved 
-- Authors: Bogdan Pasca, Florent de Dinechin (2008-2011)
--------------------------------------------------------------------------------
-- Pipeline depth: 3 cycles

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_unsigned.ALL;
LIBRARY std;
USE std.textio.ALL;
LIBRARY work;

ENTITY LeftShifter_53_by_max_66_F400_uid13 IS
   PORT (
      clk, rst : IN STD_LOGIC;
      X : IN STD_LOGIC_VECTOR(52 DOWNTO 0);
      S : IN STD_LOGIC_VECTOR(6 DOWNTO 0);
      R : OUT STD_LOGIC_VECTOR(118 DOWNTO 0));
END ENTITY;

ARCHITECTURE arch OF LeftShifter_53_by_max_66_F400_uid13 IS
   SIGNAL level0 : STD_LOGIC_VECTOR(52 DOWNTO 0);
   SIGNAL ps, ps_d1, ps_d2, ps_d3 : STD_LOGIC_VECTOR(6 DOWNTO 0);
   SIGNAL level1 : STD_LOGIC_VECTOR(53 DOWNTO 0);
   SIGNAL level2, level2_d1 : STD_LOGIC_VECTOR(55 DOWNTO 0);
   SIGNAL level3 : STD_LOGIC_VECTOR(59 DOWNTO 0);
   SIGNAL level4, level4_d1 : STD_LOGIC_VECTOR(67 DOWNTO 0);
   SIGNAL level5 : STD_LOGIC_VECTOR(83 DOWNTO 0);
   SIGNAL level6, level6_d1 : STD_LOGIC_VECTOR(115 DOWNTO 0);
   SIGNAL level7 : STD_LOGIC_VECTOR(179 DOWNTO 0);
BEGIN
   PROCESS (clk)
   BEGIN
      IF clk'event AND clk = '1' THEN
         ps_d1 <= ps;
         ps_d2 <= ps_d1;
         ps_d3 <= ps_d2;
         level2_d1 <= level2;
         level4_d1 <= level4;
         level6_d1 <= level6;
      END IF;
   END PROCESS;
   level0 <= X;
   ps <= S;
   level1 <= level0 & (0 DOWNTO 0 => '0') WHEN ps(0) = '1' ELSE
      (0 DOWNTO 0 => '0') & level0;
   level2 <= level1 & (1 DOWNTO 0 => '0') WHEN ps(1) = '1' ELSE
      (1 DOWNTO 0 => '0') & level1;
   ----------------Synchro barrier, entering cycle 1----------------
   level3 <= level2_d1 & (3 DOWNTO 0 => '0') WHEN ps_d1(2) = '1' ELSE
      (3 DOWNTO 0 => '0') & level2_d1;
   level4 <= level3 & (7 DOWNTO 0 => '0') WHEN ps_d1(3) = '1' ELSE
      (7 DOWNTO 0 => '0') & level3;
   ----------------Synchro barrier, entering cycle 2----------------
   level5 <= level4_d1 & (15 DOWNTO 0 => '0') WHEN ps_d2(4) = '1' ELSE
      (15 DOWNTO 0 => '0') & level4_d1;
   level6 <= level5 & (31 DOWNTO 0 => '0') WHEN ps_d2(5) = '1' ELSE
      (31 DOWNTO 0 => '0') & level5;
   ----------------Synchro barrier, entering cycle 3----------------
   level7 <= level6_d1 & (63 DOWNTO 0 => '0') WHEN ps_d3(6) = '1' ELSE
      (63 DOWNTO 0 => '0') & level6_d1;
   R <= level7(118 DOWNTO 0);
END ARCHITECTURE;

--------------------------------------------------------------------------------
--                 FP2Fix_11_52M_32_31_S_NT_F400_uid3MantSum
--                          (IntAdder_65_f400_uid17)
-- This operator is part of the Infinite Virtual Library FloPoCoLib
-- All rights reserved 
-- Authors: Bogdan Pasca, Florent de Dinechin (2008-2010)
--------------------------------------------------------------------------------
-- Pipeline depth: 1 cycles

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_unsigned.ALL;
LIBRARY std;
USE std.textio.ALL;
LIBRARY work;

ENTITY FP2Fix_11_52M_32_31_S_NT_F400_uid3MantSum IS
   PORT (
      clk, rst : IN STD_LOGIC;
      X : IN STD_LOGIC_VECTOR(64 DOWNTO 0);
      Y : IN STD_LOGIC_VECTOR(64 DOWNTO 0);
      Cin : IN STD_LOGIC;
      R : OUT STD_LOGIC_VECTOR(64 DOWNTO 0));
END ENTITY;

ARCHITECTURE arch OF FP2Fix_11_52M_32_31_S_NT_F400_uid3MantSum IS
   SIGNAL s_sum_l0_idx0 : STD_LOGIC_VECTOR(42 DOWNTO 0);
   SIGNAL s_sum_l0_idx1, s_sum_l0_idx1_d1 : STD_LOGIC_VECTOR(23 DOWNTO 0);
   SIGNAL sum_l0_idx0, sum_l0_idx0_d1 : STD_LOGIC_VECTOR(41 DOWNTO 0);
   SIGNAL c_l0_idx0, c_l0_idx0_d1 : STD_LOGIC_VECTOR(0 DOWNTO 0);
   SIGNAL sum_l0_idx1 : STD_LOGIC_VECTOR(22 DOWNTO 0);
   SIGNAL c_l0_idx1 : STD_LOGIC_VECTOR(0 DOWNTO 0);
   SIGNAL s_sum_l1_idx1 : STD_LOGIC_VECTOR(23 DOWNTO 0);
   SIGNAL sum_l1_idx1 : STD_LOGIC_VECTOR(22 DOWNTO 0);
   SIGNAL c_l1_idx1 : STD_LOGIC_VECTOR(0 DOWNTO 0);
BEGIN
   PROCESS (clk)
   BEGIN
      IF clk'event AND clk = '1' THEN
         s_sum_l0_idx1_d1 <= s_sum_l0_idx1;
         sum_l0_idx0_d1 <= sum_l0_idx0;
         c_l0_idx0_d1 <= c_l0_idx0;
      END IF;
   END PROCESS;
   --Alternative
   s_sum_l0_idx0 <= ("0" & X(41 DOWNTO 0)) + ("0" & Y(41 DOWNTO 0)) + Cin;
   s_sum_l0_idx1 <= ("0" & X(64 DOWNTO 42)) + ("0" & Y(64 DOWNTO 42));
   sum_l0_idx0 <= s_sum_l0_idx0(41 DOWNTO 0);
   c_l0_idx0 <= s_sum_l0_idx0(42 DOWNTO 42);
   sum_l0_idx1 <= s_sum_l0_idx1(22 DOWNTO 0);
   c_l0_idx1 <= s_sum_l0_idx1(23 DOWNTO 23);
   ----------------Synchro barrier, entering cycle 1----------------
   s_sum_l1_idx1 <= s_sum_l0_idx1_d1 + c_l0_idx0_d1(0 DOWNTO 0);
   sum_l1_idx1 <= s_sum_l1_idx1(22 DOWNTO 0);
   c_l1_idx1 <= s_sum_l1_idx1(23 DOWNTO 23);
   R <= sum_l1_idx1(22 DOWNTO 0) & sum_l0_idx0_d1(41 DOWNTO 0);
END ARCHITECTURE;

--------------------------------------------------------------------------------
--                     FP2Fix_11_52M_32_31_S_NT_F400_uid3
-- This operator is part of the Infinite Virtual Library FloPoCoLib
-- All rights reserved 
-- Authors: Fabrizio Ferrandi (2012)
--------------------------------------------------------------------------------
-- Pipeline depth: 6 cycles

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_unsigned.ALL;
LIBRARY std;
USE std.textio.ALL;
LIBRARY work;

ENTITY FP2Fix_11_52M_32_31_S_NT_F400_uid3 IS
   PORT (
      clk, rst : IN STD_LOGIC;
      I : IN STD_LOGIC_VECTOR(11 + 52 + 2 DOWNTO 0);
      O : OUT STD_LOGIC_VECTOR(63 DOWNTO 0));
END ENTITY;

ARCHITECTURE arch OF FP2Fix_11_52M_32_31_S_NT_F400_uid3 IS
   COMPONENT FP2Fix_11_52M_32_31_S_NT_F400_uid3Exponent_difference IS
      PORT (
         clk, rst : IN STD_LOGIC;
         X : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
         Y : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
         Cin : IN STD_LOGIC;
         R : OUT STD_LOGIC_VECTOR(10 DOWNTO 0));
   END COMPONENT;

   COMPONENT LeftShifter_53_by_max_66_F400_uid13 IS
      PORT (
         clk, rst : IN STD_LOGIC;
         X : IN STD_LOGIC_VECTOR(52 DOWNTO 0);
         S : IN STD_LOGIC_VECTOR(6 DOWNTO 0);
         R : OUT STD_LOGIC_VECTOR(118 DOWNTO 0));
   END COMPONENT;

   COMPONENT FP2Fix_11_52M_32_31_S_NT_F400_uid3MantSum IS
      PORT (
         clk, rst : IN STD_LOGIC;
         X : IN STD_LOGIC_VECTOR(64 DOWNTO 0);
         Y : IN STD_LOGIC_VECTOR(64 DOWNTO 0);
         Cin : IN STD_LOGIC;
         R : OUT STD_LOGIC_VECTOR(64 DOWNTO 0));
   END COMPONENT;

   SIGNAL eA0 : STD_LOGIC_VECTOR(10 DOWNTO 0);
   SIGNAL fA0, fA0_d1 : STD_LOGIC_VECTOR(52 DOWNTO 0);
   SIGNAL bias : STD_LOGIC_VECTOR(10 DOWNTO 0);
   SIGNAL eA1, eA1_d1 : STD_LOGIC_VECTOR(10 DOWNTO 0);
   SIGNAL shiftedby : STD_LOGIC_VECTOR(6 DOWNTO 0);
   SIGNAL fA1 : STD_LOGIC_VECTOR(118 DOWNTO 0);
   SIGNAL fA2a : STD_LOGIC_VECTOR(64 DOWNTO 0);
   SIGNAL notallzero : STD_LOGIC;
   SIGNAL round : STD_LOGIC;
   SIGNAL fA2b : STD_LOGIC_VECTOR(64 DOWNTO 0);
   SIGNAL fA3, fA3_d1 : STD_LOGIC_VECTOR(64 DOWNTO 0);
   SIGNAL fA3b : STD_LOGIC_VECTOR(64 DOWNTO 0);
   SIGNAL fA4 : STD_LOGIC_VECTOR(63 DOWNTO 0);
   SIGNAL overFl0 : STD_LOGIC;
   SIGNAL overFl1 : STD_LOGIC;
   SIGNAL eTest : STD_LOGIC;
   SIGNAL I_d1, I_d2, I_d3, I_d4, I_d5, I_d6 : STD_LOGIC_VECTOR(11 + 52 + 2 DOWNTO 0);
BEGIN
   PROCESS (clk)
   BEGIN
      IF clk'event AND clk = '1' THEN
         fA0_d1 <= fA0;
         eA1_d1 <= eA1;
         fA3_d1 <= fA3;
         I_d1 <= I;
         I_d2 <= I_d1;
         I_d3 <= I_d2;
         I_d4 <= I_d3;
         I_d5 <= I_d4;
         I_d6 <= I_d5;
      END IF;
   END PROCESS;
   eA0 <= I(62 DOWNTO 52);
   fA0 <= "1" & I(51 DOWNTO 0);
   bias <= NOT conv_std_logic_vector(1022, 11);
   Exponent_difference : FP2Fix_11_52M_32_31_S_NT_F400_uid3Exponent_difference -- pipelineDepth=0 maxInDelay=0
   PORT MAP(
      clk => clk,
      rst => rst,
      Cin => '1',
      R => eA1,
      X => bias,
      Y => eA0);
   ---------------- cycle 0----------------
   ----------------Synchro barrier, entering cycle 1----------------
   shiftedby <= eA1_d1(6 DOWNTO 0) WHEN eA1_d1(10) = '0' ELSE
      (6 DOWNTO 0 => '0');
   FXP_shifter : LeftShifter_53_by_max_66_F400_uid13 -- pipelineDepth=3 maxInDelay=0
   PORT MAP(
      clk => clk,
      rst => rst,
      R => fA1,
      S => shiftedby,
      X => fA0_d1);
   ----------------Synchro barrier, entering cycle 4----------------
   fA2a <= '0' & fA1(84 DOWNTO 21);
   notallzero <= '0' WHEN fA1(19 DOWNTO 0) = (19 DOWNTO 0 => '0') ELSE
      '1';
   round <= (fA1(20) AND I_d4(63)) OR (fA1(20) AND notallzero AND NOT I_d4(63));
   fA2b <= '0' & (63 DOWNTO 1 => '0') & round;
   MantSum : FP2Fix_11_52M_32_31_S_NT_F400_uid3MantSum -- pipelineDepth=1 maxInDelay=0
   PORT MAP(
      clk => clk,
      rst => rst,
      Cin => '0',
      R => fA3,
      X => fA2a,
      Y => fA2b);
   ---------------- cycle 5----------------
   ----------------Synchro barrier, entering cycle 6----------------
   fA3b <= - signed(fA3_d1);
   fA4 <= fA3_d1(63 DOWNTO 0) WHEN I_d6(63) = '0' ELSE
      fA3b(63 DOWNTO 0);
   overFl0 <= '1' WHEN I_d6(62 DOWNTO 52) > conv_std_logic_vector(1054, 11) ELSE
      I_d6(65);
   overFl1 <= fA3_d1(64);
   eTest <= (overFl0 OR overFl1);
   O <= fA4 WHEN eTest = '0' ELSE
      I_d6(63) & (62 DOWNTO 0 => NOT I_d6(63));
END ARCHITECTURE;