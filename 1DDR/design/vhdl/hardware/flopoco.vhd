--------------------------------------------------------------------------------
--                          InputIEEE_11_52_to_11_52
-- This operator is part of the Infinite Virtual Library FloPoCoLib
-- All rights reserved 
-- Authors: Florent de Dinechin (2008)
--------------------------------------------------------------------------------
-- Pipeline depth: 0 cycles

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library std;
use std.textio.all;
library work;

entity InputIEEE_11_52_to_11_52 is
   port ( clk, rst : in std_logic;
          X : in  std_logic_vector(63 downto 0);
          R : out  std_logic_vector(11+52+2 downto 0)   );
end entity;

architecture arch of InputIEEE_11_52_to_11_52 is
signal expX :  std_logic_vector(10 downto 0);
signal fracX :  std_logic_vector(51 downto 0);
signal sX :  std_logic;
signal expZero :  std_logic;
signal expInfty :  std_logic;
signal fracZero :  std_logic;
signal reprSubNormal :  std_logic;
signal sfracX :  std_logic_vector(51 downto 0);
signal fracR :  std_logic_vector(51 downto 0);
signal expR :  std_logic_vector(10 downto 0);
signal infinity :  std_logic;
signal zero :  std_logic;
signal NaN :  std_logic;
signal exnR :  std_logic_vector(1 downto 0);
begin
   process(clk)
      begin
         if clk'event and clk = '1' then
         end if;
      end process;
   expX  <= X(62 downto 52);
   fracX  <= X(51 downto 0);
   sX  <= X(63);
   expZero  <= '1' when expX = (10 downto 0 => '0') else '0';
   expInfty  <= '1' when expX = (10 downto 0 => '1') else '0';
   fracZero <= '1' when fracX = (51 downto 0 => '0') else '0';
   reprSubNormal <= fracX(51);
   -- since we have one more exponent value than IEEE (field 0...0, value emin-1),
   -- we can represent subnormal numbers whose mantissa field begins with a 1
   sfracX <= fracX(50 downto 0) & '0' when (expZero='1' and reprSubNormal='1')    else fracX;
   fracR <= sfracX;
   -- copy exponent. This will be OK even for subnormals, zero and infty since in such cases the exn bits will prevail
   expR <= expX;
   infinity <= expInfty and fracZero;
   zero <= expZero and not reprSubNormal;
   NaN <= expInfty and not fracZero;
   exnR <= 
           "00" when zero='1' 
      else "10" when infinity='1' 
      else "11" when NaN='1' 
      else "01" ;  -- normal number
   R <= exnR & sX & expR & fracR; 
end architecture;

--------------------------------------------------------------------------------
--           FP2Fix_11_52M_18_45_S_NT_F400_uid3Exponent_difference
--                          (IntAdder_11_f400_uid5)
-- This operator is part of the Infinite Virtual Library FloPoCoLib
-- All rights reserved 
-- Authors: Bogdan Pasca, Florent de Dinechin (2008-2010)
--------------------------------------------------------------------------------
-- Pipeline depth: 0 cycles

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library std;
use std.textio.all;
library work;

entity FP2Fix_11_52M_18_45_S_NT_F400_uid3Exponent_difference is
   port ( clk, rst : in std_logic;
          X : in  std_logic_vector(10 downto 0);
          Y : in  std_logic_vector(10 downto 0);
          Cin : in  std_logic;
          R : out  std_logic_vector(10 downto 0)   );
end entity;

architecture arch of FP2Fix_11_52M_18_45_S_NT_F400_uid3Exponent_difference is
begin
   process(clk)
      begin
         if clk'event and clk = '1' then
         end if;
      end process;
   --Classical
    R <= X + Y + Cin;
end architecture;

--------------------------------------------------------------------------------
--                    LeftShifter_53_by_max_66_F400_uid13
-- This operator is part of the Infinite Virtual Library FloPoCoLib
-- All rights reserved 
-- Authors: Bogdan Pasca, Florent de Dinechin (2008-2011)
--------------------------------------------------------------------------------
-- Pipeline depth: 3 cycles

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library std;
use std.textio.all;
library work;

entity LeftShifter_53_by_max_66_F400_uid13 is
   port ( clk, rst : in std_logic;
          X : in  std_logic_vector(52 downto 0);
          S : in  std_logic_vector(6 downto 0);
          R : out  std_logic_vector(118 downto 0)   );
end entity;

