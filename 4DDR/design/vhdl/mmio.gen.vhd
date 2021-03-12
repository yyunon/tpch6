-- Generated using vhdMMIO 0.0.3 (https://github.com/abs-tudelft/vhdmmio)

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

library work;
use work.vhdmmio_pkg.all;
use work.mmio_pkg.all;

entity mmio is
  port (

    -- Clock sensitive to the rising edge and synchronous, active-high reset.
    kcd_clk : in std_logic;
    kcd_reset : in std_logic := '0';

    -- Interface for field start: start.
    f_start_data : out std_logic := '0';

    -- Interface for field stop: stop.
    f_stop_data : out std_logic := '0';

    -- Interface for field reset: reset.
    f_reset_data : out std_logic := '0';

    -- Interface for field idle: idle.
    f_idle_write_data : in std_logic := '0';

    -- Interface for field busy: busy.
    f_busy_write_data : in std_logic := '0';

    -- Interface for field done: done.
    f_done_write_data : in std_logic := '0';

    -- Interface for field result: result.
    f_result_write_data : in std_logic_vector(63 downto 0) := (others => '0');

    -- Interface for field l_firstidx: l_firstidx.
    f_l_firstidx_data : out std_logic_vector(31 downto 0) := (others => '0');

    -- Interface for field l_lastidx: l_lastidx.
    f_l_lastidx_data : out std_logic_vector(31 downto 0) := (others => '0');

    -- Interface for field l_quantity_values: l_quantity_values.
    f_l_quantity_values_data : out std_logic_vector(63 downto 0)
        := (others => '0');

    -- Interface for field l_extendedprice_values: l_extendedprice_values.
    f_l_extendedprice_values_data : out std_logic_vector(63 downto 0)
        := (others => '0');

    -- Interface for field l_discount_values: l_discount_values.
    f_l_discount_values_data : out std_logic_vector(63 downto 0)
        := (others => '0');

    -- Interface for field l_shipdate_values: l_shipdate_values.
    f_l_shipdate_values_data : out std_logic_vector(63 downto 0)
        := (others => '0');

    -- Interface for field rhigh: rhigh.
    f_rhigh_write_data : in std_logic_vector(31 downto 0) := (others => '0');

    -- Interface for field rlow: rlow.
    f_rlow_write_data : in std_logic_vector(31 downto 0) := (others => '0');

    -- Interface for field Profile_enable: Profile_enable.
    f_Profile_enable_data : out std_logic := '0';

    -- Interface for field Profile_clear: Profile_clear.
    f_Profile_clear_data : out std_logic := '0';

    -- AXI4-lite + interrupt request bus to the master.
    mmio_awvalid : in  std_logic := '0';
    mmio_awready : out std_logic := '1';
    mmio_awaddr  : in  std_logic_vector(31 downto 0) := X"00000000";
    mmio_awprot  : in  std_logic_vector(2 downto 0) := "000";
    mmio_wvalid  : in  std_logic := '0';
    mmio_wready  : out std_logic := '1';
    mmio_wdata   : in  std_logic_vector(31 downto 0) := (others => '0');
    mmio_wstrb   : in  std_logic_vector(3 downto 0) := (others => '0');
    mmio_bvalid  : out std_logic := '0';
    mmio_bready  : in  std_logic := '1';
    mmio_bresp   : out std_logic_vector(1 downto 0) := "00";
    mmio_arvalid : in  std_logic := '0';
    mmio_arready : out std_logic := '1';
    mmio_araddr  : in  std_logic_vector(31 downto 0) := X"00000000";
    mmio_arprot  : in  std_logic_vector(2 downto 0) := "000";
    mmio_rvalid  : out std_logic := '0';
    mmio_rready  : in  std_logic := '1';
    mmio_rdata   : out std_logic_vector(31 downto 0) := (others => '0');
    mmio_rresp   : out std_logic_vector(1 downto 0) := "00";
    mmio_uirq    : out std_logic := '0'

  );
end mmio;

architecture behavioral of mmio is
begin
  reg_proc: process (kcd_clk) is

    -- Convenience function for unsigned accumulation with differing vector
    -- widths.
    procedure accum_add(
      accum: inout std_logic_vector;
      addend: std_logic_vector) is
    begin
      accum := std_logic_vector(
        unsigned(accum) + resize(unsigned(addend), accum'length));
    end procedure accum_add;

    -- Convenience function for unsigned subtraction with differing vector
    -- widths.
    procedure accum_sub(
      accum: inout std_logic_vector;
      addend: std_logic_vector) is
    begin
      accum := std_logic_vector(
        unsigned(accum) - resize(unsigned(addend), accum'length));
    end procedure accum_sub;

    -- Internal alias for the reset input.
    variable reset : std_logic;

    -- Bus response output register.
    variable bus_v : axi4l32_s2m_type := AXI4L32_S2M_RESET; -- reg

    -- Holding registers for the AXI4-lite request channels. Having these
    -- allows us to make the accompanying ready signals register outputs
    -- without sacrificing a cycle's worth of delay for every transaction.
    variable awl : axi4la_type := AXI4LA_RESET; -- reg
    variable wl  : axi4lw32_type := AXI4LW32_RESET; -- reg
    variable arl : axi4la_type := AXI4LA_RESET; -- reg

    -- Request flags for the register logic. When asserted, a request is
    -- present in awl/wl/arl, and the response can be returned immediately.
    -- This is used by simple registers.
    variable w_req : boolean := false;
    variable r_req : boolean := false;

    -- As above, but asserted when there is a request that can NOT be returned
    -- immediately for whatever reason, but CAN be started already if deferral
    -- is supported by the targeted block. Abbreviation for lookahead request.
    -- Note that *_lreq implies *_req.
    variable w_lreq : boolean := false;
    variable r_lreq : boolean := false;

    -- Request signals. w_strb is a validity bit for each data bit; it actually
    -- always has byte granularity but encoding it this way makes the code a
    -- lot nicer (and it should be optimized to the same thing by any sane
    -- synthesizer).
    variable w_addr : std_logic_vector(31 downto 0);
    variable w_data : std_logic_vector(31 downto 0) := (others => '0');
    variable w_strb : std_logic_vector(31 downto 0) := (others => '0');
    constant w_prot : std_logic_vector(2 downto 0) := (others => '0');
    variable r_addr : std_logic_vector(31 downto 0);
    constant r_prot : std_logic_vector(2 downto 0) := (others => '0');

    -- Logical write data holding registers. For multi-word registers, write
    -- data is held in w_hold and w_hstb until the last subregister is written,
    -- at which point their entire contents are written at once.
    variable w_hold : std_logic_vector(63 downto 0) := (others => '0'); -- reg
    variable w_hstb : std_logic_vector(63 downto 0) := (others => '0'); -- reg

    -- Between the first and last access to a multiword register, the multi
    -- bit will be set. If it is set while a request with a different *_prot is
    -- received, the interrupting request is rejected if it is A) non-secure
    -- while the interrupted request is secure or B) unprivileged while the
    -- interrupted request is privileged. If it is not rejected, previously
    -- buffered data is cleared and masked. Within the same security level, it
    -- is up to the bus master to not mess up its own access pattern. The last
    -- access to a multiword register clears the bit; for the read end r_hold
    -- is also cleared in this case to prevent data leaks.
    variable w_multi : std_logic := '0'; -- reg
    variable r_multi : std_logic := '0'; -- reg

    -- Response flags. When *_req is set and *_addr matches a register, it must
    -- set at least one of these flags; when *_rreq is set and *_rtag matches a
    -- register, it must also set at least one of these, except it cannot set
    -- *_defer. A decode error can be generated by intentionally NOT setting
    -- any of these flags, but this should only be done by registers that
    -- contain only one field (usually, these would be AXI-lite passthrough
    -- "registers"). The action taken by the non-register-specific logic is as
    -- follows (priority decoder):
    --
    --  - if *_defer is set, push *_dtag into the deferal FIFO;
    --  - if *_block is set, do nothing;
    --  - otherwise, if *_nack is set, send a slave error response;
    --  - otherwise, if *_ack is set, send a positive response;
    --  - otherwise, send a decode error response.
    --
    -- In addition to the above, the request stream(s) will be handshaked if
    -- *_req was set and a response is sent or the response is deferred.
    -- Likewise, the deferal FIFO will be popped if *_rreq was set and a
    -- response is sent.
    --
    -- The valid states can be summarized as follows:
    --
    -- .----------------------------------------------------------------------------------.
    -- | req | lreq | rreq || ack | nack | block | defer || request | response | defer    |
    -- |-----+------+------||-----+------+-------+-------||---------+----------+----------|
    -- |  0  |  0   |  0   ||  0  |  0   |   0   |   0   ||         |          |          | Idle.
    -- |-----+------+------||-----+------+-------+-------||---------+----------+----------|
    -- |  0  |  0   |  1   ||  0  |  0   |   0   |   0   ||         | dec_err  | pop      | Completing
    -- |  0  |  0   |  1   ||  1  |  0   |   0   |   0   ||         | ack      | pop      | previous,
    -- |  0  |  0   |  1   ||  -  |  1   |   0   |   0   ||         | slv_err  | pop      | no
    -- |  0  |  0   |  1   ||  -  |  -   |   1   |   0   ||         |          |          | lookahead.
    -- |-----+------+------||-----+------+-------+-------||---------+----------+----------|
    -- |  1  |  0   |  0   ||  0  |  0   |   0   |   0   || accept  | dec_err  |          | Responding
    -- |  1  |  0   |  0   ||  1  |  0   |   0   |   0   || accept  | ack      |          | immediately
    -- |  1  |  0   |  0   ||  -  |  1   |   0   |   0   || accept  | slv_err  |          | to incoming
    -- |  1  |  0   |  0   ||  -  |  -   |   1   |   0   ||         |          |          | request.
    -- |-----+------+------||-----+------+-------+-------||---------+----------+----------|
    -- |  1  |  0   |  0   ||  0  |  0   |   0   |   1   || accept  |          | push     | Deferring.
    -- |  0  |  1   |  0   ||  0  |  0   |   0   |   1   || accept  |          | push     | Deferring.
    -- |-----+------+------||-----+------+-------+-------||---------+----------+----------|
    -- |  0  |  1   |  1   ||  0  |  0   |   0   |   0   ||         | dec_err  | pop      | Completing
    -- |  0  |  1   |  1   ||  1  |  0   |   0   |   0   ||         | ack      | pop      | previous,
    -- |  0  |  1   |  1   ||  -  |  1   |   0   |   0   ||         | slv_err  | pop      | ignoring
    -- |  0  |  1   |  1   ||  -  |  -   |   1   |   0   ||         |          |          | lookahead.
    -- |-----+------+------||-----+------+-------+-------||---------+----------+----------|
    -- |  0  |  1   |  1   ||  0  |  0   |   0   |   1   || accept  | dec_err  | pop+push | Completing
    -- |  0  |  1   |  1   ||  1  |  0   |   0   |   1   || accept  | ack      | pop+push | previous,
    -- |  0  |  1   |  1   ||  -  |  1   |   0   |   1   || accept  | slv_err  | pop+push | deferring
    -- |  0  |  1   |  1   ||  -  |  -   |   1   |   1   || accept  |          | push     | lookahead.
    -- '----------------------------------------------------------------------------------'
    --
    -- This can be simplified to the following:
    --
    -- .----------------------------------------------------------------------------------.
    -- | req | lreq | rreq || ack | nack | block | defer || request | response | defer    |
    -- |-----+------+------||-----+------+-------+-------||---------+----------+----------|
    -- |  -  |  -   |  -   ||  -  |  -   |   1   |   -   ||         |          |          |
    -- |-----+------+------||-----+------+-------+-------||---------+----------+----------|
    -- |  -  |  -   |  1   ||  -  |  1   |   0   |   -   ||         | slv_err  | pop      |
    -- |  1  |  -   |  0   ||  -  |  1   |   0   |   -   || accept  | slv_err  |          |
    -- |-----+------+------||-----+------+-------+-------||---------+----------+----------|
    -- |  -  |  -   |  1   ||  1  |  0   |   0   |   -   ||         | ack      | pop      |
    -- |  1  |  -   |  0   ||  1  |  0   |   0   |   -   || accept  | ack      |          |
    -- |-----+------+------||-----+------+-------+-------||---------+----------+----------|
    -- |  -  |  -   |  1   ||  0  |  0   |   0   |   -   ||         | dec_err  | pop      |
    -- |  1  |  -   |  0   ||  0  |  0   |   0   |   -   || accept  | dec_err  |          |
    -- |-----+------+------||-----+------+-------+-------||---------+----------+----------|
    -- |  -  |  -   |  -   ||  -  |  -   |   -   |   1   || accept  |          | push     |
    -- '----------------------------------------------------------------------------------'
    --
    variable w_block : boolean := false;
    variable r_block : boolean := false;
    variable w_nack  : boolean := false;
    variable r_nack  : boolean := false;
    variable w_ack   : boolean := false;
    variable r_ack   : boolean := false;

    -- Logical read data holding register. This is set when r_ack is set during
    -- an access to the first physical register of a logical register for all
    -- fields in the logical register.
    variable r_hold  : std_logic_vector(63 downto 0) := (others => '0'); -- reg

    -- Physical read data. This is taken from r_hold based on which physical
    -- subregister is being read.
    variable r_data  : std_logic_vector(31 downto 0);

    -- Subaddress variables, used to index within large fields like memories and
    -- AXI passthroughs.
    variable subaddr_none         : std_logic_vector(0 downto 0);

    -- Private declarations for field start: start.
    type f_start_r_type is record
      d : std_logic;
      v : std_logic;
      inval : std_logic;
    end record;
    constant F_START_R_RESET : f_start_r_type := (
      d => '0',
      v => '0',
      inval => '0'
    );
    type f_start_r_array is array (natural range <>) of f_start_r_type;
    variable f_start_r : f_start_r_array(0 to 0) := (others => F_START_R_RESET);

    -- Private declarations for field stop: stop.
    type f_stop_r_type is record
      d : std_logic;
      v : std_logic;
      inval : std_logic;
    end record;
    constant F_STOP_R_RESET : f_stop_r_type := (
      d => '0',
      v => '0',
      inval => '0'
    );
    type f_stop_r_array is array (natural range <>) of f_stop_r_type;
    variable f_stop_r : f_stop_r_array(0 to 0) := (others => F_STOP_R_RESET);

    -- Private declarations for field reset: reset.
    type f_reset_r_type is record
      d : std_logic;
      v : std_logic;
      inval : std_logic;
    end record;
    constant F_RESET_R_RESET : f_reset_r_type := (
      d => '0',
      v => '0',
      inval => '0'
    );
    type f_reset_r_array is array (natural range <>) of f_reset_r_type;
    variable f_reset_r : f_reset_r_array(0 to 0) := (others => F_RESET_R_RESET);

    -- Private declarations for field idle: idle.
    type f_idle_r_type is record
      d : std_logic;
      v : std_logic;
    end record;
    constant F_IDLE_R_RESET : f_idle_r_type := (
      d => '0',
      v => '0'
    );
    type f_idle_r_array is array (natural range <>) of f_idle_r_type;
    variable f_idle_r : f_idle_r_array(0 to 0) := (others => F_IDLE_R_RESET);

    -- Private declarations for field busy: busy.
    type f_busy_r_type is record
      d : std_logic;
      v : std_logic;
    end record;
    constant F_BUSY_R_RESET : f_busy_r_type := (
      d => '0',
      v => '0'
    );
    type f_busy_r_array is array (natural range <>) of f_busy_r_type;
    variable f_busy_r : f_busy_r_array(0 to 0) := (others => F_BUSY_R_RESET);

    -- Private declarations for field done: done.
    type f_done_r_type is record
      d : std_logic;
      v : std_logic;
    end record;
    constant F_DONE_R_RESET : f_done_r_type := (
      d => '0',
      v => '0'
    );
    type f_done_r_array is array (natural range <>) of f_done_r_type;
    variable f_done_r : f_done_r_array(0 to 0) := (others => F_DONE_R_RESET);

    -- Private declarations for field result: result.
    type f_result_r_type is record
      d : std_logic_vector(63 downto 0);
      v : std_logic;
    end record;
    constant F_RESULT_R_RESET : f_result_r_type := (
      d => (others => '0'),
      v => '0'
    );
    type f_result_r_array is array (natural range <>) of f_result_r_type;
    variable f_result_r : f_result_r_array(0 to 0)
        := (others => F_RESULT_R_RESET);

    -- Private declarations for field l_firstidx: l_firstidx.
    type f_l_firstidx_r_type is record
      d : std_logic_vector(31 downto 0);
      v : std_logic;
    end record;
    constant F_L_FIRSTIDX_R_RESET : f_l_firstidx_r_type := (
      d => (others => '0'),
      v => '0'
    );
    type f_l_firstidx_r_array is array (natural range <>) of f_l_firstidx_r_type;
    variable f_l_firstidx_r : f_l_firstidx_r_array(0 to 0)
        := (others => F_L_FIRSTIDX_R_RESET);

    -- Private declarations for field l_lastidx: l_lastidx.
    type f_l_lastidx_r_type is record
      d : std_logic_vector(31 downto 0);
      v : std_logic;
    end record;
    constant F_L_LASTIDX_R_RESET : f_l_lastidx_r_type := (
      d => (others => '0'),
      v => '0'
    );
    type f_l_lastidx_r_array is array (natural range <>) of f_l_lastidx_r_type;
    variable f_l_lastidx_r : f_l_lastidx_r_array(0 to 0)
        := (others => F_L_LASTIDX_R_RESET);

    -- Private declarations for field l_quantity_values: l_quantity_values.
    type f_l_quantity_values_r_type is record
      d : std_logic_vector(63 downto 0);
      v : std_logic;
    end record;
    constant F_L_QUANTITY_VALUES_R_RESET : f_l_quantity_values_r_type := (
      d => (others => '0'),
      v => '0'
    );
    type f_l_quantity_values_r_array is array (natural range <>) of f_l_quantity_values_r_type;
    variable f_l_quantity_values_r : f_l_quantity_values_r_array(0 to 0)
        := (others => F_L_QUANTITY_VALUES_R_RESET);

    -- Private declarations for field l_extendedprice_values:
    -- l_extendedprice_values.
    type f_l_extendedprice_values_r_type is record
      d : std_logic_vector(63 downto 0);
      v : std_logic;
    end record;
    constant F_L_EXTENDEDPRICE_VALUES_R_RESET : f_l_extendedprice_values_r_type := (
      d => (others => '0'),
      v => '0'
    );
    type f_l_extendedprice_values_r_array is array (natural range <>) of f_l_extendedprice_values_r_type;
    variable f_l_extendedprice_values_r : f_l_extendedprice_values_r_array(0 to 0)
        := (others => F_L_EXTENDEDPRICE_VALUES_R_RESET);

    -- Private declarations for field l_discount_values: l_discount_values.
    type f_l_discount_values_r_type is record
      d : std_logic_vector(63 downto 0);
      v : std_logic;
    end record;
    constant F_L_DISCOUNT_VALUES_R_RESET : f_l_discount_values_r_type := (
      d => (others => '0'),
      v => '0'
    );
    type f_l_discount_values_r_array is array (natural range <>) of f_l_discount_values_r_type;
    variable f_l_discount_values_r : f_l_discount_values_r_array(0 to 0)
        := (others => F_L_DISCOUNT_VALUES_R_RESET);

    -- Private declarations for field l_shipdate_values: l_shipdate_values.
    type f_l_shipdate_values_r_type is record
      d : std_logic_vector(63 downto 0);
      v : std_logic;
    end record;
    constant F_L_SHIPDATE_VALUES_R_RESET : f_l_shipdate_values_r_type := (
      d => (others => '0'),
      v => '0'
    );
    type f_l_shipdate_values_r_array is array (natural range <>) of f_l_shipdate_values_r_type;
    variable f_l_shipdate_values_r : f_l_shipdate_values_r_array(0 to 0)
        := (others => F_L_SHIPDATE_VALUES_R_RESET);

    -- Private declarations for field rhigh: rhigh.
    type f_rhigh_r_type is record
      d : std_logic_vector(31 downto 0);
      v : std_logic;
    end record;
    constant F_RHIGH_R_RESET : f_rhigh_r_type := (
      d => (others => '0'),
      v => '0'
    );
    type f_rhigh_r_array is array (natural range <>) of f_rhigh_r_type;
    variable f_rhigh_r : f_rhigh_r_array(0 to 0) := (others => F_RHIGH_R_RESET);

    -- Private declarations for field rlow: rlow.
    type f_rlow_r_type is record
      d : std_logic_vector(31 downto 0);
      v : std_logic;
    end record;
    constant F_RLOW_R_RESET : f_rlow_r_type := (
      d => (others => '0'),
      v => '0'
    );
    type f_rlow_r_array is array (natural range <>) of f_rlow_r_type;
    variable f_rlow_r : f_rlow_r_array(0 to 0) := (others => F_RLOW_R_RESET);

    -- Private declarations for field Profile_enable: Profile_enable.
    type f_Profile_enable_r_type is record
      d : std_logic;
      v : std_logic;
    end record;
    constant F_PROFILE_ENABLE_R_RESET : f_Profile_enable_r_type := (
      d => '0',
      v => '0'
    );
    type f_Profile_enable_r_array is array (natural range <>) of f_Profile_enable_r_type;
    variable f_Profile_enable_r : f_Profile_enable_r_array(0 to 0)
        := (others => F_PROFILE_ENABLE_R_RESET);

    -- Private declarations for field Profile_clear: Profile_clear.
    type f_Profile_clear_r_type is record
      d : std_logic;
      v : std_logic;
      inval : std_logic;
    end record;
    constant F_PROFILE_CLEAR_R_RESET : f_Profile_clear_r_type := (
      d => '0',
      v => '0',
      inval => '0'
    );
    type f_Profile_clear_r_array is array (natural range <>) of f_Profile_clear_r_type;
    variable f_Profile_clear_r : f_Profile_clear_r_array(0 to 0)
        := (others => F_PROFILE_CLEAR_R_RESET);

    -- Temporary variables for the field templates.
    variable tmp_data    : std_logic;
    variable tmp_strb    : std_logic;
    variable tmp_data32  : std_logic_vector(31 downto 0);
    variable tmp_strb32  : std_logic_vector(31 downto 0);
    variable tmp_data64  : std_logic_vector(63 downto 0);
    variable tmp_strb64  : std_logic_vector(63 downto 0);

  begin
    if rising_edge(kcd_clk) then

      -- Reset variables that shouldn't become registers to default values.
      reset   := kcd_reset;
      w_req   := false;
      r_req   := false;
      w_lreq  := false;
      r_lreq  := false;
      w_addr  := (others => '0');
      w_data  := (others => '0');
      w_strb  := (others => '0');
      r_addr  := (others => '0');
      w_block := false;
      r_block := false;
      w_nack  := false;
      r_nack  := false;
      w_ack   := false;
      r_ack   := false;
      r_data  := (others => '0');

      -------------------------------------------------------------------------
      -- Finish up the previous cycle
      -------------------------------------------------------------------------
      -- Invalidate responses that were acknowledged by the master in the
      -- previous cycle.
      if mmio_bready = '1' then
        bus_v.b.valid := '0';
      end if;
      if mmio_rready = '1' then
        bus_v.r.valid := '0';
      end if;

      -- If we indicated to the master that we were ready for a transaction on
      -- any of the incoming channels, we must latch any incoming requests. If
      -- we're ready but there is no incoming request this becomes don't-care.
      if bus_v.aw.ready = '1' then
        awl.valid := mmio_awvalid;
        awl.addr  := mmio_awaddr;
        awl.prot  := mmio_awprot;
      end if;
      if bus_v.w.ready = '1' then
        wl.valid := mmio_wvalid;
        wl.data  := mmio_wdata;
        wl.strb  := mmio_wstrb;
      end if;
      if bus_v.ar.ready = '1' then
        arl.valid := mmio_arvalid;
        arl.addr  := mmio_araddr;
        arl.prot  := mmio_arprot;
      end if;

      -------------------------------------------------------------------------
      -- Handle interrupts
      -------------------------------------------------------------------------
      -- No incoming interrupts; request signal is always released.
      bus_v.u.irq := '0';

      -------------------------------------------------------------------------
      -- Handle MMIO fields
      -------------------------------------------------------------------------
      -- We're ready for a write/read when all the respective channels (or
      -- their holding registers) are ready/waiting for us.
      if awl.valid = '1' and wl.valid = '1' then
        if bus_v.b.valid = '0' then
          w_req := true; -- Request valid and response register empty.
        else
          w_lreq := true; -- Request valid, but response register is busy.
        end if;
      end if;
      if arl.valid = '1' then
        if bus_v.r.valid = '0' then
          r_req := true; -- Request valid and response register empty.
        else
          r_lreq := true; -- Request valid, but response register is busy.
        end if;
      end if;

      -- Capture request inputs into more consistently named variables.
      w_addr := awl.addr;
      for b in w_strb'range loop
        w_strb(b) := wl.strb(b / 8);
      end loop;
      w_data := wl.data and w_strb;
      r_addr := arl.addr;

      -------------------------------------------------------------------------
      -- Generated field logic
      -------------------------------------------------------------------------

      -- Pre-bus logic for field start: start.

      -- Handle post-write invalidation for field start one cycle after the
      -- write occurs.
      if f_start_r((0)).inval = '1' then
        f_start_r((0)).d := '0';
        f_start_r((0)).v := '0';
      end if;
      f_start_r((0)).inval := '0';

      -- Pre-bus logic for field stop: stop.

      -- Handle post-write invalidation for field stop one cycle after the write
      -- occurs.
      if f_stop_r((0)).inval = '1' then
        f_stop_r((0)).d := '0';
        f_stop_r((0)).v := '0';
      end if;
      f_stop_r((0)).inval := '0';

      -- Pre-bus logic for field reset: reset.

      -- Handle post-write invalidation for field reset one cycle after the
      -- write occurs.
      if f_reset_r((0)).inval = '1' then
        f_reset_r((0)).d := '0';
        f_reset_r((0)).v := '0';
      end if;
      f_reset_r((0)).inval := '0';

      -- Pre-bus logic for field idle: idle.

      -- Handle hardware write for field idle: status.
      f_idle_r((0)).d := f_idle_write_data;
      f_idle_r((0)).v := '1';

      -- Pre-bus logic for field busy: busy.

      -- Handle hardware write for field busy: status.
      f_busy_r((0)).d := f_busy_write_data;
      f_busy_r((0)).v := '1';

      -- Pre-bus logic for field done: done.

      -- Handle hardware write for field done: status.
      f_done_r((0)).d := f_done_write_data;
      f_done_r((0)).v := '1';

      -- Pre-bus logic for field result: result.

      -- Handle hardware write for field result: status.
      f_result_r((0)).d := f_result_write_data;
      f_result_r((0)).v := '1';

      -- Pre-bus logic for field rhigh: rhigh.

      -- Handle hardware write for field rhigh: status.
      f_rhigh_r((0)).d := f_rhigh_write_data;
      f_rhigh_r((0)).v := '1';

      -- Pre-bus logic for field rlow: rlow.

      -- Handle hardware write for field rlow: status.
      f_rlow_r((0)).d := f_rlow_write_data;
      f_rlow_r((0)).v := '1';

      -- Pre-bus logic for field Profile_clear: Profile_clear.

      -- Handle post-write invalidation for field Profile_clear one cycle after
      -- the write occurs.
      if f_Profile_clear_r((0)).inval = '1' then
        f_Profile_clear_r((0)).d := '0';
        f_Profile_clear_r((0)).v := '0';
      end if;
      f_Profile_clear_r((0)).inval := '0';

      -------------------------------------------------------------------------
      -- Bus read logic
      -------------------------------------------------------------------------

      -- Construct the subaddresses for read mode.
      subaddr_none(0) := '0';

      -- Read address decoder.
      case r_addr(6 downto 2) is
        when "00001" =>
          -- r_addr = 000000000000000000000000000001--

          if r_req then

            -- Clear holding register location prior to read.
            r_hold := (others => '0');

          end if;

          -- Read logic for field idle: idle.

          if r_req then
            tmp_data := r_hold(0);
          end if;
          if r_req then

            -- Regular access logic. Read mode: enabled.
            tmp_data := f_idle_r((0)).d;
            r_ack := true;

          end if;
          if r_req then
            r_hold(0) := tmp_data;
          end if;

          -- Read logic for field busy: busy.

          if r_req then
            tmp_data := r_hold(1);
          end if;
          if r_req then

            -- Regular access logic. Read mode: enabled.
            tmp_data := f_busy_r((0)).d;
            r_ack := true;

          end if;
          if r_req then
            r_hold(1) := tmp_data;
          end if;

          -- Read logic for field done: done.

          if r_req then
            tmp_data := r_hold(2);
          end if;
          if r_req then

            -- Regular access logic. Read mode: enabled.
            tmp_data := f_done_r((0)).d;
            r_ack := true;

          end if;
          if r_req then
            r_hold(2) := tmp_data;
          end if;

          -- Read logic for block idle_reg: block containing bits 31..0 of
          -- register `idle_reg` (`IDLE`).
          if r_req then

            r_data := r_hold(31 downto 0);
            r_multi := '0';

          end if;

        when "00010" =>
          -- r_addr = 000000000000000000000000000010--

          if r_req then

            -- Clear holding register location prior to read.
            r_hold := (others => '0');

          end if;

          -- Read logic for field result: result.

          if r_req then
            tmp_data64 := r_hold(63 downto 0);
          end if;
          if r_req then

            -- Regular access logic. Read mode: enabled.
            tmp_data64 := f_result_r((0)).d;
            r_ack := true;

          end if;
          if r_req then
            r_hold(63 downto 0) := tmp_data64;
          end if;

          -- Read logic for block result_reg_low: block containing bits 31..0 of
          -- register `result_reg` (`RESULT`).
          if r_req then

            r_data := r_hold(31 downto 0);
            r_multi := '1';

          end if;

        when "00011" =>
          -- r_addr = 000000000000000000000000000011--

          -- Read logic for block result_reg_high: block containing bits 63..32
          -- of register `result_reg` (`RESULT`).
          if r_req then

            r_data := r_hold(63 downto 32);
            if r_multi = '1' then
              r_ack := true;
            else
              r_nack := true;
            end if;
            r_multi := '0';

          end if;

        when "00100" =>
          -- r_addr = 000000000000000000000000000100--

          if r_req then

            -- Clear holding register location prior to read.
            r_hold := (others => '0');

          end if;

          -- Read logic for field l_firstidx: l_firstidx.

          if r_req then
            tmp_data32 := r_hold(31 downto 0);
          end if;
          if r_req then

            -- Regular access logic. Read mode: enabled.
            tmp_data32 := f_l_firstidx_r((0)).d;
            r_ack := true;

          end if;
          if r_req then
            r_hold(31 downto 0) := tmp_data32;
          end if;

          -- Read logic for block l_firstidx_reg: block containing bits 31..0 of
          -- register `l_firstidx_reg` (`L_FIRSTIDX`).
          if r_req then

            r_data := r_hold(31 downto 0);
            r_multi := '0';

          end if;

        when "00101" =>
          -- r_addr = 000000000000000000000000000101--

          if r_req then

            -- Clear holding register location prior to read.
            r_hold := (others => '0');

          end if;

          -- Read logic for field l_lastidx: l_lastidx.

          if r_req then
            tmp_data32 := r_hold(31 downto 0);
          end if;
          if r_req then

            -- Regular access logic. Read mode: enabled.
            tmp_data32 := f_l_lastidx_r((0)).d;
            r_ack := true;

          end if;
          if r_req then
            r_hold(31 downto 0) := tmp_data32;
          end if;

          -- Read logic for block l_lastidx_reg: block containing bits 31..0 of
          -- register `l_lastidx_reg` (`L_LASTIDX`).
          if r_req then

            r_data := r_hold(31 downto 0);
            r_multi := '0';

          end if;

        when "00110" =>
          -- r_addr = 000000000000000000000000000110--

          if r_req then

            -- Clear holding register location prior to read.
            r_hold := (others => '0');

          end if;

          -- Read logic for field l_quantity_values: l_quantity_values.

          if r_req then
            tmp_data64 := r_hold(63 downto 0);
          end if;
          if r_req then

            -- Regular access logic. Read mode: enabled.
            tmp_data64 := f_l_quantity_values_r((0)).d;
            r_ack := true;

          end if;
          if r_req then
            r_hold(63 downto 0) := tmp_data64;
          end if;

          -- Read logic for block l_quantity_values_reg_low: block containing
          -- bits 31..0 of register `l_quantity_values_reg`
          -- (`L_QUANTITY_VALUES`).
          if r_req then

            r_data := r_hold(31 downto 0);
            r_multi := '1';

          end if;

        when "00111" =>
          -- r_addr = 000000000000000000000000000111--

          -- Read logic for block l_quantity_values_reg_high: block containing
          -- bits 63..32 of register `l_quantity_values_reg`
          -- (`L_QUANTITY_VALUES`).
          if r_req then

            r_data := r_hold(63 downto 32);
            if r_multi = '1' then
              r_ack := true;
            else
              r_nack := true;
            end if;
            r_multi := '0';

          end if;

        when "01000" =>
          -- r_addr = 000000000000000000000000001000--

          if r_req then

            -- Clear holding register location prior to read.
            r_hold := (others => '0');

          end if;

          -- Read logic for field l_extendedprice_values:
          -- l_extendedprice_values.

          if r_req then
            tmp_data64 := r_hold(63 downto 0);
          end if;
          if r_req then

            -- Regular access logic. Read mode: enabled.
            tmp_data64 := f_l_extendedprice_values_r((0)).d;
            r_ack := true;

          end if;
          if r_req then
            r_hold(63 downto 0) := tmp_data64;
          end if;

          -- Read logic for block l_extendedprice_values_reg_low: block
          -- containing bits 31..0 of register `l_extendedprice_values_reg`
          -- (`L_EXTENDEDPRICE_VALUES`).
          if r_req then

            r_data := r_hold(31 downto 0);
            r_multi := '1';

          end if;

        when "01001" =>
          -- r_addr = 000000000000000000000000001001--

          -- Read logic for block l_extendedprice_values_reg_high: block
          -- containing bits 63..32 of register `l_extendedprice_values_reg`
          -- (`L_EXTENDEDPRICE_VALUES`).
          if r_req then

            r_data := r_hold(63 downto 32);
            if r_multi = '1' then
              r_ack := true;
            else
              r_nack := true;
            end if;
            r_multi := '0';

          end if;

        when "01010" =>
          -- r_addr = 000000000000000000000000001010--

          if r_req then

            -- Clear holding register location prior to read.
            r_hold := (others => '0');

          end if;

          -- Read logic for field l_discount_values: l_discount_values.

          if r_req then
            tmp_data64 := r_hold(63 downto 0);
          end if;
          if r_req then

            -- Regular access logic. Read mode: enabled.
            tmp_data64 := f_l_discount_values_r((0)).d;
            r_ack := true;

          end if;
          if r_req then
            r_hold(63 downto 0) := tmp_data64;
          end if;

          -- Read logic for block l_discount_values_reg_low: block containing
          -- bits 31..0 of register `l_discount_values_reg`
          -- (`L_DISCOUNT_VALUES`).
          if r_req then

            r_data := r_hold(31 downto 0);
            r_multi := '1';

          end if;

        when "01011" =>
          -- r_addr = 000000000000000000000000001011--

          -- Read logic for block l_discount_values_reg_high: block containing
          -- bits 63..32 of register `l_discount_values_reg`
          -- (`L_DISCOUNT_VALUES`).
          if r_req then

            r_data := r_hold(63 downto 32);
            if r_multi = '1' then
              r_ack := true;
            else
              r_nack := true;
            end if;
            r_multi := '0';

          end if;

        when "01100" =>
          -- r_addr = 000000000000000000000000001100--

          if r_req then

            -- Clear holding register location prior to read.
            r_hold := (others => '0');

          end if;

          -- Read logic for field l_shipdate_values: l_shipdate_values.

          if r_req then
            tmp_data64 := r_hold(63 downto 0);
          end if;
          if r_req then

            -- Regular access logic. Read mode: enabled.
            tmp_data64 := f_l_shipdate_values_r((0)).d;
            r_ack := true;

          end if;
          if r_req then
            r_hold(63 downto 0) := tmp_data64;
          end if;

          -- Read logic for block l_shipdate_values_reg_low: block containing
          -- bits 31..0 of register `l_shipdate_values_reg`
          -- (`L_SHIPDATE_VALUES`).
          if r_req then

            r_data := r_hold(31 downto 0);
            r_multi := '1';

          end if;

        when "01101" =>
          -- r_addr = 000000000000000000000000001101--

          -- Read logic for block l_shipdate_values_reg_high: block containing
          -- bits 63..32 of register `l_shipdate_values_reg`
          -- (`L_SHIPDATE_VALUES`).
          if r_req then

            r_data := r_hold(63 downto 32);
            if r_multi = '1' then
              r_ack := true;
            else
              r_nack := true;
            end if;
            r_multi := '0';

          end if;

        when "01110" =>
          -- r_addr = 000000000000000000000000001110--

          if r_req then

            -- Clear holding register location prior to read.
            r_hold := (others => '0');

          end if;

          -- Read logic for field rhigh: rhigh.

          if r_req then
            tmp_data32 := r_hold(31 downto 0);
          end if;
          if r_req then

            -- Regular access logic. Read mode: enabled.
            tmp_data32 := f_rhigh_r((0)).d;
            r_ack := true;

          end if;
          if r_req then
            r_hold(31 downto 0) := tmp_data32;
          end if;

          -- Read logic for block rhigh_reg: block containing bits 31..0 of
          -- register `rhigh_reg` (`RHIGH`).
          if r_req then

            r_data := r_hold(31 downto 0);
            r_multi := '0';

          end if;

        when "01111" =>
          -- r_addr = 000000000000000000000000001111--

          if r_req then

            -- Clear holding register location prior to read.
            r_hold := (others => '0');

          end if;

          -- Read logic for field rlow: rlow.

          if r_req then
            tmp_data32 := r_hold(31 downto 0);
          end if;
          if r_req then

            -- Regular access logic. Read mode: enabled.
            tmp_data32 := f_rlow_r((0)).d;
            r_ack := true;

          end if;
          if r_req then
            r_hold(31 downto 0) := tmp_data32;
          end if;

          -- Read logic for block rlow_reg: block containing bits 31..0 of
          -- register `rlow_reg` (`RLOW`).
          if r_req then

            r_data := r_hold(31 downto 0);
            r_multi := '0';

          end if;

        when others => -- "10000"
          -- r_addr = 000000000000000000000000010000--

          if r_req then

            -- Clear holding register location prior to read.
            r_hold := (others => '0');

          end if;

          -- Read logic for field Profile_enable: Profile_enable.

          if r_req then
            tmp_data := r_hold(0);
          end if;
          if r_req then

            -- Regular access logic. Read mode: enabled.
            tmp_data := f_Profile_enable_r((0)).d;
            r_ack := true;

          end if;
          if r_req then
            r_hold(0) := tmp_data;
          end if;

          -- Read logic for block Profile_enable_reg: block containing bits
          -- 31..0 of register `Profile_enable_reg` (`PROFILE_ENABLE`).
          if r_req then

            r_data := r_hold(31 downto 0);
            r_multi := '0';

          end if;

      end case;

      -------------------------------------------------------------------------
      -- Bus write logic
      -------------------------------------------------------------------------

      -- Construct the subaddresses for write mode.
      subaddr_none(0) := '0';

      -- Write address decoder.
      case w_addr(6 downto 2) is
        when "00000" =>
          -- w_addr = 000000000000000000000000000000--

          -- Write logic for block start_reg: block containing bits 31..0 of
          -- register `start_reg` (`START`).
          if w_req or w_lreq then
            w_hold(31 downto 0) := w_data;
            w_hstb(31 downto 0) := w_strb;
            w_multi := '0';
          end if;

          -- Write logic for field start: start.

          tmp_data := w_hold(0);
          tmp_strb := w_hstb(0);
          if w_req then

            -- Regular access logic. Write mode: enabled.

            f_start_r((0)).d := tmp_data;
            w_ack := true;

            -- Handle post-write operation: invalidate.
            f_start_r((0)).v := '1';
            f_start_r((0)).inval := '1';

          end if;

          -- Write logic for field stop: stop.

          tmp_data := w_hold(1);
          tmp_strb := w_hstb(1);
          if w_req then

            -- Regular access logic. Write mode: enabled.

            f_stop_r((0)).d := tmp_data;
            w_ack := true;

            -- Handle post-write operation: invalidate.
            f_stop_r((0)).v := '1';
            f_stop_r((0)).inval := '1';

          end if;

          -- Write logic for field reset: reset.

          tmp_data := w_hold(2);
          tmp_strb := w_hstb(2);
          if w_req then

            -- Regular access logic. Write mode: enabled.

            f_reset_r((0)).d := tmp_data;
            w_ack := true;

            -- Handle post-write operation: invalidate.
            f_reset_r((0)).v := '1';
            f_reset_r((0)).inval := '1';

          end if;

        when "00100" =>
          -- w_addr = 000000000000000000000000000100--

          -- Write logic for block l_firstidx_reg: block containing bits 31..0
          -- of register `l_firstidx_reg` (`L_FIRSTIDX`).
          if w_req or w_lreq then
            w_hold(31 downto 0) := w_data;
            w_hstb(31 downto 0) := w_strb;
            w_multi := '0';
          end if;

          -- Write logic for field l_firstidx: l_firstidx.

          tmp_data32 := w_hold(31 downto 0);
          tmp_strb32 := w_hstb(31 downto 0);
          if w_req then

            -- Regular access logic. Write mode: masked.

            f_l_firstidx_r((0)).d := (f_l_firstidx_r((0)).d and not tmp_strb32)
                or tmp_data32;
            w_ack := true;

          end if;

        when "00101" =>
          -- w_addr = 000000000000000000000000000101--

          -- Write logic for block l_lastidx_reg: block containing bits 31..0 of
          -- register `l_lastidx_reg` (`L_LASTIDX`).
          if w_req or w_lreq then
            w_hold(31 downto 0) := w_data;
            w_hstb(31 downto 0) := w_strb;
            w_multi := '0';
          end if;

          -- Write logic for field l_lastidx: l_lastidx.

          tmp_data32 := w_hold(31 downto 0);
          tmp_strb32 := w_hstb(31 downto 0);
          if w_req then

            -- Regular access logic. Write mode: masked.

            f_l_lastidx_r((0)).d := (f_l_lastidx_r((0)).d and not tmp_strb32)
                or tmp_data32;
            w_ack := true;

          end if;

        when "00110" =>
          -- w_addr = 000000000000000000000000000110--

          -- Write logic for block l_quantity_values_reg_low: block containing
          -- bits 31..0 of register `l_quantity_values_reg`
          -- (`L_QUANTITY_VALUES`).
          if w_req or w_lreq then
            w_hold(31 downto 0) := w_data;
            w_hstb(31 downto 0) := w_strb;
            w_multi := '1';
          end if;
          if w_req then
            w_ack := true;
          end if;

        when "00111" =>
          -- w_addr = 000000000000000000000000000111--

          -- Write logic for block l_quantity_values_reg_high: block containing
          -- bits 63..32 of register `l_quantity_values_reg`
          -- (`L_QUANTITY_VALUES`).
          if w_req or w_lreq then
            w_hold(63 downto 32) := w_data;
            w_hstb(63 downto 32) := w_strb;
            w_multi := '0';
          end if;

          -- Write logic for field l_quantity_values: l_quantity_values.

          tmp_data64 := w_hold(63 downto 0);
          tmp_strb64 := w_hstb(63 downto 0);
          if w_req then

            -- Regular access logic. Write mode: masked.

            f_l_quantity_values_r((0)).d
                := (f_l_quantity_values_r((0)).d and not tmp_strb64)
                or tmp_data64;
            w_ack := true;

          end if;

        when "01000" =>
          -- w_addr = 000000000000000000000000001000--

          -- Write logic for block l_extendedprice_values_reg_low: block
          -- containing bits 31..0 of register `l_extendedprice_values_reg`
          -- (`L_EXTENDEDPRICE_VALUES`).
          if w_req or w_lreq then
            w_hold(31 downto 0) := w_data;
            w_hstb(31 downto 0) := w_strb;
            w_multi := '1';
          end if;
          if w_req then
            w_ack := true;
          end if;

        when "01001" =>
          -- w_addr = 000000000000000000000000001001--

          -- Write logic for block l_extendedprice_values_reg_high: block
          -- containing bits 63..32 of register `l_extendedprice_values_reg`
          -- (`L_EXTENDEDPRICE_VALUES`).
          if w_req or w_lreq then
            w_hold(63 downto 32) := w_data;
            w_hstb(63 downto 32) := w_strb;
            w_multi := '0';
          end if;

          -- Write logic for field l_extendedprice_values:
          -- l_extendedprice_values.

          tmp_data64 := w_hold(63 downto 0);
          tmp_strb64 := w_hstb(63 downto 0);
          if w_req then

            -- Regular access logic. Write mode: masked.

            f_l_extendedprice_values_r((0)).d
                := (f_l_extendedprice_values_r((0)).d and not tmp_strb64)
                or tmp_data64;
            w_ack := true;

          end if;

        when "01010" =>
          -- w_addr = 000000000000000000000000001010--

          -- Write logic for block l_discount_values_reg_low: block containing
          -- bits 31..0 of register `l_discount_values_reg`
          -- (`L_DISCOUNT_VALUES`).
          if w_req or w_lreq then
            w_hold(31 downto 0) := w_data;
            w_hstb(31 downto 0) := w_strb;
            w_multi := '1';
          end if;
          if w_req then
            w_ack := true;
          end if;

        when "01011" =>
          -- w_addr = 000000000000000000000000001011--

          -- Write logic for block l_discount_values_reg_high: block containing
          -- bits 63..32 of register `l_discount_values_reg`
          -- (`L_DISCOUNT_VALUES`).
          if w_req or w_lreq then
            w_hold(63 downto 32) := w_data;
            w_hstb(63 downto 32) := w_strb;
            w_multi := '0';
          end if;

          -- Write logic for field l_discount_values: l_discount_values.

          tmp_data64 := w_hold(63 downto 0);
          tmp_strb64 := w_hstb(63 downto 0);
          if w_req then

            -- Regular access logic. Write mode: masked.

            f_l_discount_values_r((0)).d
                := (f_l_discount_values_r((0)).d and not tmp_strb64)
                or tmp_data64;
            w_ack := true;

          end if;

        when "01100" =>
          -- w_addr = 000000000000000000000000001100--

          -- Write logic for block l_shipdate_values_reg_low: block containing
          -- bits 31..0 of register `l_shipdate_values_reg`
          -- (`L_SHIPDATE_VALUES`).
          if w_req or w_lreq then
            w_hold(31 downto 0) := w_data;
            w_hstb(31 downto 0) := w_strb;
            w_multi := '1';
          end if;
          if w_req then
            w_ack := true;
          end if;

        when "01101" =>
          -- w_addr = 000000000000000000000000001101--

          -- Write logic for block l_shipdate_values_reg_high: block containing
          -- bits 63..32 of register `l_shipdate_values_reg`
          -- (`L_SHIPDATE_VALUES`).
          if w_req or w_lreq then
            w_hold(63 downto 32) := w_data;
            w_hstb(63 downto 32) := w_strb;
            w_multi := '0';
          end if;

          -- Write logic for field l_shipdate_values: l_shipdate_values.

          tmp_data64 := w_hold(63 downto 0);
          tmp_strb64 := w_hstb(63 downto 0);
          if w_req then

            -- Regular access logic. Write mode: masked.

            f_l_shipdate_values_r((0)).d
                := (f_l_shipdate_values_r((0)).d and not tmp_strb64)
                or tmp_data64;
            w_ack := true;

          end if;

        when "10000" =>
          -- w_addr = 000000000000000000000000010000--

          -- Write logic for block Profile_enable_reg: block containing bits
          -- 31..0 of register `Profile_enable_reg` (`PROFILE_ENABLE`).
          if w_req or w_lreq then
            w_hold(31 downto 0) := w_data;
            w_hstb(31 downto 0) := w_strb;
            w_multi := '0';
          end if;

          -- Write logic for field Profile_enable: Profile_enable.

          tmp_data := w_hold(0);
          tmp_strb := w_hstb(0);
          if w_req then

            -- Regular access logic. Write mode: masked.

            f_Profile_enable_r((0)).d
                := (f_Profile_enable_r((0)).d and not tmp_strb) or tmp_data;
            w_ack := true;

          end if;

        when others => -- "10001"
          -- w_addr = 000000000000000000000000010001--

          -- Write logic for block Profile_clear_reg: block containing bits
          -- 31..0 of register `Profile_clear_reg` (`PROFILE_CLEAR`).
          if w_req or w_lreq then
            w_hold(31 downto 0) := w_data;
            w_hstb(31 downto 0) := w_strb;
            w_multi := '0';
          end if;

          -- Write logic for field Profile_clear: Profile_clear.

          tmp_data := w_hold(0);
          tmp_strb := w_hstb(0);
          if w_req then

            -- Regular access logic. Write mode: enabled.

            f_Profile_clear_r((0)).d := tmp_data;
            w_ack := true;

            -- Handle post-write operation: invalidate.
            f_Profile_clear_r((0)).v := '1';
            f_Profile_clear_r((0)).inval := '1';

          end if;

      end case;

      -------------------------------------------------------------------------
      -- Generated field logic
      -------------------------------------------------------------------------

      -- Post-bus logic for field start: start.

      -- Handle reset for field start.
      if reset = '1' then
        f_start_r((0)).d := '0';
        f_start_r((0)).v := '1';
        f_start_r((0)).inval := '0';
      end if;
      -- Assign the read outputs for field start.
      f_start_data <= f_start_r((0)).d;

      -- Post-bus logic for field stop: stop.

      -- Handle reset for field stop.
      if reset = '1' then
        f_stop_r((0)).d := '0';
        f_stop_r((0)).v := '1';
        f_stop_r((0)).inval := '0';
      end if;
      -- Assign the read outputs for field stop.
      f_stop_data <= f_stop_r((0)).d;

      -- Post-bus logic for field reset: reset.

      -- Handle reset for field reset.
      if reset = '1' then
        f_reset_r((0)).d := '0';
        f_reset_r((0)).v := '1';
        f_reset_r((0)).inval := '0';
      end if;
      -- Assign the read outputs for field reset.
      f_reset_data <= f_reset_r((0)).d;

      -- Post-bus logic for field l_firstidx: l_firstidx.

      -- Handle reset for field l_firstidx.
      if reset = '1' then
        f_l_firstidx_r((0)).d := (others => '0');
        f_l_firstidx_r((0)).v := '0';
      end if;
      -- Assign the read outputs for field l_firstidx.
      f_l_firstidx_data <= f_l_firstidx_r((0)).d;

      -- Post-bus logic for field l_lastidx: l_lastidx.

      -- Handle reset for field l_lastidx.
      if reset = '1' then
        f_l_lastidx_r((0)).d := (others => '0');
        f_l_lastidx_r((0)).v := '0';
      end if;
      -- Assign the read outputs for field l_lastidx.
      f_l_lastidx_data <= f_l_lastidx_r((0)).d;

      -- Post-bus logic for field l_quantity_values: l_quantity_values.

      -- Handle reset for field l_quantity_values.
      if reset = '1' then
        f_l_quantity_values_r((0)).d := (others => '0');
        f_l_quantity_values_r((0)).v := '0';
      end if;
      -- Assign the read outputs for field l_quantity_values.
      f_l_quantity_values_data <= f_l_quantity_values_r((0)).d;

      -- Post-bus logic for field l_extendedprice_values:
      -- l_extendedprice_values.

      -- Handle reset for field l_extendedprice_values.
      if reset = '1' then
        f_l_extendedprice_values_r((0)).d := (others => '0');
        f_l_extendedprice_values_r((0)).v := '0';
      end if;
      -- Assign the read outputs for field l_extendedprice_values.
      f_l_extendedprice_values_data <= f_l_extendedprice_values_r((0)).d;

      -- Post-bus logic for field l_discount_values: l_discount_values.

      -- Handle reset for field l_discount_values.
      if reset = '1' then
        f_l_discount_values_r((0)).d := (others => '0');
        f_l_discount_values_r((0)).v := '0';
      end if;
      -- Assign the read outputs for field l_discount_values.
      f_l_discount_values_data <= f_l_discount_values_r((0)).d;

      -- Post-bus logic for field l_shipdate_values: l_shipdate_values.

      -- Handle reset for field l_shipdate_values.
      if reset = '1' then
        f_l_shipdate_values_r((0)).d := (others => '0');
        f_l_shipdate_values_r((0)).v := '0';
      end if;
      -- Assign the read outputs for field l_shipdate_values.
      f_l_shipdate_values_data <= f_l_shipdate_values_r((0)).d;

      -- Post-bus logic for field Profile_enable: Profile_enable.

      -- Handle reset for field Profile_enable.
      if reset = '1' then
        f_Profile_enable_r((0)).d := '0';
        f_Profile_enable_r((0)).v := '0';
      end if;
      -- Assign the read outputs for field Profile_enable.
      f_Profile_enable_data <= f_Profile_enable_r((0)).d;

      -- Post-bus logic for field Profile_clear: Profile_clear.

      -- Handle reset for field Profile_clear.
      if reset = '1' then
        f_Profile_clear_r((0)).d := '0';
        f_Profile_clear_r((0)).v := '1';
        f_Profile_clear_r((0)).inval := '0';
      end if;
      -- Assign the read outputs for field Profile_clear.
      f_Profile_clear_data <= f_Profile_clear_r((0)).d;

      -------------------------------------------------------------------------
      -- Boilerplate bus access logic
      -------------------------------------------------------------------------
      -- Perform the write action dictated by the field logic.
      if w_req and not w_block then

        -- Accept write requests by invalidating the request holding
        -- registers.
        awl.valid := '0';
        wl.valid := '0';

        -- Send the appropriate write response.
        bus_v.b.valid := '1';
        if w_nack then
          bus_v.b.resp := AXI4L_RESP_SLVERR;
        elsif w_ack then
          bus_v.b.resp := AXI4L_RESP_OKAY;
        else
          bus_v.b.resp := AXI4L_RESP_DECERR;
        end if;

      end if;

      -- Perform the read action dictated by the field logic.
      if r_req and not r_block then

        -- Accept read requests by invalidating the request holding
        -- registers.
        arl.valid := '0';

        -- Send the appropriate read response.
        bus_v.r.valid := '1';
        if r_nack then
          bus_v.r.resp := AXI4L_RESP_SLVERR;
        elsif r_ack then
          bus_v.r.resp := AXI4L_RESP_OKAY;
          bus_v.r.data := r_data;
        else
          bus_v.r.resp := AXI4L_RESP_DECERR;
        end if;

      end if;

      -- If we're at the end of a multi-word write, clear the write strobe
      -- holding register to prevent previously written data from leaking into
      -- later partial writes.
      if w_multi = '0' then
        w_hstb := (others => '0');
      end if;

      -- Mark the incoming channels as ready when their respective holding
      -- registers are empty.
      bus_v.aw.ready := not awl.valid;
      bus_v.w.ready := not wl.valid;
      bus_v.ar.ready := not arl.valid;

      -------------------------------------------------------------------------
      -- Handle AXI4-lite bus reset
      -------------------------------------------------------------------------
      -- Reset overrides everything, so it comes last. Note that field
      -- registers are *not* reset here; this would complicate code generation.
      -- Instead, the generated field logic blocks include reset logic for the
      -- field-specific registers.
      if reset = '1' then
        bus_v      := AXI4L32_S2M_RESET;
        awl        := AXI4LA_RESET;
        wl         := AXI4LW32_RESET;
        arl        := AXI4LA_RESET;
        w_hstb     := (others => '0');
        w_hold     := (others => '0');
        w_multi    := '0';
        r_multi    := '0';
        r_hold     := (others => '0');
      end if;

      mmio_awready <= bus_v.aw.ready;
      mmio_wready  <= bus_v.w.ready;
      mmio_bvalid  <= bus_v.b.valid;
      mmio_bresp   <= bus_v.b.resp;
      mmio_arready <= bus_v.ar.ready;
      mmio_rvalid  <= bus_v.r.valid;
      mmio_rdata   <= bus_v.r.data;
      mmio_rresp   <= bus_v.r.resp;
      mmio_uirq    <= bus_v.u.irq;

    end if;
  end process;
end behavioral;
