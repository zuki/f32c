--
-- Copyright (c) 2015 Davor Jadrijevic
-- All rights reserved.
--
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions
-- are met:
-- 1. Redistributions of source code must retain the above copyright
--    notice, this list of conditions and the following disclaimer.
-- 2. Redistributions in binary form must reproduce the above copyright
--    notice, this list of conditions and the following disclaimer in the
--    documentation and/or other materials provided with the distribution.
--
-- THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
-- ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
-- IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
-- ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
-- FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
-- DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
-- OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
-- HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
-- LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
-- OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
-- SUCH DAMAGE.
--
-- $Id$
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.MATH_REAL.ALL;

library unisim;
use unisim.vcomponents.all;

use work.f32c_pack.all;


entity glue is
    generic (
	-- ISA: either ARCH_MI32 or ARCH_RV32
	C_arch: integer := ARCH_MI32;
	C_debug: boolean := false;

	-- Main clock: 50/81/100/112
	C_clk_freq: integer := 100;

	-- SoC configuration options
	C_mem_size: integer := 64; -- KB
	C_vgahdmi: boolean := true;
	C_vgahdmi_mem_kb: integer := 10; -- KB
	C_fmrds: boolean := true;
	C_fm_cw_hz: integer := 107900000; -- Hz FM station carrier wave frequency
        C_fmdds_hz: integer := 250000000; -- Hz clk_fmdds (>2*108 MHz, e.g. 250 MHz, 325 MHz)
        C_rds_clock_multiply: integer := 57; -- multiply and divide from cpu clk 100 MHz
        C_rds_clock_divide: integer := 3125; -- to get 1.824 MHz for RDS logic
	-- warning long compile time on ISE 14.7
	-- C_pids = 2: 1 hour
	-- C_pids = 4: 4 hours
	C_pids: integer := 0;
	C_pid_simulator: std_logic_vector(7 downto 0) := ext("1111", 8);
	C_pid_prescaler: integer := 18;
	C_pid_precision: integer := 1;
	C_pid_pwm_bits: integer := 12;
	C_sio: integer := 1;
	C_spi: integer := 2;
	C_gpio: integer := 32;
	C_simple_io: boolean := true
    );
    port (
	clk_50MHz: in std_logic;
	rs232_tx: out std_logic;
	rs232_rx: in std_logic;
	flash_cs, flash_cclk, flash_mosi: out std_logic;
	flash_miso: in std_logic;
	sd_clk, sd_cd_dat3, sd_cmd: out std_logic;
	sd_dat0: in std_logic;
	leds: out std_logic_vector(7 downto 0);
	porta, portb: inout std_logic_vector(11 downto 0);
	portc: inout std_logic_vector(7 downto 0);
	portd: out std_logic_vector(0 downto 0); -- fm antenna is here
	TMDS_out_P, TMDS_out_N: out std_logic_vector(2 downto 0);
	TMDS_out_CLK_P, TMDS_out_CLK_N: out std_logic;
	sw: in std_logic_vector(4 downto 1)
    );
end glue;

architecture Behavioral of glue is
    signal clk, rs232_break: std_logic;
    signal btns: std_logic_vector(1 downto 0);
    signal clk_25MHz, clk_250MHz: std_logic := '0';
    signal obuf_tmds_clock: std_logic;
    signal tmds_out_rgb: std_logic_vector(2 downto 0);
begin
    -- clock synthesizer: Xilinx Spartan-6 specific
    
    clk112: if C_clk_freq = 112 generate
    clkgen112: entity work.pll_50M_112M5
    port map(
      clk_in1 => clk_50MHz, clk_out1 => clk
    );
    end generate;

    clk100: if C_clk_freq = 100 generate
    clkgen100: entity work.pll_50M_100M_25M_250M
    port map(
      clk_in1 => clk_50MHz, clk_out1 => clk, clk_out2 => clk_25MHz, clk_out3 => clk_250MHz
    );
    end generate;

    clk81: if C_clk_freq = 81 generate
    clkgen81: entity work.pll_50M_81M25
    port map(
      clk_in1 => clk_50MHz, clk_out1 => clk
    );
    end generate;

    clk50: if C_clk_freq = 50 generate
      clk <= clk_50MHz;
    end generate;

    -- reset hard-block: Xilinx Spartan-6 specific
    reset: startup_spartan6
    port map (
	clk => clk, gsr => rs232_break, gts => rs232_break,
	keyclearb => '0'
    );

    -- generic BRAM glue
    glue_bram: entity work.glue_bram
    generic map (
	C_arch => C_arch,
	C_clk_freq => C_clk_freq,
	C_mem_size => C_mem_size,
	C_vgahdmi => C_vgahdmi,
	C_vgahdmi_mem_kb => C_vgahdmi_mem_kb,
	C_fmrds => C_fmrds,
	C_fm_cw_hz => C_fm_cw_hz,
	C_fmdds_hz => C_fmdds_hz,
        C_rds_clock_multiply => C_rds_clock_multiply,
        C_rds_clock_divide => C_rds_clock_divide,
	C_gpio => C_gpio,
	C_sio => C_sio,
	C_spi => C_spi,
	C_pids => C_pids,
	C_pid_simulator => C_pid_simulator,
	C_pid_prescaler => C_pid_prescaler, -- set control loop frequency
	C_pid_fp => integer(floor((log2(real(C_clk_freq)*1.0E6))+0.5))-C_pid_prescaler, -- control loop approx freq in 2^n Hz for math, 26-C_pid_prescaler = 8
	C_pid_precision => C_pid_precision, -- fixed point PID precision
	C_pid_pwm_bits => C_pid_pwm_bits, -- clock divider bits define PWM output frequency
	C_debug => C_debug
    )
    port map (
	clk => clk,
	clk_25MHz => clk_25MHz, -- pixel clock
	clk_250MHz => clk_250MHz, -- tmds clock
	clk_fmdds => clk_250MHz, -- FM/RDS clock
	sio_txd(0) => rs232_tx, sio_rxd(0) => rs232_rx,
	sio_break(0) => rs232_break,
	spi_sck(0)  => flash_cclk,  spi_sck(1)  => sd_clk,
	spi_ss(0)   => flash_cs,    spi_ss(1)   => sd_cd_dat3,
	spi_mosi(0) => flash_mosi,  spi_mosi(1) => sd_cmd,
	spi_miso(0) => flash_miso,  spi_miso(1) => sd_dat0,
	gpio(11 downto 0) => porta(11 downto 0),
	gpio(23 downto 12) => portb(11 downto 0),
	gpio(31 downto 24) => portc(7 downto 0),
	gpio(127 downto 32) => open,
	simple_out(7 downto 0) => leds(7 downto 0),
	simple_out(31 downto 8) => open,
	simple_in(15 downto 0) => open,
	simple_in(19 downto 16) => sw(4 downto 1),
	simple_in(31 downto 20) => open,
	fm_antenna => portd(0),
	tmds_out_rgb => tmds_out_rgb
    );
    
    -- differential output buffering for HDMI clock and video
    hdmi_output: entity work.hdmi_out
      port map (
        tmds_in_clk => clk_25MHz,
        tmds_out_clk_p => tmds_out_clk_p,
        tmds_out_clk_n => tmds_out_clk_n,
        tmds_in_rgb => tmds_out_rgb,
        tmds_out_rgb_p => tmds_out_p,
        tmds_out_rgb_n => tmds_out_n
      );

end Behavioral;