architecture arch of LeftShifter_53_by_max_66_F400_uid13 is
signal level0 :  std_logic_vector(52 downto 0);
signal ps, ps_d1, ps_d2, ps_d3 :  std_logic_vector(6 downto 0);
signal level1 :  std_logic_vector(53 downto 0);
signal level2, level2_d1 :  std_logic_vector(55 downto 0);
signal level3 :  std_logic_vector(59 downto 0);
signal level4, level4_d1 :  std_logic_vector(67 downto 0);
signal level5 :  std_logic_vector(83 downto 0);
signal level6, level6_d1 :  std_logic_vector(115 downto 0);
signal level7 :  std_logic_vector(179 downto 0);
begin
   process(clk)
      begin
         if clk'event and clk = '1' then
            ps_d1 <=  ps;
            ps_d2 <=  ps_d1;
            ps_d3 <=  ps_d2;
            level2_d1 <=  level2;
            level4_d1 <=  level4;
            level6_d1 <=  level6;
         end if;
      end process;
   level0<= X;
   ps<= S;
   level1<= level0 & (0 downto 0 => '0') when ps(0)= '1' else     (0 downto 0 => '0') & level0;
   level2<= level1 & (1 downto 0 => '0') when ps(1)= '1' else     (1 downto 0 => '0') & level1;
   ----------------Synchro barrier, entering cycle 1----------------
   level3<= level2_d1 & (3 downto 0 => '0') when ps_d1(2)= '1' else     (3 downto 0 => '0') & level2_d1;
   level4<= level3 & (7 downto 0 => '0') when ps_d1(3)= '1' else     (7 downto 0 => '0') & level3;
   ----------------Synchro barrier, entering cycle 2----------------
   level5<= level4_d1 & (15 downto 0 => '0') when ps_d2(4)= '1' else     (15 downto 0 => '0') & level4_d1;
   level6<= level5 & (31 downto 0 => '0') when ps_d2(5)= '1' else     (31 downto 0 => '0') & level5;
   ----------------Synchro barrier, entering cycle 3----------------
   level7<= level6_d1 & (63 downto 0 => '0') when ps_d3(6)= '1' else     (63 downto 0 => '0') & level6_d1;
   R <= level7(118 downto 0);
end architecture;

--------------------------------------------------------------------------------
--                 FP2Fix_11_52M_18_45_S_NT_F400_uid3MantSum
--                          (IntAdder_65_f400_uid17)
-- This operator is part of the Infinite Virtual Library FloPoCoLib
-- All rights reserved 
-- Authors: Bogdan Pasca, Florent de Dinechin (2008-2010)
--------------------------------------------------------------------------------
-- Pipeline depth: 1 cycles

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library std;
use std.textio.all;
library work;

entity FP2Fix_11_52M_18_45_S_NT_F400_uid3MantSum is
   port ( clk, rst : in std_logic;
          X : in  std_logic_vector(64 downto 0);
          Y : in  std_logic_vector(64 downto 0);
          Cin : in  std_logic;
          R : out  std_logic_vector(64 downto 0)   );
end entity;

architecture arch of FP2Fix_11_52M_18_45_S_NT_F400_uid3MantSum is
signal s_sum_l0_idx0 :  std_logic_vector(42 downto 0);
signal s_sum_l0_idx1, s_sum_l0_idx1_d1 :  std_logic_vector(23 downto 0);
signal sum_l0_idx0, sum_l0_idx0_d1 :  std_logic_vector(41 downto 0);
signal c_l0_idx0, c_l0_idx0_d1 :  std_logic_vector(0 downto 0);
signal sum_l0_idx1 :  std_logic_vector(22 downto 0);
signal c_l0_idx1 :  std_logic_vector(0 downto 0);
signal s_sum_l1_idx1 :  std_logic_vector(23 downto 0);
signal sum_l1_idx1 :  std_logic_vector(22 downto 0);
signal c_l1_idx1 :  std_logic_vector(0 downto 0);
begin
   process(clk)
      begin
         if clk'event and clk = '1' then
            s_sum_l0_idx1_d1 <=  s_sum_l0_idx1;
            sum_l0_idx0_d1 <=  sum_l0_idx0;
            c_l0_idx0_d1 <=  c_l0_idx0;
         end if;
      end process;
   --Alternative
   s_sum_l0_idx0 <= ( "0" & X(41 downto 0)) + ( "0" & Y(41 downto 0)) + Cin;
   s_sum_l0_idx1 <= ( "0" & X(64 downto 42)) + ( "0" & Y(64 downto 42));
   sum_l0_idx0 <= s_sum_l0_idx0(41 downto 0);
   c_l0_idx0 <= s_sum_l0_idx0(42 downto 42);
   sum_l0_idx1 <= s_sum_l0_idx1(22 downto 0);
   c_l0_idx1 <= s_sum_l0_idx1(23 downto 23);
   ----------------Synchro barrier, entering cycle 1----------------
   s_sum_l1_idx1 <=  s_sum_l0_idx1_d1 + c_l0_idx0_d1(0 downto 0);
   sum_l1_idx1 <= s_sum_l1_idx1(22 downto 0);
   c_l1_idx1 <= s_sum_l1_idx1(23 downto 23);
   R <= sum_l1_idx1(22 downto 0) & sum_l0_idx0_d1(41 downto 0);
end architecture;

--------------------------------------------------------------------------------
--                     FP2Fix_11_52M_18_45_S_NT_F400_uid3
-- This operator is part of the Infinite Virtual Library FloPoCoLib
-- All rights reserved 
-- Authors: Fabrizio Ferrandi (2012)
--------------------------------------------------------------------------------
-- Pipeline depth: 6 cycles

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library std;
use std.textio.all;
library work;

