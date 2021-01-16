library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use     work.Join_pkg.all;
use     work.Stream_pkg.all;

entity HashJoin is
  generic (
    DATA_WIDTH                  : natural;
    HASH_WIDTH                  : natural;
    HASH_ADDR_WIDTH             : natural
  );
  port (
    clk                         : in std_logic;

    reset                       : in std_logic;

    hash_state                       : in std_logic; -- build '1' or populate '0'

    in_valid                  : in std_logic;
    in_dvalid                  : in std_logic;
    in_ready                  : out std_logic;
    in_last                   : in std_logic;
    in_data                   : in std_logic_vector(DATA_WIDTH-1 downto 0);

    out_valid                  : out std_logic;
    out_dvalid                  : out std_logic;
    out_ready                  : in std_logic;
    out_data                   : out std_logic_vector(DATA_WIDTH-1 downto 0)
  );
end HashJoin;

architecture Behav of HashJoin is
    constant ZERO : std_logic_vector(in_data'range) := (others => '0');
    signal hash_addr_out : std_logic_vector(HASH_ADDR_WIDTH - 1 downto 0); -- Mask 18 bits for hash addressing

    signal key_in_ready : std_logic;
    signal key_in_valid : std_logic;
    signal key_in_last : std_logic;
    signal key_in_data : std_logic_vector(DATA_WIDTH-1 downto 0);

    signal buffered_in_ready : std_logic;
    signal buffered_in_valid : std_logic;
    signal buffered_in_data : std_logic_vector(DATA_WIDTH-1 downto 0);

    signal bit_table_write_enable : std_logic;
    signal bit_table_write_in : std_logic_vector(HASH_WIDTH - 1 downto 0); -- Out of hash mask
    signal bit_table_write_data : std_logic_vector(HASH_ADDR_WIDTH downto 0); -- Input hash table, for newly hashed key, also valid bit

    signal bit_table_read_in : std_logic_vector(HASH_WIDTH - 1 downto 0); -- Out of hash mask
    signal bit_table_read_data : std_logic_vector(HASH_ADDR_WIDTH downto 0); -- Out of hash mask,this will point out the address table

    signal hash_table_write_enable : std_logic;
    signal hash_table_write_in : std_logic_vector(HASH_ADDR_WIDTH - 1 downto 0); -- Out of hash mask
    signal hash_table_write_data : std_logic_vector(HASH_ADDR_WIDTH + DATA_WIDTH - 1 downto 0); -- Input hash table, for newly hashed key

    signal hash_table_read_in : std_logic_vector(HASH_ADDR_WIDTH - 1 downto 0); -- Out of hash mask
    signal hash_table_read_data : std_logic_vector(HASH_ADDR_WIDTH + DATA_WIDTH - 1 downto 0); -- Out of hash mask,this will point out the address table

    signal hash_next_val : std_logic_vector(HASH_ADDR_WIDTH - 1 downto 0);
    signal hash_addr_pointer : std_logic_vector(HASH_ADDR_WIDTH -1 downto 0):= (others =>'0'); -- Points to next row in hash table

    signal out_predicate     : std_logic;
    signal out_valid_s       : std_logic;
    signal out_valid_s       : std_logic;

begin
  key_in_ready  <= in_ready;
  key_in_valid  <= in_valid;
  key_in_data   <= in_data;
  key_in_last   <= in_last;
  -- Buffer to hold predicated as transation indexes  
  pred_buffer: StreamBuffer
    generic map (
      MIN_DEPTH                 => 1,
      DATA_WIDTH                => DATA_WIDTH
    )
    port map (
      clk                       => clk,
      reset                     => reset,
      in_valid                  => key_in_valid,
      in_ready                  => key_in_ready,
      in_data                   => key_in_data,
      out_valid                 => buffered_in_valid,
      out_ready                 => buffered_in_ready,
      out_data                  => buffered_in_data
    );

  bit_table: Ram
    generic map (
      WIDTH                         => HASH_ADDR_WIDTH + 1, -- Holds the : bit_valid & HEAD
      DEPTH_LOG2                    => HASH_WIDTH
      --RAM_CONFIG                    => "RAM4K" --Modelsim
    )
    port map (
      w_clk                         => clk,
      w_ena                         => bit_table_write_enable,
      w_addr                        => bit_table_write_in,
      w_data                        => bit_table_write_data,

      r_addr                        => bit_table_read_in,
      r_data                        => bit_table_read_data
    );
  hash_table: Ram
    generic map (
      WIDTH                         => HASH_ADDR_WIDTH + DATA_WIDTH, -- Holds the : Next(18)(signed)&Value(64)
      DEPTH_LOG2                    => HASH_ADDR_WIDTH
      --RAM_CONFIG                    => "RAM4K" --Modelsim
    )
    port map (
      w_clk                         => clk,
      w_ena                         => hash_table_write_enable,
      w_addr                        => hash_table_write_in,
      w_data                        => hash_table_write_data,

      r_addr                        => hash_table_read_in,
      r_data                        => hash_table_read_data
    );

  bit_table_read_in <= key_in_data(HASH_WIDTH - 1 downto 0); -- Mask 5 bits for hashing
  combinatorial_proc_bit_table: process (buffered_in_data, buffered_in_ready,buffered_in_valid,
                                         bit_table_write_enable,bit_table_write_data,bit_table_write_in,
                                         bit_table_read_data,bit_table_read_in,
                                         hash_table_read_in, hash_table_read_data,
                                         hash_table_write_enable,hash_table_write_in, hash_table_write_data) is
  begin
    hash_table_write_enable <= '0';
    bit_table_write_enable <= '0';
    hash_table_read_in <= bit_table_read_data(HASH_ADDR_WIDTH-1 downto 0);
    hash_next_val <= hash_table_read_data(HASH_ADDR_WIDTH + DATA_WIDTH - 1 downto DATA_WIDTH);
    out_valid_s <='1';

    if hash_state = '1' then -- state build
      if buffered_in_valid = '1' then
        -- Read
        if bit_table_read_data(HASH_ADDR_WIDTH) = '1' then -- Read valid
          -- Populate to hash table
          hash_table_write_enable <= '1';
          hash_table_write_in <= hash_addr_pointer;
          hash_table_write_data(DATA_WIDTH -1 downto 0) <= buffered_in_data;
          hash_table_write_data(HASH_ADDR_WIDTH + DATA_WIDTH -1 downto DATA_WIDTH) <= std_logic_vector(signed(bit_table_read_data(HASH_ADDR_WIDTH - 1 downto 0)) - signed(hash_addr_pointer));
          hash_addr_pointer <= std_logic_vector(unsigned(hash_addr_pointer) + to_unsigned(1, 18));
        else --Read not valid, write take place first time
          bit_table_write_enable <= '1';
          bit_table_write_in <= key_in_data(HASH_WIDTH - 1 downto 0);
          bit_table_write_data <= '1' & hash_addr_pointer; 
          -- Populate to hash table
          hash_table_write_enable <= '1';
          hash_table_write_in <= hash_addr_pointer;
          hash_table_write_data(DATA_WIDTH -1 downto 0) <= buffered_in_data;
          hash_table_write_data(HASH_ADDR_WIDTH + DATA_WIDTH - 1 downto DATA_WIDTH ) <= (others => '0');
          -- Increment the address ptr for cache
          hash_addr_pointer <= std_logic_vector(unsigned(hash_addr_pointer) + to_unsigned(1,18));
        end if; 
        if key_in_last = '1' then -- in build_phase set valid 1 when last element is hashed.
          out_valid_s <= '1';
        end if;
      end if;
    else  --state probe
      if buffered_in_valid = '1' then
        if bit_table_read_data(HASH_ADDR_WIDTH) = '1' then
          if key_in_data = hash_table_read_data(DATA_WIDTH-1 downto 0) then 
            out_predicate <='1'; 
            out_valid_s <='1';
          end if;
        end if;

      end if;
    end if;
  end process;
  buffered_in_ready <= out_ready;
  out_data(0) <= out_predicate;
  out_valid <= out_valid_s;
  out_dvalid <= in_dvalid;
  -- addr_out_data <= ZERO(DATA_WIDTH downto hash_addr_out'length) & hash_addr_out;
end architecture;