entity FP2Fix_11_52M_18_45_S_NT_F400_uid3 is
   port ( clk, rst : in std_logic;
          I : in  std_logic_vector(11+52+2 downto 0);
          O : out  std_logic_vector(63 downto 0)   );
end entity;

architecture arch of FP2Fix_11_52M_18_45_S_NT_F400_uid3 is
   component FP2Fix_11_52M_18_45_S_NT_F400_uid3Exponent_difference is
      port ( clk, rst : in std_logic;
             X : in  std_logic_vector(10 downto 0);
             Y : in  std_logic_vector(10 downto 0);
             Cin : in  std_logic;
             R : out  std_logic_vector(10 downto 0)   );
   end component;

   component LeftShifter_53_by_max_66_F400_uid13 is
      port ( clk, rst : in std_logic;
             X : in  std_logic_vector(52 downto 0);
             S : in  std_logic_vector(6 downto 0);
             R : out  std_logic_vector(118 downto 0)   );
   end component;

   component FP2Fix_11_52M_18_45_S_NT_F400_uid3MantSum is
      port ( clk, rst : in std_logic;
             X : in  std_logic_vector(64 downto 0);
             Y : in  std_logic_vector(64 downto 0);
             Cin : in  std_logic;
             R : out  std_logic_vector(64 downto 0)   );
   end component;

signal eA0 :  std_logic_vector(10 downto 0);
signal fA0, fA0_d1 :  std_logic_vector(52 downto 0);
signal bias :  std_logic_vector(10 downto 0);
signal eA1, eA1_d1 :  std_logic_vector(10 downto 0);
signal shiftedby :  std_logic_vector(6 downto 0);
signal fA1 :  std_logic_vector(118 downto 0);
signal fA2a :  std_logic_vector(64 downto 0);
signal notallzero :  std_logic;
signal round :  std_logic;
signal fA2b :  std_logic_vector(64 downto 0);
signal fA3, fA3_d1 :  std_logic_vector(64 downto 0);
signal fA3b :  std_logic_vector(64 downto 0);
signal fA4 :  std_logic_vector(63 downto 0);
signal overFl0 :  std_logic;
signal overFl1 :  std_logic;
signal eTest :  std_logic;
signal I_d1, I_d2, I_d3, I_d4, I_d5, I_d6 :  std_logic_vector(11+52+2 downto 0);
begin
   process(clk)
      begin
         if clk'event and clk = '1' then
            fA0_d1 <=  fA0;
            eA1_d1 <=  eA1;
            fA3_d1 <=  fA3;
            I_d1 <=  I;
            I_d2 <=  I_d1;
            I_d3 <=  I_d2;
            I_d4 <=  I_d3;
            I_d5 <=  I_d4;
            I_d6 <=  I_d5;
         end if;
      end process;
   eA0 <= I(62 downto 52);
   fA0 <= "1" & I(51 downto 0);
   bias <= not conv_std_logic_vector(1022, 11);
   Exponent_difference: FP2Fix_11_52M_18_45_S_NT_F400_uid3Exponent_difference  -- pipelineDepth=0 maxInDelay=0
      port map ( clk  => clk,
                 rst  => rst,
                 Cin => '1',
                 R => eA1,
                 X => bias,
                 Y => eA0);
   ---------------- cycle 0----------------
   ----------------Synchro barrier, entering cycle 1----------------
   shiftedby <= eA1_d1(6 downto 0) when eA1_d1(10) = '0' else (6 downto 0 => '0');
   FXP_shifter: LeftShifter_53_by_max_66_F400_uid13  -- pipelineDepth=3 maxInDelay=0
      port map ( clk  => clk,
                 rst  => rst,
                 R => fA1,
                 S => shiftedby,
                 X => fA0_d1);
   ----------------Synchro barrier, entering cycle 4----------------
   fA2a<= '0' & fA1(98 downto 35);
   notallzero <= '0' when fA1(33 downto 0) = (33 downto 0 => '0') else '1';
   round <= (fA1(34) and I_d4(63)) or (fA1(34) and notallzero and not I_d4(63));
   fA2b<= '0' & (63 downto 1 => '0') & round;
   MantSum: FP2Fix_11_52M_18_45_S_NT_F400_uid3MantSum  -- pipelineDepth=1 maxInDelay=0
      port map ( clk  => clk,
                 rst  => rst,
                 Cin => '0',
                 R => fA3,
                 X => fA2a,
                 Y => fA2b);
   ---------------- cycle 5----------------
   ----------------Synchro barrier, entering cycle 6----------------
   fA3b<= -signed(fA3_d1);
   fA4<= fA3_d1(63 downto 0) when I_d6(63) = '0' else fA3b(63 downto 0);
   overFl0<= '1' when I_d6(62 downto 52) > conv_std_logic_vector(1068,11) else I_d6(65);
   overFl1 <= fA3_d1(64);
   eTest <= (overFl0 or overFl1);
   O <= fA4 when eTest = '0' else
      I_d6(63) & (62 downto 0 => not I_d6(63));
end architecture;

